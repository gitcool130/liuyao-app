/// 功能锁服务
/// 基于HMAC验证码的离线解锁机制
///
/// ## 验证码算法
/// 验证码 = base32(HMAC-SHA256(secret, deviceId + featureCode + expireDate)).substring(0, 8)
///
/// ## 管理员生成验证码
/// ```dart
/// String code = FeatureLockService.generateCode(
///   deviceId: '设备的唯一标识',
///   featureCode: 'F001',
///   expireDate: '20261231',
/// );
/// ```
///
/// ## 用户输入验证码
/// - App端用相同算法验证
/// - 验证通过后，功能标记存入 SharedPreferences
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 功能定义
class LockedFeature {
  final String code;       // 功能代码，如 'F001'
  final String name;       // 显示名称
  final String description; // 功能描述

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

/// 功能锁服务
class FeatureLockService {
  static String get _secretKey {
    const p1 = 'LiuYao';
    const p2 = 'App_U';
    const p3 = 'nlock';
    const p4 = '_Key_2';
    const p5 = '026';
    return '$p1$p2$p3$p4$p5';
  }

  /// SharedPreferences 键名
  static const String _prefsPrefix = 'unlocked_features_';

  /// 生成验证码（管理员用）
  /// [deviceId] - 设备唯一标识
  /// [featureCode] - 功能代码（如F001）
  /// [expireDate] - 过期日期（如20261231）
  static String generateCode({
    required String deviceId,
    required String featureCode,
    required String expireDate,
  }) {
    final data = utf8.encode('$deviceId|$featureCode|$expireDate');
    final key = utf8.encode(_secretKey);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);

    // 取前8位十六进制字符，转换为大写
    return digest.toString().substring(0, 8).toUpperCase();
  }

  /// 验证验证码（App端）
  /// 返回 (是否有效, 过期日期)
  static ({bool valid, String expireDate}) verifyCode({
    required String deviceId,
    required String featureCode,
    required String code,
  }) {
    // 尝试解析验证码中的过期日期
    // 遍历可能的过期日期格式（YYYYMMDD）
    final now = DateTime.now();
    for (int year = now.year; year <= 2099; year++) {
      for (int month = 1; month <= 12; month++) {
        // 计算该月天数
        final daysInMonth = (month == 2)
            ? (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) ? 29 : 28)
            : [1, 3, 5, 7, 8, 10, 12].contains(month) ? 31 : 30;

        for (int day = 1; day <= daysInMonth; day++) {
          final dateStr = '${year}${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}';
          final expected = generateCode(
            deviceId: deviceId,
            featureCode: featureCode,
            expireDate: dateStr,
          );
          if (expected == code) {
            final expireDt = DateTime(year, month, day + 1); // 过期日次日失效
            if (now.isBefore(expireDt)) {
              return (valid: true, expireDate: dateStr);
            }
            return (valid: false, expireDate: dateStr); // 已过期
          }
        }
      }
    }
    return (valid: false, expireDate: '');
  }

  /// 获取设备ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('_device_id');
    if (deviceId == null) {
      // 生成随机设备ID
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

    // 检查是否过期
    if (expireDate.length == 8) {
      final year = int.tryParse(expireDate.substring(0, 4)) ?? 0;
      final month = int.tryParse(expireDate.substring(4, 6)) ?? 0;
      final day = int.tryParse(expireDate.substring(6, 8)) ?? 0;
      final expireDt = DateTime(year, month, day + 1);
      if (DateTime.now().isAfter(expireDt)) {
        return false; // 已过期
      }
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
}
