import 'package:flutter/material.dart';

enum DanmakuItemType {
  scroll,
  top,
  bottom,
}

class DanmakuContentItem {
  /// 弹幕文本
  final String text;

  /// 弹幕颜色
  final Color color;

  /// 弹幕类型
  final DanmakuItemType type;

  /// 是否为自己发送
  final bool selfSend;

  DanmakuContentItem(
    this.text, {
    this.color = Colors.white,
    this.type = DanmakuItemType.scroll,
    this.selfSend = false,
  });
}
