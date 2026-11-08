/// 平台能力判断
///
/// 本项目的 Android/iOS 专属能力（摇一摇传感、拍照 OCR、内置 WebView）
/// 在桌面端（Windows/Linux/macOS）没有对应插件实现，
/// 统一在这里判断，桌面端改为提示或降级，避免运行时抛 MissingPluginException。
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// 是否桌面端
bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// 是否移动端
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// 不支持的功能提示文案
String desktopUnsupportedHint(String feature) =>
    '桌面版暂不支持「$feature」\n请改用「手动排盘」或「干支排盘」。';
