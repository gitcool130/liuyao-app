/// 神煞计算器
/// 根据干支计算贵人、驿马、华盖、桃花、天医、禄神、文昌、将星、羊刃、天喜、劫煞、灾煞、谋星
library;

import '../models/shensha_result.dart';
import 'constants.dart';

/// 神煞计算器
class ShenShaCalculator {
  /// 计算神煞（13项）
  static ShenshaResult calculate({
    required String dayGan,
    required String dayZhi,
    required String yearZhi,
    required String monthZhi,
  }) {
    return ShenshaResult(
      tianYi: getTianYiGuiRen(dayGan),
      yiMa: getYiMa(dayZhi),
      huaGai: getHuaGai(dayZhi),
      xianChi: getXianChi(dayZhi),
      tianYiShen: getTianYiShen(monthZhi),
      luShen: getLuShen(dayGan),
      wenChang: getWenChang(dayGan),
      jiangXing: getJiangXing(dayZhi),
      yangRen: getYangRen(dayGan),
      tianXi: getTianXi(monthZhi),
      jieSha: getJieSha(dayZhi),
      zaiSha: getZaiSha(dayZhi),
      mouXing: getMouXing(dayZhi),
    );
  }

  /// 天乙贵人（按日干）
  static String getTianYiGuiRen(String dayGan) => tianYiGuiRen[dayGan] ?? '';

  /// 禄神（按日干）
  static String getLuShen(String dayGan) => luShen[dayGan] ?? '';

  /// 驿马（按日支）
  static String getYiMa(String dayZhi) => yiMa[dayZhi] ?? '';

  /// 华盖（按日支）
  static String getHuaGai(String yearZhi) => huaGai[yearZhi] ?? '';

  /// 桃花/咸池（按日支）
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

  /// 天喜（按月支/季节查）
  static String getTianXi(String monthZhi) => tianXi[monthZhi] ?? '';

  /// 劫煞（按日支，三合局绝地）
  static String getJieSha(String dayZhi) => jieSha[dayZhi] ?? '';

  /// 神煞含义说明
  static String getShenShaExplanation(String shenShaName) {
    const Map<String, String> explanations = {
      '贵人': '最吉之神，主贵人相助，遇难呈祥',
      '驿马': '主奔波、出行、变动、迁移',
      '华盖': '主艺术、才华、孤独、清高',
      '桃花': '又称咸池，主感情、异性、魅力',
      '天医': '主健康、医疗、贵人相助',
      '禄神': '主财富、地位、俸禄',
      '文昌': '主学业、文书、考试、文采',
      '将星': '主权柄、领导力、才能',
      '羊刃': '主刚强、果断，过则血光',
      '天喜': '主喜庆、添丁、好事临近',
      '劫煞': '主劫难、破财、小人',
    };
    return explanations[shenShaName] ?? '';
  }

  /// 灾煞（按日支，三合局对冲位）
  static String getZaiSha(String yearZhi) => zaiSha[yearZhi] ?? '';

  /// 谋星（按日支）
  static String getMouXing(String dayZhi) => mouXing[dayZhi] ?? '';

  /// 获取三合局
  static String getSanHeJu(String zhi) {
    if (['申', '子', '辰'].contains(zhi)) return '水局';
    if (['寅', '午', '戌'].contains(zhi)) return '火局';
    if (['巳', '酉', '丑'].contains(zhi)) return '金局';
    if (['亥', '卯', '未'].contains(zhi)) return '木局';
    return '';
  }
}
