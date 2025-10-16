import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:flutter/material.dart';

final class StaticDanmakuPainter extends CustomPainter {
  final int length;
  final List<DanmakuItem> danmakuItems;
  final double staticDurationInMilliseconds;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final int tick;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  StaticDanmakuPainter({
    required this.length,
    required this.danmakuItems,
    required this.staticDurationInMilliseconds,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.tick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in danmakuItems) {
      item
        ..drawTick ??= tick
        ..drawParagraphIfNeeded(fontSize, fontWeight, strokeWidth)
        ..xPosition = (size.width - item.width) / 2;

      canvas.drawImage(
        item.image!,
        Offset(
          item.xPosition,
          item.content.type == DanmakuItemType.bottom
              ? size.height - item.yPosition - item.height
              : item.yPosition,
        ),
        Paint(),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StaticDanmakuPainter oldDelegate) =>
      oldDelegate.length != length ||
      oldDelegate.fontSize != fontSize ||
      oldDelegate.fontWeight != fontWeight ||
      oldDelegate.strokeWidth != strokeWidth;
}
