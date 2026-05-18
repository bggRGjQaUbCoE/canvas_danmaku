import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

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

  /// 弹幕显示区域
  double _area = 1.0;

  /// 弹幕粗细
  int _fontWeight = 4;

  /// 隐藏滚动弹幕
  bool _hideScroll = false;

  /// 隐藏顶部弹幕
  bool _hideTop = false;

  /// 隐藏底部弹幕
  bool _hideBottom = false;

  /// 隐藏高级弹幕
  bool _hideSpecial = false;

  /// 为字幕预留空间
  bool _safeArea = true;

  /// 静态弹幕无法添加时作为滚动弹幕添加
  bool _static2Scroll = false;

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
                  child: const Text('Self'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条自己发的弹幕",
                        color: getRandomColor(),
                        // color: Colors.white,
                        // isColorful: true,
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
                TextButton(
                  child: const Text('LongTop'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条超长顶部弹幕。" * 10,
                        color: getRandomColor(),
                        // color: Colors.white,
                        // isColorful: true,
                        type: DanmakuItemType.top,
                      ),
                    );
                  },
                ),
                TextButton(
                  child: const Text('LongShort'),
                  onPressed: () {
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条超长滚动弹幕。" * 10,
                        color: getRandomColor(),
                        // color: Colors.white,
                        // isColorful: true,
                        type: DanmakuItemType.scroll,
                      ),
                    );
                    _controller?.addDanmaku(
                      DanmakuContentItem(
                        "这是一条短滚动弹幕",
                        color: getRandomColor(),
                        // color: Colors.white,
                        // isColorful: true,
                        type: DanmakuItemType.scroll,
                      ),
                    );
                  },
                ),
                TextButton(
                  onPressed: loadXmlDmFromAsset,
                  child: const Text('XML'),
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
                    _stopTimer();
                  },
                  tooltip: 'Clear',
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: Colors.grey,
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 100),
                child: LayoutBuilder(
                  builder: (_, constrains) {
                    return DanmakuScreen(
                      createdController: (e) {
                        _controller = e;
                      },
                      option: DanmakuOption(
                        fontSize: _fontSize,
                        fontWeight: _fontWeight,
                        duration: _duration,
                        staticDuration: _staticDuration,
                        strokeWidth: _strokeWidth,
                        massiveMode: _massiveMode,
                        static2Scroll: _static2Scroll,
                        hideScroll: _hideScroll,
                        hideTop: _hideTop,
                        hideBottom: _hideBottom,
                        safeArea: _safeArea,
                        lineHeight: _lineHeight,
                      ),
                      size: constrains.biggest,
                    );
                  },
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
              Text("Opacity : $_opacity"),
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
                      Text("Font Size : $_fontSize"),
                      Slider(
                        value: _fontSize,
                        min: 8,
                        max: 100,
                        onChanged: (e) {
                          if (_controller != null) {
                            _fontSize = e.round().toDouble();
                            _controller!.updateOption(
                              _controller!.option.copyWith(fontSize: _fontSize),
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
                      Text("Area : $_area"),
                      Slider(
                        value: _area,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: (e) {
                          if (_controller != null) {
                            _area = e.toPrecision(1);
                            _controller!.updateOption(
                              _controller!.option.copyWith(area: _area),
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
                      Text("Static Duration : $_staticDuration"),
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
                    title: const Text('scrollFixedVelocity'),
                    value: _controller!.option.scrollFixedVelocity,
                    onChanged: (e) {
                      if (_controller != null) {
                        _controller!.updateOption(
                          _controller!.option.copyWith(scrollFixedVelocity: e),
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
                    title: const Text('Static2Scroll'),
                    value: _static2Scroll,
                    onChanged: (e) {
                      if (_controller != null) {
                        _static2Scroll = e;
                        _controller!.updateOption(
                          _controller!.option.copyWith(static2Scroll: e),
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

  Timer? _timer;

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> loadXmlDmFromAsset() async {
    _stopTimer();

    // final xmlString = await rootBundle.loadString('assets/dm.xml');
    final xmlString = await rootBundle.loadString('assets/dm_special.xml');
    final document = XmlDocument.parse(xmlString);

    final danmakus = document.findAllElements('d').toList();

    int index = 0;
    final length = danmakus.length;
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (index >= length || _controller == null) {
        _stopTimer();
        return;
      }
      final dm = danmakus[index];
      final pAttr = dm.getAttribute('p');
      final content = dm.innerText;
      if (pAttr != null) {
        final parts = pAttr.split(',');
        final type = _parseType(parts[1]);
        final color = _parseColor(parts[3]);
        _controller?.addDanmaku(
          DanmakuContentItem(
            content,
            type: type,
            color: color,
          ),
        );
      }
      index++;
    });
  }

  Color _parseColor(String color) => Color(int.parse(color) | 0xFF000000);

  DanmakuItemType _parseType(String type) => switch (type) {
    '4' => DanmakuItemType.bottom,
    '5' => DanmakuItemType.top,
    _ => DanmakuItemType.scroll,
  };

  Future<void> startPlay() async {
    _stopTimer();
    String data = await rootBundle.loadString('assets/132590001.json');
    List<DanmakuContentItem> items = [];
    Map jsonMap = json.decode(data);
    for (Map item in jsonMap['comments']) {
      final parts = (item['p'] as String).split(',');
      items.add(
        DanmakuContentItem(
          item['m'],
          type: _parseType(parts[1]),
          color: _parseColor(parts[2]),
        ),
      );
    }
    int index = 0;
    final length = items.length;
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (index >= length || _controller == null) {
        _stopTimer();
        return;
      }
      _controller?.addDanmaku(items[index]);
      index++;
    });
  }

  // 生成随机颜色
  static Color getRandomColor() {
    return Color(0xFF000000 | _random.nextInt(0x1000000));
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

class TrianglePainter extends CustomPainter {
  TrianglePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => color != oldDelegate.color;
}

extension on double {
  double toPrecision(int fractionDigits) {
    final mod = pow(10, fractionDigits).toDouble();
    return (this * mod).roundToDouble() / mod;
  }
}
