import 'dart:ui' as ui;

import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';

abstract base class BaseDanmakuPainter extends CustomPainter {
  final int length;
  final List<DanmakuItem> danmakuItems;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final bool running;
  final int batchThreshold;
  final int tick;

  const BaseDanmakuPainter({
    required this.length,
    required this.danmakuItems,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.running,
    required this.tick,
    this.batchThreshold = 10, // 默认值为10，可以自行调整
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ui.PictureRecorder? pictureRecorder;
    final Canvas pictureCanvas;
    final length = danmakuItems.length;

    if (length > batchThreshold) {
      pictureRecorder = ui.PictureRecorder();
      pictureCanvas = Canvas(pictureRecorder);
    } else {
      pictureRecorder = null;
      pictureCanvas = canvas;
    }

    for (var i in danmakuItems) {
      if (!i.expired) paintDanmaku(pictureCanvas, size, i);
    }

    if (pictureRecorder != null) {
      final ui.Picture picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);
      picture.dispose();
    }
  }

  void paintDanmaku(Canvas canvas, Size size, DanmakuItem item);

  @override
  bool shouldRepaint(covariant BaseDanmakuPainter oldDelegate) {
    return (running && oldDelegate.length != 0) ||
        oldDelegate.tick == tick ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
