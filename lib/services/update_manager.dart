/// 更新管理器
/// 后台下载APK + 断点续传 + 安装包校验 + 待安装状态持久化
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feature_lock_service.dart';

/// 下载状态
enum DownloadStatus { none, downloading, paused, pendingInstall, installed }

/// 更新信息
class UpdateInfo {
  final String version;
  final int buildNumber;
  final String description;
  final int apkSize;
  final String url;
  final String md5;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.description,
    required this.apkSize,
    required this.url,
    this.md5 = '',
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
    version: json['version'] as String,
    buildNumber: json['buildNumber'] as int,
    description: json['description'] as String? ?? '',
    apkSize: json['apkSize'] as int? ?? 0,
    url: json['url'] as String? ?? '/apk/liuyao-assistant.apk',
    md5: json['md5'] as String? ?? '',
  );
}

/// 更新管理器
class UpdateManager {
  static const _prefsKey = 'update_status';
  static const _apkKey = 'update_apk_path';
  static const _buildKey = 'update_target_build';

  static DownloadStatus _status = DownloadStatus.none;
  static double _progress = 0;
  static String? _cachedApkPath;
  static int _targetBuild = 0;

  /// 当前下载状态
  static DownloadStatus get status => _status;
  static double get progress => _progress;

  /// 检查服务器更新
  static Future<UpdateInfo?> checkUpdate(int currentBuild) async {
    final info = await FeatureLockService.checkUpdate();
    if (info == null) return null;
    final serverBuild = info['buildNumber'] as int? ?? 0;
    if (serverBuild <= currentBuild) return null;
    return UpdateInfo.fromJson(info);
  }

  /// 检查是否有待安装的安装包
  static Future<bool> hasPendingInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final apkPath = prefs.getString(_apkKey);
    if (apkPath == null || apkPath.isEmpty) return false;
    final file = File(apkPath);
    if (!file.existsSync()) {
      await prefs.remove(_apkKey);
      await prefs.remove(_buildKey);
      return false;
    }
    _cachedApkPath = apkPath;
    _targetBuild = prefs.getInt(_buildKey) ?? 0;
    _status = DownloadStatus.pendingInstall;
    return true;
  }

  /// 开始后台下载（带MD5校验）
  static Future<bool> startDownload(UpdateInfo info) async {
    _status = DownloadStatus.downloading;
    _progress = 0;

    final url = '${FeatureLockService.serverUrl}${info.url}';
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/liuyao-assistant.apk');

    // 检查已有文件是否对应同一个版本，防止服务器升级后断点续传损坏文件
    final prefs = await SharedPreferences.getInstance();
    final savedBuild = prefs.getInt(_buildKey) ?? 0;
    if (savedBuild > 0 && savedBuild != info.buildNumber) {
      // 服务器已升级，删除旧的部分文件
      if (file.existsSync()) await file.delete();
      await prefs.remove(_apkKey);
      await prefs.remove(_buildKey);
    }

    try {
      final existingBytes = file.existsSync() ? await file.length() : 0;
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      // 有续传时先校验已有部分是否完整（查服务端APK大小）
      if (existingBytes > 0) {
        if (existingBytes >= info.apkSize) {
          // 已有文件大小 ≥ 预期大小，直接校验MD5
          return await _verifyAndSave(file.path, info);
        }
        // 否则发起续传请求
      }

      final request = await client.getUrl(Uri.parse(url));
      if (existingBytes > 0) {
        request.headers.set('Range', 'bytes=$existingBytes-');
      }

      final response = await request.close();

      // 处理续传响应：206=续传成功，200=服务器不支持续传（重新下载）
      if (response.statusCode == 206) {
        // 续传模式，追加写入
        final sink = file.openWrite(mode: FileMode.append);
        await response.pipe(sink);
        return await _verifyAndSave(file.path, info);
      } else if (response.statusCode == 200) {
        // 服务器不支持续传或range无效，重新下载
        if (existingBytes > 0) {
          // 删除不完整的文件，重新下载
          await file.delete();
        }
        final sink = file.openWrite(mode: FileMode.write);
        await response.pipe(sink);
        return await _verifyAndSave(file.path, info);
      } else if (response.statusCode == 416) {
        // Range超出范围，文件已完整
        return await _verifyAndSave(file.path, info);
      }
    } catch (_) {
      _status = DownloadStatus.none;
    }
    return false;
  }

  /// 校验APK完整性并保存状态
  static Future<bool> _verifyAndSave(String filePath, UpdateInfo info) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final expectedSize = info.apkSize;

    // 大小校验
    if (fileSize != expectedSize) {
      await file.delete();
      _status = DownloadStatus.none;
      return false;
    }

    // MD5校验（如果服务器提供了md5）
    if (info.md5.isNotEmpty) {
      try {
        final bytes = await file.readAsBytes();
        final digest = _md5Hash(bytes);
        if (digest != info.md5) {
          await file.delete();
          _status = DownloadStatus.none;
          return false;
        }
      } catch (_) {
        await file.delete();
        return false;
      }
    }

    // 保存待安装状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apkKey, file.path);
    await prefs.setInt(_buildKey, info.buildNumber);
    _cachedApkPath = file.path;
    _targetBuild = info.buildNumber;
    _status = DownloadStatus.pendingInstall;
    _progress = 1.0;
    return true;
  }

  /// MD5哈希
  static String _md5Hash(List<int> data) => md5.convert(data).toString();

  static const _installChannel = MethodChannel('com.bobo.liuyao_app/install');

  /// 触发安装
  static Future<String?> install() async {
    if (_cachedApkPath == null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedApkPath = prefs.getString(_apkKey);
    }
    if (_cachedApkPath == null) return '未找到安装包';

    final file = File(_cachedApkPath!);
    if (!file.existsSync()) return '安装包文件不存在';

    try {
      final success = await _installChannel.invokeMethod<bool>('installApk', {'path': _cachedApkPath});
      if (success == true) {
        _status = DownloadStatus.installed;
        return null;
      }
      return '启动安装程序失败，请在文件管理器中手动安装';
    } catch (e) {
      return '安装失败：$e';
    }
  }

  /// 安装完成后清理
  static Future<void> cleanUp() async {
    if (_cachedApkPath != null) {
      try { await File(_cachedApkPath!).delete(); } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apkKey);
    await prefs.remove(_buildKey);
    _cachedApkPath = null;
    _targetBuild = 0;
    _status = DownloadStatus.none;
    _progress = 0;
  }
}
