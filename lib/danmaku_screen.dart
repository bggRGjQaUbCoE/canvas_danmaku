import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';
import 'models/danmaku_item.dart';
import 'scroll_danmaku_painter.dart';
import 'special_danmaku_painter.dart';
import 'static_danmaku_painter.dart';
import 'danmaku_controller.dart';
import 'dart:ui' as ui;
import 'models/danmaku_option.dart';
import '/models/danmaku_content_item.dart';
import 'dart:math';

class DanmakuScreen extends StatefulWidget {
  // 创建Screen后返回控制器
  final Function(DanmakuController) createdController;
  final DanmakuOption option;

  const DanmakuScreen({
    required this.createdController,
    required this.option,
    super.key,
  });

  @override
  State<DanmakuScreen> createState() => _DanmakuScreenState();
}

class _DanmakuScreenState extends State<DanmakuScreen>
    with TickerProviderStateMixin {
  /// 视图宽度
  double _viewWidth = 0;

  /// 弹幕控制器
  late DanmakuController _controller;

  /// 弹幕动画控制器
  late AnimationController _animationController;

  /// 静态弹幕动画控制器
  late AnimationController _staticAnimationController;

  /// 弹幕配置
  DanmakuOption _option = DanmakuOption();

  /// 滚动弹幕
  List<DanmakuItem> _scrollDanmakuItems = [];

  /// 顶部弹幕
  List<DanmakuItem> _topDanmakuItems = [];

  /// 底部弹幕
  List<DanmakuItem> _bottomDanmakuItems = [];

  /// 高级弹幕
  List<DanmakuItem> _specialDanmakuItems = [];

  /// 弹幕高度
  late double _danmakuHeight;

  /// 弹幕轨道数
  late int _trackCount;

  /// 弹幕轨道位置
  late List<double> _trackYPositions;

  late final _random = Random();

  /// 内部计时器
  int get _tick => _stopwatch.elapsedMilliseconds;

  final _stopwatch = Stopwatch();

  /// 运行状态
  bool _running = true;

  @override
  void initState() {
    super.initState();
    // 计时器初始化
    // _startTick(); // start when adding danmaku
    _option = widget.option;
    _controller = DanmakuController(
      onAddDanmaku: addDanmaku,
      onUpdateOption: updateOption,
      onPause: pause,
      onResume: resume,
      onClear: clearDanmakus,
    );
    _controller.option = _option;
    widget.createdController.call(
      _controller,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_option.duration * 1000).toInt()),
    )..repeat();

    _staticAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_option.staticDuration * 1000).toInt()),
    );

    // WidgetsBinding.instance.addObserver(this);

    /// 计算弹幕轨道
    _danmakuHeight = _textPainter.height;
  }

  // only layout when fontSize or lineHeight is changed
  TextPainter get _textPainter => TextPainter(
        text: TextSpan(
          text: '弹幕',
          style: TextStyle(
            fontSize: _option.fontSize,
            height: _option.lineHeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  /// 处理 Android/iOS 应用后台或熄屏导致的动画问题
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused) {
  //     pause();
  //   }
  // }

  @override
  void dispose() {
    _running = false;
    // WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _staticAnimationController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  /// 添加弹幕
  void addDanmaku(DanmakuContentItem content) {
    // ensure adding self-send danmaku when pause
    if (content.selfSend) {
      if (!mounted) {
        return;
      }
    } else {
      if (!_running || !mounted) {
        return;
      }
    }

    if (_running && !_stopwatch.isRunning) {
      _startTick();
    }

    if (content.type == DanmakuItemType.special) {
      if (!_option.hideSpecial) {
        (content as SpecialDanmakuContentItem).painterCache = TextPainter(
          text: TextSpan(
            text: content.text,
            style: TextStyle(
              color: content.color,
              fontSize: content.fontSize,
              fontWeight: FontWeight.values[_option.fontWeight],
              shadows: content.hasStroke
                  ? [
                      Shadow(
                          color: Colors.black.withOpacity(
                              content.alphaTween?.begin ??
                                  content.color.opacity),
                          blurRadius: _option.strokeWidth)
                    ]
                  : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        _specialDanmakuItems.add(DanmakuItem(
          width: 0,
          height: 0,
          creationTime: _tick,
          content: content,
          paragraph: null,
          strokeParagraph: null,
        ));
      } else {
        return;
      }
    } else {
      // 在这里提前创建 Paragraph 缓存防止卡顿
      final textPainter = TextPainter(
        text: TextSpan(
          text: content.text,
          style: TextStyle(
            fontSize: _option.fontSize,
            fontWeight: FontWeight.values[_option.fontWeight],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final danmakuWidth = textPainter.width;
      final danmakuHeight = textPainter.height;

      ui.Paragraph? paragraph;
      if (content.isColorful != true) {
        paragraph = Utils.generateParagraph(
          content: content,
          danmakuWidth: danmakuWidth,
          fontSize: _option.fontSize,
          fontWeight: _option.fontWeight,
          // opacity: _option.opacity,
        );
      }

      ui.Paragraph? strokeParagraph;
      if (_option.strokeWidth > 0 && content.isColorful != true) {
        strokeParagraph = Utils.generateStrokeParagraph(
          content: content,
          danmakuWidth: danmakuWidth,
          fontSize: _option.fontSize,
          fontWeight: _option.fontWeight,
          strokeWidth: _option.strokeWidth,
          // opacity: _option.opacity,
        );
      }

      int idx = 1;
      for (double yPosition in _trackYPositions) {
        if (content.type == DanmakuItemType.scroll && !_option.hideScroll) {
          bool scrollCanAddToTrack =
              _scrollCanAddToTrack(yPosition, danmakuWidth);

          if (scrollCanAddToTrack) {
            _scrollDanmakuItems.add(
              DanmakuItem(
                yPosition: yPosition,
                xPosition: _viewWidth,
                width: danmakuWidth,
                height: danmakuHeight,
                creationTime: _tick,
                content: content,
                paragraph: paragraph,
                strokeParagraph: strokeParagraph,
              ),
            );
            break;
          }

          /// 无法填充自己发送的弹幕时强制添加
          if (content.selfSend && idx == _trackCount) {
            _scrollDanmakuItems.add(
              DanmakuItem(
                yPosition: _trackYPositions[0],
                xPosition: _viewWidth,
                width: danmakuWidth,
                height: danmakuHeight,
                creationTime: _tick,
                content: content,
                paragraph: paragraph,
                strokeParagraph: strokeParagraph,
              ),
            );
            break;
          }

          /// 海量弹幕启用时进行随机添加
          if (_option.massiveMode && idx == _trackCount) {
            double randomYPosition =
                _trackYPositions[_random.nextInt(_trackYPositions.length)];
            _scrollDanmakuItems.add(
              DanmakuItem(
                yPosition: randomYPosition,
                xPosition: _viewWidth,
                width: danmakuWidth,
                height: danmakuHeight,
                creationTime: _tick,
                content: content,
                paragraph: paragraph,
                strokeParagraph: strokeParagraph,
              ),
            );
            break;
          }
        }

        if (content.type == DanmakuItemType.top && !_option.hideTop) {
          bool topCanAddToTrack = _topCanAddToTrack(yPosition);

          if (topCanAddToTrack) {
            _topDanmakuItems.add(
              DanmakuItem(
                yPosition: yPosition,
                xPosition: _viewWidth,
                width: danmakuWidth,
                height: danmakuHeight,
                creationTime: _tick,
                content: content,
                paragraph: paragraph,
                strokeParagraph: strokeParagraph,
              ),
            );
            break;
          }
        }

        if (content.type == DanmakuItemType.bottom && !_option.hideBottom) {
          if (_option.safeArea && yPosition <= _danmakuHeight) {
            continue;
          }

          bool bottomCanAddToTrack = _bottomCanAddToTrack(yPosition);

          if (bottomCanAddToTrack) {
            _bottomDanmakuItems.add(
              DanmakuItem(
                yPosition: yPosition,
                xPosition: _viewWidth,
                width: danmakuWidth,
                height: danmakuHeight,
                creationTime: _tick,
                content: content,
                paragraph: paragraph,
                strokeParagraph: strokeParagraph,
              ),
            );
            break;
          }
        }
        idx++;
      }
    }

    switch (content.type) {
      case DanmakuItemType.top:
      case DanmakuItemType.bottom:
        // 重绘静态弹幕
        setState(() {
          _staticAnimationController.value = 0;
        });
        break;
      case DanmakuItemType.scroll:
      case DanmakuItemType.special:
        if (!_animationController.isAnimating &&
            (_scrollDanmakuItems.isNotEmpty ||
                _specialDanmakuItems.isNotEmpty)) {
          _animationController.repeat();
        }
        break;
    }
  }

  /// 暂停
  void pause() {
    if (!mounted) return;
    if (_running) {
      setState(() {
        _running = false;
      });
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
      }
    }
  }

  /// 恢复
  void resume() {
    if (!mounted) return;
    if (!_running) {
      setState(() {
        _running = true;
      });
      if (!_animationController.isAnimating) {
        _animationController.repeat();
      }
      if (!_stopwatch.isRunning) {
        // 重启计时器
        _startTick();
      }
    }
  }

  void _updateOption(DanmakuOption option) {
    _option = option;
    _controller.option = _option;
  }

  /// 更新弹幕设置
  void updateOption(DanmakuOption option) {
    if (_option.lineHeight != option.lineHeight) {
      _updateOption(option);
      _danmakuHeight = _textPainter.height; // resize _danmakuHeight
      return;
    }

    bool needRestart = false;
    bool needClearParagraph = false;
    if (_animationController.isAnimating) {
      _animationController.stop();
      needRestart = true;
    }

    if (option.fontSize != _option.fontSize ||
        option.fontWeight != _option.fontWeight ||
        option.opacity != _option.opacity ||
        option.strokeWidth != _option.strokeWidth) {
      needClearParagraph = true;
    }

    /// 需要隐藏弹幕时清理已有弹幕
    if (option.hideScroll && !_option.hideScroll) {
      _scrollDanmakuItems = [];
    }
    if (option.hideTop && !_option.hideTop) {
      _topDanmakuItems = [];
    }
    if (option.hideBottom && !_option.hideBottom) {
      _bottomDanmakuItems = [];
    }

    if (option.hideSpecial && !_option.hideSpecial) {
      _specialDanmakuItems = [];
    }

    if (option.fontSize != _option.fontSize) {
      _updateOption(option);
      _danmakuHeight = _textPainter.height; // resize _danmakuHeight
    } else {
      _updateOption(option);
    }

    /// 清理已经存在的 Paragraph 缓存
    if (needClearParagraph) {
      for (DanmakuItem item in _scrollDanmakuItems) {
        if (item.paragraph != null) {
          item.paragraph = null;
        }
        if (item.strokeParagraph != null) {
          item.strokeParagraph = null;
        }
      }
      for (DanmakuItem item in _topDanmakuItems) {
        if (item.paragraph != null) {
          item.paragraph = null;
        }
        if (item.strokeParagraph != null) {
          item.strokeParagraph = null;
        }
      }
      for (DanmakuItem item in _bottomDanmakuItems) {
        if (item.paragraph != null) {
          item.paragraph = null;
        }
        if (item.strokeParagraph != null) {
          item.strokeParagraph = null;
        }
      }
    }
    if (needRestart) {
      _animationController.repeat();
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// 清空弹幕
  void clearDanmakus() {
    if (!mounted) return;
    setState(() {
      _scrollDanmakuItems = [];
      _topDanmakuItems = [];
      _bottomDanmakuItems = [];
      _specialDanmakuItems = [];
    });
    _animationController.stop();
  }

  /// 确定滚动弹幕是否可以添加
  bool _scrollCanAddToTrack(double yPosition, double newDanmakuWidth) {
    for (DanmakuItem item in _scrollDanmakuItems) {
      if (item.yPosition == yPosition) {
        final existingEndPosition = item.xPosition + item.width;
        // 首先保证进入屏幕时不发生重叠，其次保证知道移出屏幕前不与速度慢的弹幕(弹幕宽度较小)发生重叠
        if (_viewWidth - existingEndPosition < 0) {
          return false;
        }
        if (item.width < newDanmakuWidth) {
          if ((1 -
                  ((_viewWidth - item.xPosition) / (item.width + _viewWidth))) >
              ((_viewWidth) / (_viewWidth + newDanmakuWidth))) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// 确定顶部弹幕是否可以添加
  bool _topCanAddToTrack(double yPosition) {
    for (DanmakuItem item in _topDanmakuItems) {
      if (item.yPosition == yPosition) {
        return false;
      }
    }
    return true;
  }

  /// 确定底部弹幕是否可以添加
  bool _bottomCanAddToTrack(double yPosition) {
    for (DanmakuItem item in _bottomDanmakuItems) {
      if (item.yPosition == yPosition) {
        return false;
      }
    }
    return true;
  }

  // 基于Stopwatch的计时器同步
  void _startTick() async {
    // _stopwatch.reset();
    _stopwatch.start();

    final staticDuration = _option.staticDuration * 1000;

    while (_running && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      // 移除屏幕外滚动弹幕
      _scrollDanmakuItems
          .removeWhere((item) => item.xPosition + item.width < 0);
      // 移除顶部弹幕
      _topDanmakuItems
          .removeWhere((item) => (_tick - item.creationTime) >= staticDuration);
      // 移除底部弹幕
      _bottomDanmakuItems
          .removeWhere((item) => (_tick - item.creationTime) >= staticDuration);
      // 移除高级弹幕
      _specialDanmakuItems.removeWhere((item) =>
          (_tick - item.creationTime) >=
          (item.content as SpecialDanmakuContentItem).duration);
      // 暂停动画
      if (_scrollDanmakuItems.isEmpty &&
          _specialDanmakuItems.isEmpty &&
          _animationController.isAnimating) {
        _animationController.stop();
      }

      /// 重绘静态弹幕
      if (mounted) {
        setState(() {
          _staticAnimationController.value = 0;
        });
      }
    }

    _stopwatch.stop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        /// 计算视图宽度
        if (constraints.maxWidth != _viewWidth) {
          _viewWidth = constraints.maxWidth;
          for (DanmakuItem item in _topDanmakuItems) {
            if (item.content.isColorful == true) {
              item.strokeParagraph = null;
            }
          }
          for (DanmakuItem item in _bottomDanmakuItems) {
            if (item.content.isColorful == true) {
              item.strokeParagraph = null;
            }
          }
        }

        _trackCount =
            (constraints.maxHeight * _option.area / _danmakuHeight).floor();

        /// 为字幕留出余量
        if (_option.safeArea && _option.area == 1.0) {
          _trackCount = _trackCount - 1;
        }

        _trackYPositions =
            List<double>.generate(_trackCount, (i) => i * _danmakuHeight);
        return ClipRect(
          child: IgnorePointer(
            child: Opacity(
              opacity: _option.opacity,
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: ScrollDanmakuPainter(
                            progress: _animationController.value,
                            scrollDanmakuItems: _scrollDanmakuItems,
                            danmakuDurationInSeconds: _option.duration,
                            fontSize: _option.fontSize,
                            fontWeight: _option.fontWeight,
                            strokeWidth: _option.strokeWidth,
                            opacity: _option.opacity,
                            danmakuHeight: _danmakuHeight,
                            running: _running,
                            tick: _tick,
                          ),
                          size: const Size(double.infinity, double.infinity),
                        );
                      },
                    ),
                  ),
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _staticAnimationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: StaticDanmakuPainter(
                            progress: _staticAnimationController.value,
                            topDanmakuItems: _topDanmakuItems,
                            bottomDanmakuItems: _bottomDanmakuItems,
                            danmakuDurationInSeconds: _option.staticDuration,
                            fontSize: _option.fontSize,
                            fontWeight: _option.fontWeight,
                            strokeWidth: _option.strokeWidth,
                            opacity: _option.opacity,
                            danmakuHeight: _danmakuHeight,
                            running: _running,
                            tick: _tick,
                          ),
                          size: const Size(double.infinity, double.infinity),
                        );
                      },
                    ),
                  ),
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _animationController, // 与滚动弹幕共用控制器
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SpecialDanmakuPainter(
                            progress: _animationController.value,
                            specialDanmakuItems: _specialDanmakuItems,
                            fontSize: _option.fontSize,
                            fontWeight: _option.fontWeight,
                            strokeWidth: _option.strokeWidth,
                            running: _running,
                            tick: _tick,
                          ),
                          size: const Size(double.infinity, double.infinity),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
