/// 起卦记录完整数据模型
library;

import 'dart:convert';
import 'gua_info.dart';
import 'shensha_result.dart';
import 'yao_line.dart';

/// 起卦记录类
class DivinationRecord {
  /// 记录ID（数据库主键）
  final int? id;

  /// 创建时间
  final DateTime createdAt;

  /// 起卦时间
  final DateTime divTime;

  /// 所问问题
  final String question;

  /// 起卦方式
  final String startMethod;

  /// 起卦人姓名
  final String querentName;

  /// 起卦人性别
  final String querentGender;

  /// 农历年
  final String? lunarYear;

  /// 农历月
  final String? lunarMonth;

  /// 农历日
  final String? lunarDay;

  /// 年柱干支
  final String yearGz;

  /// 月柱干支
  final String monthGz;

  /// 日柱干支
  final String dayGz;

  /// 时柱干支
  final String hourGz;

  /// 旬空地支
  final String xunKong;

  /// 本卦信息
  final GuaInfo benGua;

  /// 变卦信息（有动爻才有）
  final GuaInfo? bianGua;

  /// 互卦信息
  final GuaInfo? huGua;

  /// 六次背面数
  final List<int> backCounts;

  /// 六爻详情
  final List<YaoLine> yaoLines;

  /// 神煞结果
  final ShenshaResult shensha;

  /// 解卦内容
  final String? interpretation;

  /// 标签（备用）
  final List<String>? tags;

  DivinationRecord({
    this.id,
    required this.createdAt,
    required this.divTime,
    required this.question,
    required this.startMethod,
    this.querentName = '',
    this.querentGender = '',
    this.lunarYear,
    this.lunarMonth,
    this.lunarDay,
    required this.yearGz,
    required this.monthGz,
    required this.dayGz,
    required this.hourGz,
    required this.xunKong,
    required this.benGua,
    this.bianGua,
    this.huGua,
    required this.backCounts,
    required this.yaoLines,
    required this.shensha,
    this.interpretation,
    this.tags,
  });

  /// 是否有动爻
  bool hasDongYao() {
    return yaoLines.any((yao) => yao.isDong);
  }

  /// 获取动爻列表
  List<YaoLine> getDongYaoList() {
    return yaoLines.where((yao) => yao.isDong).toList();
  }

  /// 动爻数量
  int get dongYaoCount => getDongYaoList().length;

  /// 获取世爻
  YaoLine? getShiYao() {
    return yaoLines.where((yao) => yao.isShi == true).firstOrNull;
  }

  /// 获取应爻
  YaoLine? getYingYao() {
    return yaoLines.where((yao) => yao.isYing == true).firstOrNull;
  }

  /// 获取旬空爻列表
  List<YaoLine> getXunKongYaoList() {
    return yaoLines.where((yao) => yao.isXunKong == true).toList();
  }

  /// 获取伏神爻列表
  List<YaoLine> getFuShenYaoList() {
    return yaoLines.where((yao) => yao.fuShen != null && yao.fuShen!.isNotEmpty).toList();
  }

  /// 格式化时间显示
  String get formattedDivTime {
    return '${divTime.year}年${divTime.month}月${divTime.day}日 '
        '${divTime.hour}:${divTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化创建时间（记录添加时间，精确到分钟）
  String get formattedCreatedAt {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化干支显示
  String get formattedGanZhi {
    return '$yearGz年 $monthGz月 $dayGz日 $hourGz时';
  }

  /// 复制并更新部分属性
  DivinationRecord copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? divTime,
    String? question,
    String? startMethod,
    String? querentName,
    String? querentGender,
    String? lunarYear,
    String? lunarMonth,
    String? lunarDay,
    String? yearGz,
    String? monthGz,
    String? dayGz,
    String? hourGz,
    String? xunKong,
    GuaInfo? benGua,
    GuaInfo? bianGua,
    GuaInfo? huGua,
    List<int>? backCounts,
    List<YaoLine>? yaoLines,
    ShenshaResult? shensha,
    String? interpretation,
    List<String>? tags,
  }) {
    return DivinationRecord(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      divTime: divTime ?? this.divTime,
      question: question ?? this.question,
      startMethod: startMethod ?? this.startMethod,
      querentName: querentName ?? this.querentName,
      querentGender: querentGender ?? this.querentGender,
      lunarYear: lunarYear ?? this.lunarYear,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      lunarDay: lunarDay ?? this.lunarDay,
      yearGz: yearGz ?? this.yearGz,
      monthGz: monthGz ?? this.monthGz,
      dayGz: dayGz ?? this.dayGz,
      hourGz: hourGz ?? this.hourGz,
      xunKong: xunKong ?? this.xunKong,
      benGua: benGua ?? this.benGua,
      bianGua: bianGua ?? this.bianGua,
      huGua: huGua ?? this.huGua,
      backCounts: backCounts ?? this.backCounts,
      yaoLines: yaoLines ?? this.yaoLines,
      shensha: shensha ?? this.shensha,
      interpretation: interpretation ?? this.interpretation,
      tags: tags ?? this.tags,
    );
  }

