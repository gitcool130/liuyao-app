/// 神煞结果模型
library;

/// 神煞结果类（共13项）
class ShenshaResult {
  /// 贵人
  final String tianYi;
  /// 驿马
  final String yiMa;
  /// 华盖
  final String huaGai;
  /// 桃花（咸池）
  final String xianChi;
  /// 禄神
  final String luShen;
  /// 天医
  final String tianYiShen;

  // === 新增 (2026-06-26) ===
  /// 文昌
  final String wenChang;
  /// 将星
  final String jiangXing;
  /// 羊刃
  final String yangRen;
  /// 天喜
  final String tianXi;
  /// 劫煞
  final String jieSha;

  /// 灾煞
  final String zaiSha;

  /// 谋星
  final String mouXing;

  ShenshaResult({
    this.tianYi = '',
    this.yiMa = '',
    this.huaGai = '',
    this.xianChi = '',
    this.tianYiShen = '',
    this.luShen = '',
    this.wenChang = '',
    this.jiangXing = '',
    this.yangRen = '',
    this.tianXi = '',
    this.jieSha = '',
    this.zaiSha = '',
    this.mouXing = '',
  });

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'tianYi': tianYi,
      'yiMa': yiMa,
      'huaGai': huaGai,
      'xianChi': xianChi,
      'tianYiShen': tianYiShen,
      'luShen': luShen,
      'wenChang': wenChang,
      'jiangXing': jiangXing,
      'yangRen': yangRen,
      'tianXi': tianXi,
      'jieSha': jieSha,
      'zaiSha': zaiSha,
      'mouXing': mouXing,
    };
  }

  /// 从 JSON Map 创建
  factory ShenshaResult.fromJson(Map<String, dynamic> json) {
    return ShenshaResult(
      tianYi: json['tianYi'] as String? ?? '',
      yiMa: json['yiMa'] as String? ?? '',
      huaGai: json['huaGai'] as String? ?? '',
      xianChi: json['xianChi'] as String? ?? '',
      tianYiShen: json['tianYiShen'] as String? ?? '',
      luShen: json['luShen'] as String? ?? '',
      wenChang: json['wenChang'] as String? ?? '',
      jiangXing: json['jiangXing'] as String? ?? '',
      yangRen: json['yangRen'] as String? ?? '',
      tianXi: json['tianXi'] as String? ?? '',
      jieSha: json['jieSha'] as String? ?? '',
      zaiSha: json['zaiSha'] as String? ?? '',
      mouXing: json['mouXing'] as String? ?? '',
    );
  }

  /// 是否为空
  bool isEmpty() {
    return tianYi.isEmpty && yiMa.isEmpty && huaGai.isEmpty &&
        xianChi.isEmpty && tianYiShen.isEmpty && luShen.isEmpty &&
        wenChang.isEmpty && jiangXing.isEmpty && yangRen.isEmpty &&
        tianXi.isEmpty && jieSha.isEmpty && zaiSha.isEmpty && mouXing.isEmpty;
  }

  @override
  String toString() {
    List<String> parts = [];
    if (tianYi.isNotEmpty) parts.add('天乙:$tianYi');
    if (yiMa.isNotEmpty) parts.add('驿马:$yiMa');
    if (xianChi.isNotEmpty) parts.add('桃花:$xianChi');
    if (luShen.isNotEmpty) parts.add('禄神:$luShen');
    if (huaGai.isNotEmpty) parts.add('华盖:$huaGai');
    if (tianYiShen.isNotEmpty) parts.add('天医:$tianYiShen');
    if (wenChang.isNotEmpty) parts.add('文昌:$wenChang');
    if (jiangXing.isNotEmpty) parts.add('将星:$jiangXing');
    if (yangRen.isNotEmpty) parts.add('羊刃:$yangRen');
    if (tianXi.isNotEmpty) parts.add('天喜:$tianXi');
    if (jieSha.isNotEmpty) parts.add('劫煞:$jieSha');
    if (zaiSha.isNotEmpty) parts.add('灾煞:$zaiSha');
    if (mouXing.isNotEmpty) parts.add('谋星:$mouXing');
    return 'ShenshaResult(${parts.join(', ')})';
  }
}
