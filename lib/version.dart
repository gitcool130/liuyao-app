/// 应用版本号
/// 更新时同步修改 pubspec.yaml 中的 version
///
/// 注意：Flutter 3.35+ 的 `package:flutter/services.dart` 已自带同名常量
/// `appVersion` / `appBuildNumber`，本项目沿用同名会报「imported from both」，
/// 因此统一加 k 前缀，避开与框架的命名冲突。
const String kAppVersion = '1.2.4';
const int kAppBuildNumber = 87;
