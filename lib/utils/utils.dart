import 'dart:math';
import 'dart:ui' as ui;

import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:flutter/material.dart';

abstract final class DmUtils {
  static final Random random = Random();

  static const maxRasterizeSize = 8192.0;

  static String generateRandomString(int length) {
    const characters = '0123456789abcdefghijklmnopqrstuvwxyz';

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  static final Paint _selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green;

  static void updateSelfSendPaint(double strokeWidth) {
    _selfSendPaint.strokeWidth = strokeWidth;
  }

  static ui.Paragraph generateParagraph({
    required DanmakuContentItem content,
    required double fontSize,
    required int fontWeight,
  }) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontWeight: FontWeight.values[fontWeight],
      textDirection: TextDirection.ltr,
      maxLines: 1,
    ));

    if (content.count case final count?) {
      builder
        ..pushStyle(ui.TextStyle(
          color: content.color,
          fontSize: fontSize * 0.6,
        ))
        ..addText('($count)')
        ..pop();
    }

    builder
      ..pushStyle(ui.TextStyle(color: content.color, fontSize: fontSize))
      ..addText(content.text);

    return builder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
  }

  static ui.Image recordDanmakuImage({
    required ui.Paragraph contentParagraph,
    required DanmakuContentItem content,
    required double fontSize,
    required int fontWeight,
    required double strokeWidth,
    required double devicePixelRatio,
  }) {
    double w = contentParagraph.maxIntrinsicWidth + strokeWidth;
    double h = contentParagraph.height + strokeWidth;

    final offset = Offset(
      (strokeWidth / 2.0) + (content.selfSend ? 2.0 : 0.0),
      strokeWidth / 2.0,
    );

    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec)..scale(devicePixelRatio);

    if (strokeWidth != 0) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ));
      final Paint strokePaint = Paint()
        ..shader = content.isColorful
            ? const LinearGradient(
                    colors: [Color(0xFFF2509E), Color(0xFF308BCD)])
                .createShader(Rect.fromLTWH(0, 0, w, h))
            : null
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      final count = content.count;

      if (count != null) {
        builder
          ..pushStyle(ui.TextStyle(
            fontSize: fontSize * 0.6,
            foreground: strokePaint,
          ))
          ..addText('($count)')
          ..pop();
      }

      builder
        ..pushStyle(ui.TextStyle(fontSize: fontSize, foreground: strokePaint))
        ..addText(content.text);

      if (!content.isColorful) {
        strokePaint.color = Colors.black;
      }

      final strokeParagraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: double.infinity));

      canvas.drawParagraph(strokeParagraph, offset);
      strokeParagraph.dispose();
    }

    canvas.drawParagraph(contentParagraph, offset);

    if (content.selfSend) {
      w += 4;
      canvas.drawRect(Rect.fromLTRB(0, 0, w, h), _selfSendPaint);
    }

    final pic = rec.endRecording();
    final img = pic.toImageSync(
      (w * devicePixelRatio).ceil(),
      (h * devicePixelRatio).ceil(),
    );
    pic.dispose();
    return img;
  }

  static ui.Image recordSpecialDanmakuImg({
    required SpecialDanmakuContentItem content,
    required int fontWeight,
    required double strokeWidth,
    required double devicePixelRatio,
    required Size playerSize,
  }) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontWeight: FontWeight.values[fontWeight],
      textDirection: TextDirection.ltr,
      fontSize: content.fontSize,
    ))
      ..pushStyle(ui.TextStyle(
        color: content.color,
        fontSize: content.fontSize,
        shadows: content.hasStroke
            ? [Shadow(color: Colors.black, blurRadius: strokeWidth)]
            : null,
      ))
      ..addText(content.text);

    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));

    final strokeOffset = strokeWidth / 2;
    final totalWidth = paragraph.maxIntrinsicWidth + strokeWidth;
    final totalHeight = paragraph.height + strokeWidth;

    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);

    final Rect rect;
    double adjuestDevicePixelRatio = devicePixelRatio;

    final Size imgSize;
    if (content.rotateZ != 0 || content.matrix != null) {
      final translatedRect = _calculateRotatedBounds(
        totalWidth,
        totalHeight,
        content.rotateZ,
        content.matrix,
      );

      rect = _calculateCroppedImageSize(
        playerSize,
        translatedRect,
        content.translateXTween,
        content.translateYTween,
      );

      imgSize = rect.size * devicePixelRatio;
      final imgLongestSide = imgSize.longestSide;
      if (imgLongestSide > maxRasterizeSize) {
        // force resize
        adjuestDevicePixelRatio = maxRasterizeSize / imgLongestSide;
      }
      canvas
        ..scale(adjuestDevicePixelRatio)
        ..translate(strokeOffset - rect.left, strokeOffset - rect.top);

      if (content.matrix case final matrix?) {
        canvas.transform(matrix.storage);
      } else {
        canvas.rotate(content.rotateZ);
      }
      canvas.drawParagraph(paragraph, Offset.zero);
    } else {
      rect = _calculateCroppedImageSize(
        playerSize,
        Rect.fromLTRB(0, 0, totalWidth, totalHeight),
        content.translateXTween,
        content.translateYTween,
      );

      imgSize = rect.size * devicePixelRatio;

      final imgLongestSide = imgSize.longestSide;
      if (imgLongestSide > maxRasterizeSize) {
        final scale = maxRasterizeSize / imgLongestSide;
        adjuestDevicePixelRatio = scale;
      }
      canvas
        ..scale(adjuestDevicePixelRatio)
        ..drawParagraph(paragraph, Offset(strokeOffset, strokeOffset));
    }

    content.rect = rect;

    final pic = rec.endRecording();
    final img = pic.toImageSync(imgSize.width.ceil(), imgSize.height.ceil());
    pic.dispose();
    paragraph.dispose();

    return img;
  }

  static Rect _calculateRotatedBounds(
    double w,
    double h,
    double rotateZ,
    Matrix4? matrix,
  ) {
    final double cosZ;
    final double cosY;
    final double sinZ;
    if (matrix == null) {
      cosZ = cos(rotateZ);
      sinZ = sin(rotateZ);
      cosY = 1;
    } else {
      cosZ = matrix[5];
      sinZ = matrix[1];
      cosY = matrix[10];
    }

    final wx = w * cosZ * cosY;
    final wy = w * sinZ;
    final hx = -h * sinZ * cosY;
    final hy = h * cosZ;

    final minX = _min4(0.0, wx, hx, wx + hx);
    final maxX = _max4(0.0, wx, hx, wx + hx);
    final minY = _min4(0.0, wy, hy, wy + hy);
    final maxY = _max4(0.0, wy, hy, wy + hy);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @pragma("vm:prefer-inline")
  static double _min4(double a, double b, double c, double d) {
    final ab = a < b ? a : b;
    final cd = c < d ? c : d;
    return ab < cd ? ab : cd;
  }

  @pragma("vm:prefer-inline")
  static double _max4(double a, double b, double c, double d) {
    final ab = a > b ? a : b;
    final cd = c > d ? c : d;
    return ab > cd ? ab : cd;
  }

  static Rect _calculateCroppedImageSize(
    Size windowSize,
    Rect rect,
    Tween<double> xTween,
    Tween<double> yTween,
  ) {
    final imgSize = rect.size;

    double maxX =
        max(xTween.begin!, xTween.end!) * windowSize.width + rect.left;
    double maxY =
        max(yTween.begin!, yTween.end!) * windowSize.height + rect.top;

    double minX =
        min(xTween.begin!, xTween.end!) * windowSize.width + rect.left;
    double minY =
        min(yTween.begin!, yTween.end!) * windowSize.height + rect.top;

    double left = max(0, -maxX);
    double top = max(0, -maxY);
    double right = min(imgSize.width, windowSize.width - minX);
    double bottom = min(imgSize.height, windowSize.height - minY);

    assert(right > left && bottom > top);

    return Rect.fromLTRB(left, top, right, bottom).shift(rect.topLeft);
  }
}
