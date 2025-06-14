import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'models/danmaku_item.dart';
import '/utils/utils.dart';

class ScrollDanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> scrollDanmakuItems;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final double opacity;
  final double danmakuHeight;
  final bool running;
  final int tick;
  final int batchThreshold;
  final double totalDuration;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  ScrollDanmakuPainter({
    required this.progress,
    required this.scrollDanmakuItems,
    required double danmakuDurationInSeconds,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.opacity,
    required this.danmakuHeight,
    required this.running,
    required this.tick,
    this.batchThreshold = 10, // 默认值为10，可以自行调整
  }) : totalDuration = danmakuDurationInSeconds * 1000;

  @override
  void paint(Canvas canvas, Size size) {
    final startPosition = size.width;

    if (scrollDanmakuItems.length > batchThreshold) {
      // 弹幕数量超过阈值时使用批量绘制
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas pictureCanvas = Canvas(pictureRecorder);

      for (DanmakuItem item in scrollDanmakuItems) {
        item.lastDrawTick ??= item.creationTime;
        final endPosition = -item.width;
        final distance = startPosition - endPosition;
        item.xPosition = item.xPosition +
            (((item.lastDrawTick! - tick) / totalDuration) * distance);

        if (item.xPosition < -item.width || item.xPosition > size.width) {
          continue;
        }

        item.paragraph ??= Utils.generateParagraph(
          content: item.content,
          danmakuWidth: size.width,
          fontSize: fontSize,
          fontWeight: fontWeight,
          size: item.content.isColorful == true
              ? Size(item.width, item.height)
              : null,
          screenSize: item.content.isColorful == true ? size : null,
          // opacity: opacity,
        );

        late Offset offset = Offset.zero;

        if (strokeWidth > 0) {
          if (item.content.isColorful == true) {
            item.strokeParagraph = Utils.generateStrokeParagraph(
              content: item.content,
              danmakuWidth: size.width,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
              size: Size(item.width, item.height),
              offset: Offset(item.xPosition, item.yPosition),
              screenSize: size,
              // opacity: opacity,
            );
          } else {
            item.strokeParagraph ??= Utils.generateStrokeParagraph(
              content: item.content,
              danmakuWidth: size.width,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
              // opacity: opacity,
            );
          }
          if (item.content.count != null) {
            TextPainter textPainter = Utils.getCountPainter(
              isStroke: true,
              content: item.content,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
            );
            offset = Offset(
                textPainter.width / 2, item.yPosition + danmakuHeight / 3);
            textPainter.paint(
              canvas,
              Offset(item.xPosition - offset.dx, offset.dy),
            );
            pictureCanvas.drawParagraph(
              item.strokeParagraph!,
              Offset(item.xPosition + offset.dx, item.yPosition),
            );
          } else {
            pictureCanvas.drawParagraph(
              item.strokeParagraph!,
              Offset(item.xPosition, item.yPosition),
            );
          }
        }

        if (item.content.selfSend) {
          pictureCanvas.drawRect(
            Offset(item.xPosition - 2, item.yPosition) &
                Size(item.width + 4, item.height),
            selfSendPaint,
          );
        }

        if (item.content.count != null) {
          TextPainter textPainter = Utils.getCountPainter(
            isStroke: false,
            content: item.content,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
          );
          textPainter.paint(
            canvas,
            Offset(item.xPosition - offset.dx, offset.dy),
          );
          pictureCanvas.drawParagraph(
            item.paragraph!,
            Offset(item.xPosition + offset.dx, item.yPosition),
          );
        } else {
          pictureCanvas.drawParagraph(
            item.paragraph!,
            Offset(item.xPosition, item.yPosition),
          );
        }

        item.lastDrawTick = tick;
      }

      final ui.Picture picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);
    } else {
      // 弹幕数量较少时直接绘制 (节约创建 canvas 的开销)
      for (DanmakuItem item in scrollDanmakuItems) {
        item.lastDrawTick ??= item.creationTime;
        final endPosition = -item.width;
        final distance = startPosition - endPosition;
        item.xPosition = item.xPosition +
            (((item.lastDrawTick! - tick) / totalDuration) * distance);

        if (item.xPosition < -item.width || item.xPosition > size.width) {
          continue;
        }

        item.paragraph ??= Utils.generateParagraph(
          content: item.content,
          danmakuWidth: size.width,
          fontSize: fontSize,
          fontWeight: fontWeight,
          size: item.content.isColorful == true
              ? Size(item.width, item.height)
              : null,
          screenSize: item.content.isColorful == true ? size : null,
          // opacity: opacity,
        );

        late Offset offset = Offset.zero;

        if (strokeWidth > 0) {
          if (item.content.isColorful == true) {
            item.strokeParagraph = Utils.generateStrokeParagraph(
              content: item.content,
              danmakuWidth: size.width,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
              size: Size(item.width, item.height),
              offset: Offset(item.xPosition, item.yPosition),
              screenSize: size,
              // opacity: opacity,
            );
          } else {
            item.strokeParagraph ??= Utils.generateStrokeParagraph(
              content: item.content,
              danmakuWidth: size.width,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
              // opacity: opacity,
            );
          }
          if (item.content.count != null) {
            TextPainter textPainter = Utils.getCountPainter(
              isStroke: true,
              content: item.content,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
            );
            offset = Offset(
                textPainter.width / 2, item.yPosition + danmakuHeight / 3);
            textPainter.paint(
              canvas,
              Offset(item.xPosition - offset.dx, offset.dy),
            );
            canvas.drawParagraph(
              item.strokeParagraph!,
              Offset(item.xPosition + offset.dx, item.yPosition),
            );
          } else {
            canvas.drawParagraph(
              item.strokeParagraph!,
              Offset(item.xPosition, item.yPosition),
            );
          }
        }

        if (item.content.selfSend) {
          canvas.drawRect(
            Offset(item.xPosition - 2, item.yPosition) &
                Size(item.width + 4, item.height),
            selfSendPaint,
          );
        }

        if (item.content.count != null) {
          TextPainter textPainter = Utils.getCountPainter(
            isStroke: false,
            content: item.content,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
          );
          textPainter.paint(
            canvas,
            Offset(item.xPosition - offset.dx, offset.dy),
          );
          canvas.drawParagraph(
            item.paragraph!,
            Offset(item.xPosition + offset.dx, item.yPosition),
          );
        } else {
          canvas.drawParagraph(
            item.paragraph!,
            Offset(item.xPosition, item.yPosition),
          );
        }

        item.lastDrawTick = tick;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScrollDanmakuPainter oldDelegate) {
    return running ||
        oldDelegate.scrollDanmakuItems.length != scrollDanmakuItems.length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.opacity != opacity;
  }
}
