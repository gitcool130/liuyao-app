/// 单爻数据模型
library;

import '../algorithms/constants.dart';

/// 单爻数据类
class YaoLine {
  /// 爻位 1(初爻)-6(上爻)
  final int position;

  /// 背面数 0-3
  final int backCount;

  /// 爻类型
  final YaoType yaoType;

  /// 是否阳爻
  final bool isYang;

  /// 是否动爻
  final bool isDong;

  /// 纳甲地支
  String? ganZhi;

  /// 纳甲天干
  String? tianGan;

  /// 地支五行
  String? wuXing;

  /// 六亲
  String? liuQin;

  /// 六神
  String? liuShen;

  /// 是否世爻
  bool? isShi;

  /// 是否应爻
  bool? isYing;

  /// 是否旬空
  bool? isXunKong;

  /// 伏神（如有，存储地支如"酉")
  String? fuShen;

  /// 飞神（如有，存储地支）
  String? feiShen;

  /// 变爻类型（动爻才有）
  YaoType? bianYaoType;

  /// 变爻地支（动爻才有）
  String? bianGanZhi;

  /// 变爻天干（动爻才有）
  String? bianTianGan;

  /// 变爻五行（动爻才有）
  String? bianWuXing;

  /// 变爻六亲（动爻才有）
  String? bianLiuQin;

  /// 日月建影响（预留）
  List<String>? riYueEffects;

  /// 与其他爻的关系（预留）
  List<String>? relations;

  YaoLine({
    required this.position,
    required this.backCount,
    required this.yaoType,
    required this.isYang,
    required this.isDong,
    this.ganZhi,
    this.tianGan,
    this.wuXing,
    this.liuQin,
    this.liuShen,
    this.isShi,
    this.isYing,
    this.isXunKong,
    this.fuShen,
    this.feiShen,
    this.bianYaoType,
    this.bianTianGan,
    this.bianGanZhi,
    this.bianWuXing,
    this.bianLiuQin,
    this.riYueEffects,
    this.relations,
  });

  /// 从背面数创建爻
  factory YaoLine.fromBackCount(int position, int backCount) {
    YaoType yaoType;
    bool isYang;
    bool isDong;

    switch (backCount) {
      case 0: // 三个正面 = 0背 = 老阴（动）
        yaoType = YaoType.laoYin;
        isYang = false;
        isDong = true;
        break;
      case 1: // 两正一反 = 1背 = 少阳（静）
        yaoType = YaoType.shaoYang;
        isYang = true;
        isDong = false;
        break;
      case 2: // 一正两反 = 2背 = 少阴（静）
        yaoType = YaoType.shaoYin;
        isYang = false;
        isDong = false;
        break;
      case 3: // 三个反面 = 3背 = 老阳（动）
        yaoType = YaoType.laoYang;
        isYang = true;
        isDong = true;
        break;
      default:
        throw ArgumentError('背面数必须在0-3之间');
    }

    return YaoLine(
      position: position,
      backCount: backCount,
      yaoType: yaoType,
      isYang: isYang,
      isDong: isDong,
    );
  }

  /// 爻位名称（初爻、二爻...上爻）
  String get positionName {
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return names[position - 1];
  }

  /// 爻类型名称
  String get yaoTypeName => yaoTypeNames[yaoType] ?? '';

  /// 爻类型符号
  String get yaoTypeSymbol => yaoTypeSymbols[yaoType] ?? '';

  /// 复制并更新部分属性
  YaoLine copyWith({
    int? position,
    int? backCount,
    YaoType? yaoType,
    bool? isYang,
    bool? isDong,
    String? ganZhi,
    String? tianGan,
    String? wuXing,
    String? liuQin,
    String? liuShen,
    bool? isShi,
    bool? isYing,
    bool? isXunKong,
    String? fuShen,
    String? feiShen,
    YaoType? bianYaoType,
    String? bianTianGan,
    String? bianGanZhi,
    String? bianWuXing,
    String? bianLiuQin,
    List<String>? riYueEffects,
    List<String>? relations,
  }) {
    return YaoLine(
      position: position ?? this.position,
      backCount: backCount ?? this.backCount,
      yaoType: yaoType ?? this.yaoType,
      isYang: isYang ?? this.isYang,
      isDong: isDong ?? this.isDong,
      ganZhi: ganZhi ?? this.ganZhi,
      tianGan: tianGan ?? this.tianGan,
      wuXing: wuXing ?? this.wuXing,
      liuQin: liuQin ?? this.liuQin,
      liuShen: liuShen ?? this.liuShen,
      isShi: isShi ?? this.isShi,
      isYing: isYing ?? this.isYing,
      isXunKong: isXunKong ?? this.isXunKong,
      fuShen: fuShen ?? this.fuShen,
      feiShen: feiShen ?? this.feiShen,
      bianYaoType: bianYaoType ?? this.bianYaoType,
      bianTianGan: bianTianGan ?? this.bianTianGan,
      bianGanZhi: bianGanZhi ?? this.bianGanZhi,
      bianWuXing: bianWuXing ?? this.bianWuXing,
      bianLiuQin: bianLiuQin ?? this.bianLiuQin,
      riYueEffects: riYueEffects ?? this.riYueEffects,
      relations: relations ?? this.relations,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'backCount': backCount,
      'yaoType': yaoType.index,
      'isYang': isYang,
      'isDong': isDong,
      'ganZhi': ganZhi,
      'tianGan': tianGan,
      'wuXing': wuXing,
      'liuQin': liuQin,
      'liuShen': liuShen,
      'isShi': isShi,
      'isYing': isYing,
      'isXunKong': isXunKong,
      'fuShen': fuShen,
      'feiShen': feiShen,
      'bianYaoType': bianYaoType?.index,
      'bianTianGan': bianTianGan,
      'bianGanZhi': bianGanZhi,
      'bianWuXing': bianWuXing,
      'bianLiuQin': bianLiuQin,
      'riYueEffects': riYueEffects,
      'relations': relations,
    };
  }

  /// 从 JSON Map 创建
  factory YaoLine.fromJson(Map<String, dynamic> json) {
    return YaoLine(
      position: json['position'] as int,
      backCount: json['backCount'] as int,
      yaoType: YaoType.values[json['yaoType'] as int],
      isYang: json['isYang'] as bool,
      isDong: json['isDong'] as bool,
      ganZhi: json['ganZhi'] as String?,
      tianGan: json['tianGan'] as String?,
      wuXing: json['wuXing'] as String?,
      liuQin: json['liuQin'] as String?,
      liuShen: json['liuShen'] as String?,
      isShi: json['isShi'] as bool?,
      isYing: json['isYing'] as bool?,
      isXunKong: json['isXunKong'] as bool?,
      fuShen: json['fuShen'] as String?,
      feiShen: json['feiShen'] as String?,
      bianYaoType: json['bianYaoType'] != null
          ? YaoType.values[json['bianYaoType'] as int]
          : null,
      bianTianGan: json['bianTianGan'] as String?,
      bianGanZhi: json['bianGanZhi'] as String?,
      bianWuXing: json['bianWuXing'] as String?,
      bianLiuQin: json['bianLiuQin'] as String?,
      riYueEffects: (json['riYueEffects'] as List?)?.cast<String>(),
      relations: (json['relations'] as List?)?.cast<String>(),
    );
  }

  @override
  String toString() {
    return 'YaoLine($positionName: ${yaoTypeName}, $ganZhi$wuXing, $liuQin)';
  }
}