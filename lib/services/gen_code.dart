/// 管理员验证码生成工具
/// 使用方式：
///   dart run lib/services/gen_code.dart <设备ID> <功能代码> [过期日期]
///
/// 示例：
///   dart run lib/services/gen_code.dart abc123 F001 20261231
///
/// 参数说明：
///   设备ID     - 用户提供的设备标识
///   功能代码   - F001~F005（见 lockedFeatures 列表）
///   过期日期   - 可选，默认一年后，格式 YYYYMMDD
import 'feature_lock_service.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('用法: dart run lib/services/gen_code.dart <设备ID> <功能代码> [过期日期]');
    print('');
    print('功能代码列表:');
    for (final feature in lockedFeatures) {
      print('  ${feature.code} - ${feature.name}: ${feature.description}');
    }
    print('');
    print('过期日期格式: YYYYMMDD（可选，默认一年后）');
    return;
  }

  final deviceId = args[0];
  final featureCode = args[1].toUpperCase();
  final expireDate = args.length >= 3 ? args[2] : _defaultExpireDate();

  // 验证功能代码
  final feature = lockedFeatures.where((f) => f.code == featureCode).toList();
  if (feature.isEmpty) {
    print('错误: 无效的功能代码 "$featureCode"');
    return;
  }

  // 验证日期格式
  if (expireDate.length != 8 || int.tryParse(expireDate) == null) {
    print('错误: 日期格式不正确，应为 YYYYMMDD');
    return;
  }

  final code = FeatureLockService.generateCode(
    deviceId: deviceId,
    featureCode: featureCode,
    expireDate: expireDate,
  );

  print('');
  print('═══════════════════════════════════════');
  print('  设备ID:     $deviceId');
  print('  功能:       ${feature.first.code} - ${feature.first.name}');
  print('  过期日期:   $expireDate');
  print('  验证码:     $code');
  print('═══════════════════════════════════════');
  print('');
  print('将此验证码提供给用户即可解锁功能。');
}

String _defaultExpireDate() {
  final now = DateTime.now();
  final nextYear = DateTime(now.year + 1, now.month, now.day);
  return '${nextYear.year}${nextYear.month.toString().padLeft(2, '0')}${nextYear.day.toString().padLeft(2, '0')}';
}
