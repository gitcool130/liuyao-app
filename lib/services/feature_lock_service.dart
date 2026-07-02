/// 功能锁服务
/// 纯服务器验证模式：App不存储密钥，全部通过服务器API验证
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 功能定义
class LockedFeature {
  final String code;
  final String name;
  final String description;

  const LockedFeature({
    required this.code,
    required this.name,
    required this.description,
  });
}

/// 所有可锁定的功能列表
const List<LockedFeature> lockedFeatures = [
  LockedFeature(code: 'F005', name: '神煞详解', description: '神煞含义详解与吉凶分析'),
  LockedFeature(code: 'F006', name: '易青岚高级课笔记', description: '45课时六爻进阶课程笔记'),
  LockedFeature(code: 'F007', name: '易青岚论坛', description: '访问易青岚六爻学习社区'),
];

/// 功能锁服务（纯服务器验证）
class FeatureLockService {
  /// 服务器地址
  static String serverUrl = 'http://182.92.214.89:3456';

  /// SharedPreferences 键名
  static const String _prefsPrefix = 'unlocked_features_';

  /// 在线验证验证码（唯一验证方式，本地不存储密钥）
  static Future<({bool valid, String expireDate})> verifyCode({
    required String deviceId,
    required String code,
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(Uri.parse('$serverUrl/api/verify_code'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'deviceId': deviceId, 'code': code}));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final jsonData = jsonDecode(body) as Map<String, dynamic>;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'] as Map<String, dynamic>;
          if (data['valid'] == true) {
            return (valid: true, expireDate: data['expireDate'] as String);
          }
        }
      }
    } catch (_) {}
    return (valid: false, expireDate: '');
  }

  /// 获取设备ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('_device_id');
    if (deviceId == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(8, (_) => random.nextInt(256));
      deviceId = base64Url.encode(bytes);
      await prefs.setString('_device_id', deviceId);
    }
    return deviceId;
  }

  /// 检查功能是否已解锁
  static Future<bool> isUnlocked(String featureCode) async {
    final prefs = await SharedPreferences.getInstance();
    final expireDate = prefs.getString('$_prefsPrefix$featureCode');
    if (expireDate == null || expireDate.isEmpty) return false;

    if (expireDate.length == 8) {
      final year = int.tryParse(expireDate.substring(0, 4)) ?? 0;
      final month = int.tryParse(expireDate.substring(4, 6)) ?? 0;
      final day = int.tryParse(expireDate.substring(6, 8)) ?? 0;
      final expireDt = DateTime(year, month, day + 1);
      if (DateTime.now().isAfter(expireDt)) return false;
    }
    return true;
  }

  /// 解锁功能（保存到本地）
  static Future<void> unlock(String featureCode, String expireDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix$featureCode', expireDate);
  }

  /// 获取所有已解锁的功能
  static Future<List<String>> getUnlockedFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = <String>[];
    for (final feature in lockedFeatures) {
      final expireDate = prefs.getString('$_prefsPrefix${feature.code}');
      if (expireDate != null && expireDate.isNotEmpty) {
        if (expireDate.length == 8) {
          final year = int.tryParse(expireDate.substring(0, 4)) ?? 0;
          final month = int.tryParse(expireDate.substring(4, 6)) ?? 0;
          final day = int.tryParse(expireDate.substring(6, 8)) ?? 0;
          final expireDt = DateTime(year, month, day + 1);
          if (DateTime.now().isAfter(expireDt)) continue;
        }
        unlocked.add(feature.code);
      }
    }
    return unlocked;
  }

  /// 检查更新
  static Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse('$serverUrl/api/check_update'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final jsonData = jsonDecode(body) as Map<String, dynamic>;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return jsonData['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }
}
