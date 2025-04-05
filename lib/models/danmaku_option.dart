class DanmakuOption {
  /// 默认的字体大小
  final double fontSize;

  /// 字体粗细
  final int fontWeight;

  /// 显示区域，0.1-1.0
  final double area;

  /// 滚动弹幕运行时间，秒
  final double duration;

  /// 静态弹幕运行时间，秒
  final double staticDuration;

  /// 不透明度，0.1-1.0
  final double opacity;

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

  DanmakuOption({
    this.fontSize = 16,
    this.fontWeight = 4,
    this.area = 1.0,
    this.duration = 10,
    this.staticDuration = 5,
    this.opacity = 1.0,
    this.hideBottom = false,
    this.hideScroll = false,
    this.hideTop = false,
    this.hideSpecial = false,
    this.strokeWidth = 1.5,
    this.massiveMode = false,
    this.safeArea = true,
    this.lineHeight = 1.6,
  });

  DanmakuOption copyWith({
    double? fontSize,
    int? fontWeight,
    double? area,
    double? duration,
    double? staticDuration,
    double? opacity,
    bool? hideTop,
    bool? hideBottom,
    bool? hideScroll,
    double? strokeWidth,
    bool? massiveMode,
    bool? safeArea,
    double? lineHeight,
  }) {
    return DanmakuOption(
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      duration: duration ?? this.duration,
      staticDuration: staticDuration ?? this.staticDuration,
      opacity: opacity ?? this.opacity,
      hideTop: hideTop ?? this.hideTop,
      hideBottom: hideBottom ?? this.hideBottom,
      hideScroll: hideScroll ?? this.hideScroll,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      massiveMode: massiveMode ?? this.massiveMode,
      safeArea: safeArea ?? this.safeArea,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }
}
