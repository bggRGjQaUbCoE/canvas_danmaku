import 'package:canvas_danmaku/models/danmaku_item.dart';

class DanmakuOption {
  /// 默认的字体大小
  final double fontSize;

  /// 字体粗细
  final int fontWeight;

  /// 显示区域，0.1-1.0
  final double area;

  /// 滚动弹幕运行时间，秒
  final double duration;

  final double durationInMilliseconds;

  /// 静态弹幕运行时间，秒
  final double staticDuration;

  final double staticDurationInMilliseconds;

  /// 隐藏顶部弹幕
  final bool hideTop;

  /// 隐藏底部弹幕
  final bool hideBottom;

  /// 隐藏滚动弹幕
  final bool hideScroll;

  final bool hideSpecial;

  /// 弹幕描边
  final double strokeWidth;

  /// 海量弹幕模式 (弹幕轨道占满时进行叠加)
  final bool massiveMode;

  /// 为字幕预留空间
  final bool safeArea;

  /// 弹幕行高
  final double lineHeight;

  final void Function(DanmakuItem)? onTap;

  final void Function(List<DanmakuItem>)? onTapAll;

  const DanmakuOption({
    this.fontSize = 16,
    this.fontWeight = 4,
    this.area = 1.0,
    this.duration = 10,
    this.staticDuration = 5,
    this.hideBottom = false,
    this.hideScroll = false,
    this.hideTop = false,
    this.hideSpecial = false,
    this.strokeWidth = 1.5,
    this.massiveMode = false,
    this.safeArea = true,
    this.lineHeight = 1.6,
    this.onTap,
    this.onTapAll,
  })  : durationInMilliseconds = duration * 1000,
        staticDurationInMilliseconds = staticDuration * 1000,
        assert(onTap == null || onTapAll == null);

  DanmakuOption copyWith({
    double? fontSize,
    int? fontWeight,
    double? area,
    double? duration,
    double? staticDuration,
    bool? hideTop,
    bool? hideBottom,
    bool? hideScroll,
    bool? hideSpecial,
    double? strokeWidth,
    bool? massiveMode,
    bool? safeArea,
    double? lineHeight,
    void Function(DanmakuItem)? onTap,
    void Function(List<DanmakuItem>)? onTapAll,
  }) {
    return DanmakuOption(
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      duration: duration ?? this.duration,
      staticDuration: staticDuration ?? this.staticDuration,
      hideTop: hideTop ?? this.hideTop,
      hideBottom: hideBottom ?? this.hideBottom,
      hideScroll: hideScroll ?? this.hideScroll,
      hideSpecial: hideSpecial ?? this.hideSpecial,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      massiveMode: massiveMode ?? this.massiveMode,
      safeArea: safeArea ?? this.safeArea,
      lineHeight: lineHeight ?? this.lineHeight,
      onTap: onTap ?? this.onTap,
      onTapAll: onTapAll ?? this.onTapAll,
    );
  }
}
