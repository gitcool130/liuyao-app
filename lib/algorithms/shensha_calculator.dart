/// 神煞计算器
/// 根据干支计算天乙贵人、驿马、华盖、咸池、天医、禄神、文昌、将星、羊刃、红鸾、天喜、劫煞
library;

import '../models/shensha_result.dart';
import 'constants.dart';

/// 神煞计算器
class ShenShaCalculator {
  /// 计算神煞（16项）
  static ShenshaResult calculate({
    required String dayGan,
    required String dayZhi,
    required String yearZhi,
    required String monthZhi,
  }) {
    return ShenshaResult(
      tianYi: getTianYiGuiRen(dayGan),
      yiMa: getYiMa(dayZhi),
      huaGai: getHuaGai(yearZhi),
      xianChi: getXianChi(dayZhi),
      tianYiShen: getTianYiShen(monthZhi),
      luShen: getLuShen(dayGan),
      wenChang: getWenChang(dayGan),
      jiangXing: getJiangXing(dayZhi),
      yangRen: getYangRen(dayGan),
      hongLuan: getHongLuan(dayZhi),
      tianXi: getTianXi(dayZhi),
      jieSha: getJieSha(dayZhi),
      zaiSha: getZaiSha(yearZhi),
      wangShen: getWangShen(dayZhi),
      guChen: getGuChen(yearZhi),
      guaSu: getGuaSu(yearZhi),
    );
  }

  /// 天乙贵人（按日干）
  static String getTianYiGuiRen(String dayGan) => tianYiGuiRen[dayGan] ?? '';

  /// 禄神（按日干）
  static String getLuShen(String dayGan) => luShen[dayGan] ?? '';

  /// 驿马（按日支）
  static String getYiMa(String dayZhi) => yiMa[dayZhi] ?? '';

  /// 华盖（按年支）
  static String getHuaGai(String yearZhi) => huaGai[yearZhi] ?? '';

  /// 咸池/桃花（按日支）
  static String getXianChi(String dayZhi) => xianChi[dayZhi] ?? '';

  /// 天医（按月支）
  static String getTianYiShen(String monthZhi) => tianYiShen[monthZhi] ?? '';

  // === 新增神煞 (2026-06-26) ===

  /// 文昌（按日干）
  static String getWenChang(String dayGan) => wenChang[dayGan] ?? '';

  /// 将星（按日支，三合局中位）
  static String getJiangXing(String dayZhi) => jiangXing[dayZhi] ?? '';

  /// 羊刃（按日干，禄前一位）
  static String getYangRen(String dayGan) => yangRen[dayGan] ?? '';

  /// 红鸾（按日支，卯起逆排）
  static String getHongLuan(String dayZhi) => hongLuan[dayZhi] ?? '';

  /// 天喜（按日支，红鸾对冲位 +6）
  static String getTianXi(String dayZhi) => tianXi[dayZhi] ?? '';

  /// 劫煞（按日支，三合局绝地）
  static String getJieSha(String dayZhi) => jieSha[dayZhi] ?? '';

  /// 神煞含义说明
  static String getShenShaExplanation(String shenShaName) {
    const Map<String, String> explanations = {
      '天乙贵人': '最吉之神，主贵人相助，遇难呈祥',
      '驿马': '主奔波、出行、变动、迁移',
      '华盖': '主艺术、才华、孤独、清高',
      '咸池': '又称桃花，主感情、异性、魅力',
      '天医': '主健康、医疗、贵人相助',
      '禄神': '主财富、地位、俸禄',
      '文昌': '主学业、文书、考试、文采',
      '将星': '主权柄、领导力、才能',
      '羊刃': '主刚强、果断，过则血光',
      '红鸾': '主婚恋、喜庆、姻缘',
      '天喜': '主喜庆、添丁、好事临近',
      '劫煞': '主劫难、破财、小人',
    };
    return explanations[shenShaName] ?? '';
  }

  // === 新增神煞 (2026-07-01) ===

  /// 灾煞（按年支，三合局对冲位）
  static String getZaiSha(String yearZhi) => zaiSha[yearZhi] ?? '';

  /// 亡神（按日支，三合局寅申巳亥）
  static String getWangShen(String dayZhi) => wangShen[dayZhi] ?? '';

  /// 孤辰（按年支）
  static String getGuChen(String yearZhi) => guChen[yearZhi] ?? '';

  /// 寡宿（按年支）
  static String getGuaSu(String yearZhi) => guaSu[yearZhi] ?? '';

  /// 获取三合局
  static String getSanHeJu(String zhi) {
    if (['申', '子', '辰'].contains(zhi)) return '水局';
    if (['寅', '午', '戌'].contains(zhi)) return '火局';
    if (['巳', '酉', '丑'].contains(zhi)) return '金局';
    if (['亥', '卯', '未'].contains(zhi)) return '木局';
    return '';
  }
}