  /// 转换为 JSON Map（用于数据库存储，使用驼峰命名）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'divTime': divTime.toIso8601String(),
      'question': question,
      'startMethod': startMethod,
      'querentName': querentName,
      'querentGender': querentGender,
      'lunarYear': lunarYear,
      'lunarMonth': lunarMonth,
      'lunarDay': lunarDay,
      'yearGz': yearGz,
      'monthGz': monthGz,
      'dayGz': dayGz,
      'hourGz': hourGz,
      'xunKong': xunKong,
      'benGua': jsonEncode(benGua.toJson()),
      'bianGua': bianGua != null ? jsonEncode(bianGua!.toJson()) : null,
      'huGua': huGua != null ? jsonEncode(huGua!.toJson()) : null,
      'backCounts': jsonEncode(backCounts),
      'yaoLines': jsonEncode(yaoLines.map((y) => y.toJson()).toList()),
      'shensha': jsonEncode(shensha.toJson()),
      'interpretation': interpretation,
      'tags': tags != null ? jsonEncode(tags) : null,
    };
  }

  /// 从 JSON Map 创建（从数据库读取，使用驼峰命名）
  factory DivinationRecord.fromJson(Map<String, dynamic> json) {
    return DivinationRecord(
      id: json['id'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      divTime: DateTime.parse(json['divTime'] as String),
      question: json['question'] as String,
      startMethod: json['startMethod'] as String,
      querentName: json['querentName'] as String? ?? '',
      querentGender: json['querentGender'] as String? ?? '',
      lunarYear: json['lunarYear'] as String?,
      lunarMonth: json['lunarMonth'] as String?,
      lunarDay: json['lunarDay'] as String?,
      yearGz: json['yearGz'] as String,
      monthGz: json['monthGz'] as String,
      dayGz: json['dayGz'] as String,
      hourGz: json['hourGz'] as String,
      xunKong: json['xunKong'] as String,
      benGua: GuaInfo.fromJson(jsonDecode(json['benGua'] as String) as Map<String, dynamic>),
      bianGua: json['bianGua'] != null
          ? GuaInfo.fromJson(jsonDecode(json['bianGua'] as String) as Map<String, dynamic>)
          : null,
      huGua: json['huGua'] != null
          ? GuaInfo.fromJson(jsonDecode(json['huGua'] as String) as Map<String, dynamic>)
          : null,
      backCounts: (jsonDecode(json['backCounts'] as String) as List).cast<int>(),
      yaoLines: (jsonDecode(json['yaoLines'] as String) as List)
          .map((y) => YaoLine.fromJson(y as Map<String, dynamic>))
          .toList(),
      shensha: ShenshaResult.fromJson(jsonDecode(json['shensha'] as String) as Map<String, dynamic>),
      interpretation: json['interpretation'] as String?,
      tags: json['tags'] != null ? (jsonDecode(json['tags'] as String) as List).cast<String>() : null,
    );
  }

  @override
  String toString() {
    return 'DivinationRecord($benGua.guaName, $formattedGanZhi, ${dongYaoCount}动)';
  }
}