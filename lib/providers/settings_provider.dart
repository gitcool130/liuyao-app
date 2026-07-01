/// 设置状态提供者
library;

import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  /// 初始化加载
  Future<void> load() async {
    _settings = await AppSettings.load();
    _loaded = true;
    notifyListeners();
  }

  /// 更新设置
  void update(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }
}
