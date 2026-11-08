/// 数据库平台的初始化
///
/// sqflite 官方只实现了 Android/iOS。桌面端要改用 sqflite_common_ffi，
/// 把全局 [databaseFactory] 切换成 FFI 实现（依赖 sqlite3 动态库）。
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _inited = false;

/// 在 main() 里尽早调用一次
void initDatabaseFactory() {
  if (_inited) return;
  _inited = true;
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
