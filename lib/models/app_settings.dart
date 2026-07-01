/// 应用设置模型
/// 管理颜色自定义、字体大小等用户偏好
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 颜色数值与名称映射
class ColorOption {
  final String name;
  final Color color;
  const ColorOption(this.name, this.color);
}

/// 预设颜色列表——供用户选择
const List<ColorOption> presetColors = [
  ColorOption('橙色', Color(0xFFFF9800)),
  ColorOption('红色', Color(0xFFE53935)),
  ColorOption('绿色', Color(0xFF43A047)),
  ColorOption('蓝色', Color(0xFF1E88E5)),
  ColorOption('棕色', Color(0xFF8B4513)),
  ColorOption('紫色', Color(0xFF8E24AA)),
  ColorOption('青色', Color(0xFF00ACC1)),
  ColorOption('灰色', Color(0xFF757575)),
  ColorOption('黑色', Color(0xFF000000)),
];

class AppSettings {
  // ========== 爻颜色 ==========
  Color staticYaoColor;      // 静爻颜色
  Color dongYaoColor;        // 动爻颜色
  double yaoFontSize;        // 爻象字体大小

  // ========== 连线颜色 ==========
  Color chongLineColor;      // 冲线颜色
  Color heLineColor;         // 合线颜色
  Color shengLineColor;      // 生线颜色
  Color keLineColor;         // 克线颜色

  // ========== 显示开关 ==========
  bool showColoredWuXing;    // 地支五行彩色显示

  AppSettings({
    Color? staticYaoColor,
    Color? dongYaoColor,
    double? yaoFontSize,
    Color? chongLineColor,
    Color? heLineColor,
    Color? shengLineColor,
    Color? keLineColor,
    this.showColoredWuXing = false,
  })  : staticYaoColor = staticYaoColor ?? const Color(0xFF8B4513),
        dongYaoColor = dongYaoColor ?? Colors.orange.shade700,
        yaoFontSize = yaoFontSize ?? 13,
        chongLineColor = chongLineColor ?? const Color(0xFFE53935),
        heLineColor = heLineColor ?? const Color(0xFF43A047),
        shengLineColor = shengLineColor ?? const Color(0xFFFFB300),
        keLineColor = keLineColor ?? const Color(0xFF1E88E5);

  /// 获取连线颜色（按关系类型）
  Color getLineColor(int relationType) {
    switch (relationType) {
      case 1: return chongLineColor; // 冲
      case 2: return heLineColor;    // 合
      case 3: return heLineColor;    // 三合（复用合色）
      case 4: return shengLineColor; // 生
      case 5: return keLineColor;    // 克
      default: return const Color(0xFF757575);
    }
  }

  // ========== 持久化 ==========

  static const String _prefsKey = 'app_settings';

  /// 卦象五行 → 颜色
  static const Map<String, Color> wuXingColors = {
    '金': Color(0xFFD4A017), // 金色
    '木': Color(0xFF388E3C), // 绿色
    '水': Color(0xFF1976D2), // 蓝色
    '火': Color(0xFFD32F2F), // 红色
    '土': Color(0xFF4E342E), // 棕色
  };

  Map<String, dynamic> toJson() => {
    'staticYaoColor': staticYaoColor.value,
    'dongYaoColor': dongYaoColor.value,
    'yaoFontSize': yaoFontSize,
    'chongLineColor': chongLineColor.value,
    'heLineColor': heLineColor.value,
    'shengLineColor': shengLineColor.value,
    'keLineColor': keLineColor.value,
    'showColoredWuXing': showColoredWuXing,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    staticYaoColor: json['staticYaoColor'] != null ? Color(json['staticYaoColor'] as int) : null,
    dongYaoColor: json['dongYaoColor'] != null ? Color(json['dongYaoColor'] as int) : null,
    yaoFontSize: json['yaoFontSize'] != null ? (json['yaoFontSize'] as num).toDouble() : null,
    chongLineColor: json['chongLineColor'] != null ? Color(json['chongLineColor'] as int) : null,
    heLineColor: json['heLineColor'] != null ? Color(json['heLineColor'] as int) : null,
    shengLineColor: json['shengLineColor'] != null ? Color(json['shengLineColor'] as int) : null,
    keLineColor: json['keLineColor'] != null ? Color(json['keLineColor'] as int) : null,
    showColoredWuXing: json['showColoredWuXing'] as bool? ?? false,
  );

  /// 加载设置
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null || jsonStr.isEmpty) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  /// 保存设置
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(toJson()));
  }

  /// 复制并更新
  AppSettings copyWith({
    Color? staticYaoColor,
    Color? dongYaoColor,
    double? yaoFontSize,
    Color? chongLineColor,
    Color? heLineColor,
    Color? shengLineColor,
    Color? keLineColor,
    bool? showColoredWuXing,
  }) {
    return AppSettings(
      staticYaoColor: staticYaoColor ?? this.staticYaoColor,
      dongYaoColor: dongYaoColor ?? this.dongYaoColor,
      yaoFontSize: yaoFontSize ?? this.yaoFontSize,
      chongLineColor: chongLineColor ?? this.chongLineColor,
      heLineColor: heLineColor ?? this.heLineColor,
      shengLineColor: shengLineColor ?? this.shengLineColor,
      keLineColor: keLineColor ?? this.keLineColor,
      showColoredWuXing: showColoredWuXing ?? this.showColoredWuXing,
    );
  }
}
