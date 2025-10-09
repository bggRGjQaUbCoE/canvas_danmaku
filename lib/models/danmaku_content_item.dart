import 'dart:math' show pi;

import 'package:flutter/material.dart';

enum DanmakuItemType { scroll, top, bottom, special }

class DanmakuContentItem {
  /// 弹幕文本
  final String text;

  /// 弹幕颜色
  Color color;

  /// 弹幕类型
  final DanmakuItemType type;

  /// 是否为自己发送
  final bool selfSend;

  /// 是否为会员弹幕
  final bool isColorful;

  /// 弹幕数量
  final int? count;

  DanmakuContentItem(
    this.text, {
    this.color = Colors.white,
    this.type = DanmakuItemType.scroll,
    this.selfSend = false,
    this.isColorful = false,
    this.count,
  });
}

class SpecialDanmakuContentItem extends DanmakuContentItem {
  final int duration;

  final double fontSize; // 从弹幕内容外解析
  final bool hasStroke;
  final Tween<double>? alphaTween;

  final Tween<double> translateXTween; // 相对坐标
  final Tween<double> translateYTween; // 相对坐标
  final int translationDuration;
  final int translationStartDelay;

  final double rotateZ;
  final Matrix4? matrix;
  // final PathMetric? motionPathMetric;

  final Curve easingType;

  @override
  bool get isColorful => false;
  @override
  bool get selfSend => false;
  @override
  DanmakuItemType get type => DanmakuItemType.special;

  SpecialDanmakuContentItem(
    super.text, {
    required this.duration,
    required super.color,
    required this.fontSize,
    this.hasStroke = false,
    required this.translateXTween,
    required this.translateYTween,
    this.alphaTween,
    this.rotateZ = 0,
    this.matrix,
    // this.motionPathMetric,
    int? translationDuration,
    this.translationStartDelay = 0,
    super.count,
    this.easingType = Curves.linear,
  }) : translationDuration = translationDuration ?? duration;

  factory SpecialDanmakuContentItem.fromList(
    Color color,
    double fontSize,
    List list, {
    double videoX = 1920,
    double videoY = 1080,
    bool disableGradient = false,
  }) {
    final (startX, endX) = _toRelativePosition(list[0], list[7], videoX);
    final (startY, endY) = _toRelativePosition(list[1], list[8], videoY);
    final List<String> alphaString = list[2].split('-');
    final startA = double.tryParse(alphaString[0]) ?? 1;
    final endA = double.tryParse(alphaString[1]) ?? 1;
    Tween<double>? alphaTween;
    if (disableGradient || startA == endA) {
      color = color.withValues(alpha: (startA + endA) / 2);
    } else {
      color = color.withValues(alpha: startA);
      alphaTween = Tween(begin: startA, end: endA);
    }
    final duration = (_parseDouble(list[3]) * 1000).round();
    final String text = list[4].trim();
    final rotateZ = _degreeToRadian(_parseInt(list[5]));
    final rotateY = _parseInt(list[6]);
    final matrix = rotateY == 0
        ? null
        : (Matrix4.identity()..rotateY(_degreeToRadian(rotateY)));
    var translateXTween = _makeTween(startX, endX);
    var translateYTween = _makeTween(startY, endY);
    final translationDuration = _parseInt(list[9]);
    final translationStartDelay = _parseInt(list[10]);
    final hasStroke = list[11] == 1;
    // 字体
    // list[12];
    final easingType = list[13] == 1 ? Curves.easeInCubic : Curves.linear;
    // TODO 路径动画
    // List<Path> path;
    // if (list.length > 15) {
    //   list[14];
    // }
    return SpecialDanmakuContentItem(
      text,
      duration: duration,
      color: color,
      fontSize: fontSize,
      hasStroke: hasStroke,
      alphaTween: alphaTween,
      translateXTween: translateXTween,
      translateYTween: translateYTween,
      translationDuration: translationDuration,
      translationStartDelay: translationStartDelay,
      rotateZ: rotateZ,
      matrix: matrix,
      // motionPathMetric: null,
      easingType: easingType,
    );
  }

  static (double, double) _toRelativePosition(
    dynamic rawStart,
    dynamic rawEnd,
    double videoSize,
  ) {
    double toRadix(double? value, dynamic rawValue) =>
        (value! > 1 || (rawValue is String && !rawValue.contains('.')))
            ? value /= videoSize
            : value;

    double? convert(value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    double? start = convert(rawStart);
    double? end = convert(rawEnd);

    if (start == null && end == null) return (0, 0);
    start ??= end;
    end ??= start;

    return (toRadix(start, rawStart), toRadix(end, rawEnd));
  }

  static int _parseInt(dynamic digit) => switch (digit) {
        int() => digit,
        double() => digit.toInt(),
        String() => int.tryParse(digit) ?? 0,
        _ => throw UnimplementedError()
      };

  static double _parseDouble(dynamic digit) => switch (digit) {
        int() => digit.toDouble(),
        double() => digit,
        String() => double.tryParse(digit) ?? 0,
        _ => throw UnimplementedError()
      };

  static Tween<T> _makeTween<T>(T start, T end) {
    return start == end
        ? ConstantTween<T>(start)
        : Tween<T>(begin: start, end: end);
  }

  static double _degreeToRadian(int degree) {
    const pi180 = pi / 180;
    return degree * pi180;
  }
}
