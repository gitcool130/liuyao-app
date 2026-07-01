/// 图像识别结果模型
/// 用于存储排盘图片识别后的解析数据

import 'divination_record.dart';
import 'yao_line.dart';
import 'gua_info.dart';
import 'shensha_result.dart';

/// 图像识别结果
class ImageRecognitionResult {
  /// 是否识别成功
  final bool success;

  /// 错误信息（识别失败时）
  final String? errorMessage;

  /// 识别到的原始文本（用于调试）
  final String? rawText;

  /// 解析后的排盘数据
  final ParsedDivinationData? data;

  /// 置信度（0-1）
  final double confidence;

  /// 需要人工确认的字段列表
  final List<String>? needsConfirmation;

  ImageRecognitionResult({
    required this.success,
    this.errorMessage,
    this.rawText,
    this.data,
    this.confidence = 0.0,
    this.needsConfirmation,
  });

  factory ImageRecognitionResult.success({
    required ParsedDivinationData data,
    String? rawText,
    double confidence = 0.0,
    List<String>? needsConfirmation,
  }) {
    return ImageRecognitionResult(
      success: true,
      data: data,
      rawText: rawText,
      confidence: confidence,
      needsConfirmation: needsConfirmation,
    );
  }

  factory ImageRecognitionResult.failure(String errorMessage) {
    return ImageRecognitionResult(
      success: false,
      errorMessage: errorMessage,
      confidence: 0.0,
    );
  }
}

/// 解析后的排盘数据
class ParsedDivinationData {
  /// 性别
  final String? gender;

  /// 占问内容
  final String? question;

  /// 公历时间
  final DateTime? gregorianTime;

  /// 农历时间字符串
  final String? lunarTime;

  /// 年柱干支
  final String? yearGanZhi;

  /// 月柱干支
  final String? monthGanZhi;

  /// 日柱干支
  final String? dayGanZhi;

  /// 时柱干支
  final String? hourGanZhi;

  /// 本卦名称
  final String? benGuaName;

  /// 变卦名称（可选）
  final String? bianGuaName;

  /// 六神列表（从下往上：初爻到上爻）
  final List<String>? liuShen;

  /// 六亲列表（从下往上）
  final List<String>? liuQin;

  /// 地支列表（从下往上）
  final List<String>? diZhi;

  /// 旬空地支
  final List<String>? xunKong;

  /// 世爻位置（1-6）
  final int? shiPosition;

  /// 应爻位置（1-6）
  final int? yingPosition;

  /// 动爻位置列表（1-6）
  final List<int>? dongYaoPositions;

  /// 神煞信息
  final Map<String, List<String>>? shenSha;

  ParsedDivinationData({
    this.gender,
    this.question,
    this.gregorianTime,
    this.lunarTime,
    this.yearGanZhi,
    this.monthGanZhi,
    this.dayGanZhi,
    this.hourGanZhi,
    this.benGuaName,
    this.bianGuaName,
    this.liuShen,
    this.liuQin,
    this.diZhi,
    this.xunKong,
    this.shiPosition,
    this.yingPosition,
    this.dongYaoPositions,
    this.shenSha,
  });

  /// 转换为 DivinationRecord（用于保存到数据库）
  /// 注意：需要结合 algorithms 中的排盘算法生成完整的 YaoLine 列表
  DivinationRecord? toDivinationRecord({
    required List<int> backCounts,
    required GuaInfo benGua,
    GuaInfo? bianGua,
    required List<YaoLine> yaoLines,
    required ShenshaResult shensha,
  }) {
    // 验证必要字段
    if (dayGanZhi == null || benGuaName == null) {
      return null;
    }

    // OCR识别的排盘没有起卦人信息，用识别的日期和时间填入
    final String ocrQuerentName;
    if (gregorianTime != null) {
      final gt = gregorianTime!;
      ocrQuerentName = 'OCR导入 ${gt.month}月${gt.day}日 '
          '${gt.hour.toString().padLeft(2, '0')}:${gt.minute.toString().padLeft(2, '0')}';
    } else {
      ocrQuerentName = 'OCR导入';
    }

    return DivinationRecord(
      createdAt: DateTime.now(),
      divTime: gregorianTime ?? DateTime.now(),
      question: question ?? '',
      startMethod: 'image_import', // 图像导入
      querentName: ocrQuerentName,
      querentGender: gender ?? '',
      lunarYear: lunarTime,
      yearGz: yearGanZhi ?? '',
      monthGz: monthGanZhi ?? '',
      dayGz: dayGanZhi ?? '',
      hourGz: hourGanZhi ?? '',
      xunKong: xunKong?.join('') ?? '',
      benGua: benGua,
      bianGua: bianGua,
      backCounts: backCounts,
      yaoLines: yaoLines,
      shensha: shensha,
    );
  }

  /// 检查哪些字段缺失
  List<String> getMissingFields() {
    final missing = <String>[];
    if (gender == null) missing.add('性别');
    if (gregorianTime == null && lunarTime == null) missing.add('时间');
    if (dayGanZhi == null) missing.add('日柱');
    if (benGuaName == null) missing.add('本卦');
    if (liuShen == null || liuShen!.length != 6) missing.add('六神');
    if (liuQin == null || liuQin!.length != 6) missing.add('六亲');
    if (diZhi == null || diZhi!.length != 6) missing.add('地支');
    return missing;
  }

  /// 获取世爻名称
  String? getShiYaoName() {
    if (shiPosition == null || shiPosition! < 1 || shiPosition! > 6) return null;
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return names[shiPosition! - 1];
  }

  /// 获取应爻名称
  String? getYingYaoName() {
    if (yingPosition == null || yingPosition! < 1 || yingPosition! > 6) return null;
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return names[yingPosition! - 1];
  }

  /// 获取动爻名称列表
  List<String> getDongYaoNames() {
    if (dongYaoPositions == null || dongYaoPositions!.isEmpty) return [];
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return dongYaoPositions!
        .where((p) => p >= 1 && p <= 6)
        .map((p) => names[p - 1])
        .toList();
  }
}
