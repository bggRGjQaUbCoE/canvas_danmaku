import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:flutter/material.dart';

class DanmakuController {
  final bool Function(DanmakuContentItem) addDanmaku;
  final ValueChanged<DanmakuOption> updateOption;
  final VoidCallback pause;
  final VoidCallback resume;
  final VoidCallback clear;
  final ValueGetter<DanmakuOption> getOption;
  final ValueGetter<bool> isRunning;
  final ValueGetter<int> getTrackCount;

  final List<List<DanmakuItem>> scrollDanmaku;
  final List<DanmakuItem?> staticDanmaku;

  DanmakuOption get option => getOption();

  bool get running => isRunning();

  int get trackCount => getTrackCount();

  DanmakuController({
    required this.addDanmaku,
    required this.updateOption,
    required this.pause,
    required this.resume,
    required this.clear,
    required this.getOption,
    required this.isRunning,
    required this.getTrackCount,
    required this.scrollDanmaku,
    required this.staticDanmaku,
  });
}
