/// 管理员验证码生成工具（纯 Dart，不依赖 Flutter）
/// 使用方式：
///   dart run lib/services/gen_code_cli.dart <设备ID> <功能代码> [过期日期]
///
/// 示例：
///   dart run lib/services/gen_code_cli.dart dWkaD8lQIN8= F006 20261231
library;

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

const String _secretKey = 'LiuYaoApp_Unlock_Key_2026';

const List<Map<String, String>> _features = [
  {'code': 'F005', 'name': '神煞详解', 'desc': '神煞含义详解与吉凶分析'},
  {'code': 'F006', 'name': '易青岚高级课笔记', 'desc': '45课时六爻进阶课程笔记'},
];

String generateCode(String deviceId, String featureCode, String expireDate) {
  final data = utf8.encode('$deviceId|$featureCode|$expireDate');
  final key = utf8.encode(_secretKey);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(data);
  return digest.toString().substring(0, 8).toUpperCase();
}

String _defaultExpireDate() {
  final now = DateTime.now();
  final nextYear = DateTime(now.year + 1, now.month, now.day);
  return '${nextYear.year}${nextYear.month.toString().padLeft(2, '0')}${nextYear.day.toString().padLeft(2, '0')}';
}

void main(List<String> args) {
  if (args.length < 2) {
    print('用法: dart run lib/services/gen_code_cli.dart <设备ID> <功能代码> [过期日期]');
    print('');
    print('功能代码列表:');
    for (final f in _features) {
      print('  ${f['code']} - ${f['name']}: ${f['desc']}');
    }
    print('');
    print('过期日期格式: YYYYMMDD（可选，默认一年后）');
    exit(1);
  }

  final deviceId = args[0];
  final featureCode = args[1].toUpperCase();

  final feature = _features.where((f) => f['code'] == featureCode).toList();
  if (feature.isEmpty) {
    print('错误: 无效的功能代码 "$featureCode"');
    exit(1);
  }

  final expireDate = args.length >= 3 ? args[2] : _defaultExpireDate();

  if (expireDate.length != 8 || int.tryParse(expireDate) == null) {
    print('错误: 日期格式不正确，应为 YYYYMMDD');
    exit(1);
  }

  final code = generateCode(deviceId, featureCode, expireDate);

  print('');
  print('═══════════════════════════════════════');
  print('  设备ID:     $deviceId');
  print('  功能:       ${feature.first['code']} - ${feature.first['name']}');
  print('  过期日期:   $expireDate');
  print('  验证码:     $code');
  print('═══════════════════════════════════════');
  print('');
  print('将此验证码提供给用户即可解锁功能。');
}
