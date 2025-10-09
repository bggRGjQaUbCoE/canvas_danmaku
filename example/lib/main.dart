import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CanvasDanmaku Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final _random = Random();

  DanmakuController? _controller;

  final _danmuKey = GlobalKey();

  /// 弹幕行高
  double _lineHeight = 1.6;

  /// 弹幕描边
  double _strokeWidth = 1.5;

  /// 弹幕海量模式(弹幕轨道填满时继续绘制)
  bool _massiveMode = false;

  /// 弹幕透明度
  double _opacity = 1.0;

  /// 滚动弹幕持续时间
  double _duration = 8.0;

  /// 静态弹幕持续时间
  double _staticDuration = 3.0;

  /// 弹幕字号
  double _fontSize = (Platform.isIOS || Platform.isAndroid) ? 16 : 25;

  /// 弹幕粗细
  int _fontWeight = 4;

  /// 隐藏滚动弹幕
  bool _hideScroll = false;

  /// 隐藏顶部弹幕
  bool _hideTop = false;

  /// 隐藏底部弹幕
  bool _hideBottom = false;

  bool _hideSpecial = false;

  /// 为字幕预留空间
  bool _safeArea = true;

  DanmakuItem? _suspendedDM;
  OverlayEntry? _overlayEntry;
  void _removeOverlay() {
    _suspendedDM?.suspend = false;
    _suspendedDM = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CanvasDanmaku Demo'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            child: Row(
              children: [
                TextButton(
                  child: const Text('Scroll'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条超长弹幕ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789这是一条超长的弹幕，这条弹幕会超出屏幕宽度",
                        // isColorful: true,
                        // color: Colors.white,
                        color: getRandomColor(),
                        count: [1, 10, 100, 1000, 10000][_random.nextInt(5)],
                      ),
                    );
                  },
                ),
                TextButton(
                  child: const Text('Top'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条顶部弹幕",
                        color: getRandomColor(),
                        // isColorful: true,
                        // color: Colors.white,
                        type: DanmakuItemType.top,
                        count: [1, 10, 100, 1000, 10000][_random.nextInt(5)],
                      ),
                    );
                  },
                ),
                TextButton(
                  child: const Text('Bottom'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条底部弹幕",
                        color: getRandomColor(),
                        // isColorful: true,
                        // color: Colors.white,
                        type: DanmakuItemType.bottom,
                        count: [1, 10, 100, 1000, 10000][_random.nextInt(5)],
                      ),
                    );
                  },
                ),
                TextButton(
                  child: const Text('Special'),
                  onPressed: () {
                    _controller?.addDanmaku(randSpecialDanmaku());
                  },
                  onLongPress: () {
                    for (var i = 0; i < 100; i++) {
                      _controller?.addDanmaku(randSpecialDanmaku());
                    }
                  },
                ),
                TextButton(
                  child: const Text('Circle'),
                  onPressed: () {
                    Iterable.generate(
                      36,
                      (i) => SpecialDanmakuContentItem(
                        '测试',
                        duration: 4000,
                        color: Colors.red,
                        fontSize: 64 * 2,
                        translateXTween: Tween<double>(begin: 0.5, end: 0.5),
                        translateYTween: Tween<double>(begin: 0.5, end: 0.5),
                        alphaTween: Tween<double>(begin: 1, end: 0),
                        rotateZ: i * pi / 18,
                        easingType: Curves.linear,
                        hasStroke: true,
                      ),
                    ).forEach(_controller!.addDanmaku);
                  },
                ),
                TextButton(
                  child: const Text('Star'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      SpecialDanmakuContentItem.fromList(getRandomColor(), 44, [
                        "0.939",
                        "0.083",
                        "1-1",
                        "6",
                        "☆——————\n" * 14,
                        "342",
                        "0",
                        "0.002",
                        "0.271",
                        500,
                        0,
                        1,
                        "SimHei",
                        1,
                      ]),
                    );
                  },
                ),
                TextButton(
                  child: const Text('DanMu'),
                  onPressed: () async {
                    String data = await rootBundle.loadString('assets/dm.json');
                    final danmaku = jsonDecode(data) as List;
                    final dan = danmaku.last as List;
                    final mu = danmaku.first as List;
                    for (var item in dan) {
                      _controller?.addDanmaku(
                        SpecialDanmakuContentItem.fromList(
                          Colors.orange,
                          16,
                          item,
                        ),
                      );
                    }
                    await Future.delayed(const Duration(seconds: 2));
                    for (var item in mu) {
                      _controller?.addDanmaku(
                        SpecialDanmakuContentItem.fromList(
                          Colors.orange,
                          16,
                          item,
                        ),
                      );
                    }
                  },
                ),
                TextButton(
                  child: const Text('Self'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条自己发的弹幕",
                        // color: getRandomColor(),
                        color: Colors.white,
                        isColorful: true,
                        type: const [
                          DanmakuItemType.top,
                          DanmakuItemType.bottom,
                          DanmakuItemType.scroll,
                        ][_random.nextInt(3)],
                        selfSend: true,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_outline_outlined),
                  onPressed: startPlay,
                  tooltip: 'Start Player',
                ),
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Icon(
                        _controller?.running ?? true
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        if (_controller != null) {
                          if (_controller!.running) {
                            _controller!.pause();
                          } else {
                            _controller!.resume();
                          }
                          (context as Element).markNeedsBuild();
                        }
                      },
                      tooltip: 'Play Resume',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller?.clear();
                    _removeOverlay();
                  },
                  tooltip: 'Clear',
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _random.nextDouble() * 50 + 10,
                _random.nextDouble() * 50 + 10,
                _random.nextDouble() * 50 + 10,
                _random.nextDouble() * 50 + 10,
              ),
              child: Listener(
                onPointerUp: (event) {
                  if (_controller == null) return;

                  // final items = _controller
                  //     !.findDanmaku(event.localPosition)
                  //     .toList();
                  // if (items != null && items.isNotEmpty) {
                  //   for (var i in items) {
                  //     i.suspend = true;
                  //   }
                  //   debugPrint(items.toString());
                  // Future.delayed(const Duration(seconds: 3), () {
                  //   for (var i in items) {
                  //     i.suspend = false;
                  //   }
                  // });
                  // }

                  /// single
                  final item = _controller!.findSingleDanmaku(
                    event.localPosition,
                  );

                  if (item == null) {
                    _removeOverlay();
                  } else if (item != _suspendedDM) {
                    _removeOverlay();
                    item.suspend = true;
                    _suspendedDM = item;

                    const spacing = 10.0;
                    const width = 50.0;
                    const height = 25.0;

                    final dy = item.content.type == DanmakuItemType.bottom
                        ? _controller!.viewHeight - item.yPosition - item.height
                        : item.yPosition;
                    final dySpacing =
                        event.position.dy - event.localPosition.dy;
                    final dxSpacing =
                        event.position.dx - event.localPosition.dx;
                    _overlayEntry = OverlayEntry(
                      builder: (context) {
                        return Positioned(
                          top: dy + item.height + dySpacing,
                          left: clampDouble(
                            event.position.dx - height,
                            spacing + dxSpacing,
                            _controller!.viewWidth -
                                width -
                                spacing +
                                dxSpacing,
                          ),
                          child: Container(
                            width: width,
                            height: height,
                            color: getRandomColor(),
                          ),
                        );
                      },
                    );
                    Overlay.of(context).insert(_overlayEntry!);
                  }
                },
                child: ColoredBox(
                  color: Colors.grey,
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 100),
                    child: DanmakuScreen(
                      key: _danmuKey,
                      createdController: (DanmakuController e) {
                        _controller = e;
                      },
                      option: DanmakuOption(
                        fontSize: _fontSize,
                        fontWeight: _fontWeight,
                        duration: _duration,
                        staticDuration: _staticDuration,
                        strokeWidth: _strokeWidth,
                        massiveMode: _massiveMode,
                        hideScroll: _hideScroll,
                        hideTop: _hideTop,
                        hideBottom: _hideBottom,
                        safeArea: _safeArea,
                        lineHeight: _lineHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Builder(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Line Height : $_lineHeight"),
                      Slider(
                        value: _lineHeight,
                        min: 1.0,
                        max: 3.0,
                        onChanged: (e) {
                          if (_controller != null) {
                            _lineHeight = double.parse(e.toStringAsFixed(1));
                            _controller!.updateOption(
                              _controller!.option.copyWith(
                                lineHeight: _lineHeight,
                              ),
                            );
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Stroke Width : $_strokeWidth"),
                      Slider(
                        value: _strokeWidth,
                        min: 0,
                        max: 10,
                        divisions: 20,
                        onChanged: (e) {
                          if (_controller != null) {
                            _strokeWidth = e;
                            _controller!.updateOption(
                              _controller!.option.copyWith(
                                strokeWidth: _strokeWidth,
                              ),
                            );
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Font Weight : $_fontWeight"),
                      Slider(
                        value: _fontWeight.toDouble(),
                        min: 0,
                        max: 8,
                        divisions: 8,
                        onChanged: (e) {
                          if (_controller != null) {
                            _fontWeight = e.toInt();
                            _controller!.updateOption(
                              _controller!.option.copyWith(
                                fontWeight: _fontWeight,
                              ),
                            );
                          }
                          (context as Element).markNeedsBuild();
                        },
                      ),
                    ],
                  );
                },
              ),
              const Text("Opacity : "),
              Slider(
                value: _opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (e) {
                  _opacity = double.parse(e.toStringAsFixed(1));
                  setState(() {});
                },
              ),
              Builder(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Font Size : "),
                      Slider(
                        value: _fontSize,
                        min: 8,
                        max: 36,
                        divisions: 14,
                        onChanged: (e) {
                          if (_controller != null) {
                            _fontSize = e;
                            _controller!.updateOption(
                              _controller!.option.copyWith(fontSize: e),
                            );
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Scroll Duration : $_duration"),
                      Slider(
                        value: _duration.toDouble(),
                        min: 4,
                        max: 20,
                        divisions: 16,
                        onChanged: (e) {
                          if (_controller != null) {
                            _duration = e;
                            _controller!.updateOption(
                              _controller!.option.copyWith(duration: _duration),
                            );
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Static Duration : "),
                      Slider(
                        value: _staticDuration.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        onChanged: (e) {
                          if (_controller != null) {
                            _staticDuration = e;
                            _controller!.updateOption(
                              _controller!.option.copyWith(
                                staticDuration: _staticDuration,
                              ),
                            );
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return SwitchListTile(
                    title: const Text('MassiveMode'),
                    value: _massiveMode,
                    onChanged: (e) {
                      if (_controller != null) {
                        _massiveMode = e;
                        _controller!.updateOption(
                          _controller!.option.copyWith(massiveMode: e),
                        );
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return SwitchListTile(
                    title: const Text('SafeArea'),
                    value: _safeArea,
                    onChanged: (e) {
                      if (_controller != null) {
                        _safeArea = e;
                        _controller!.updateOption(
                          _controller!.option.copyWith(safeArea: e),
                        );
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return SwitchListTile(
                    title: const Text('hide scroll'),
                    value: _hideScroll,
                    onChanged: (e) {
                      if (_controller != null) {
                        _hideScroll = e;
                        _controller!.updateOption(
                          _controller!.option.copyWith(hideScroll: e),
                        );
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return SwitchListTile(
                    title: const Text('hide top'),
                    value: _hideTop,
                    onChanged: (e) {
                      if (_controller != null) {
                        _hideTop = e;
                        _controller!.updateOption(
                          _controller!.option.copyWith(hideTop: e),
                        );
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return SwitchListTile(
                    title: const Text('hide bottom'),
                    value: _hideBottom,
                    onChanged: (e) {
                      if (_controller != null) {
                        _hideBottom = e;
                        _controller!.updateOption(
                          _controller!.option.copyWith(hideBottom: e),
                        );
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return SwitchListTile(
                    title: const Text('hide special'),
                    value: _hideSpecial,
                    onChanged: (e) {
                      if (_controller != null) {
                        _hideSpecial = e;
                        _controller!.updateOption(
                          _controller!.option.copyWith(hideSpecial: e),
                        );
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Timer? timer;
  int sec = 0;
  Future<void> startPlay() async {
    String data = await rootBundle.loadString('assets/132590001.json');
    List<DanmakuContentItem> items = [];
    Map jsonMap = json.decode(data);
    for (Map item in jsonMap['comments']) {
      items.add(
        DanmakuContentItem(
          item['m'],
          color: Colors.white,
        ),
      );
    }
    timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller == null) return;
      _controller?.addDanmaku(items[sec]);
      sec++;
    });
  }

  // 生成随机颜色
  static Color getRandomColor() {
    return Color(0xFF000000 | _random.nextInt(0x1000000));
  }

  static SpecialDanmakuContentItem randSpecialDanmaku() {
    final translationStartDelay = _random.nextInt(1000);
    final translationDuration = _random.nextInt(14000);
    final duration =
        translationStartDelay + translationDuration + _random.nextInt(1000);
    return SpecialDanmakuContentItem(
      '这是一条特殊弹幕',
      color: getRandomColor(),
      fontSize: _random.nextInt(50) + 25,
      translateXTween: Tween<double>(
        begin: _random.nextDouble(),
        end: _random.nextDouble(),
      ),
      translateYTween: Tween<double>(
        begin: _random.nextDouble(),
        end: _random.nextDouble(),
      ),
      alphaTween: Tween<double>(
        begin: _random.nextDouble(),
        end: _random.nextDouble(),
      ),
      rotateZ: _random.nextDouble() * pi,
      // matrix: Matrix4.identity()..rotateY(_random.nextDouble() * pi),
      duration: duration,
      translationDuration: translationDuration,
      translationStartDelay: translationStartDelay,
      easingType: const [Curves.linear, Curves.easeInCubic][_random.nextInt(2)],
      hasStroke: _random.nextBool(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
