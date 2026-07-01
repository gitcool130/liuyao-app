/// 神煞结果模型
library;

/// 神煞结果类（共16项）
class ShenshaResult {
  /// 天乙贵人
  final String tianYi;
  /// 驿马
  final String yiMa;
  /// 华盖
  final String huaGai;
  /// 咸池（桃花）
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
  /// 红鸾
  final String hongLuan;
  /// 天喜
  final String tianXi;
  /// 劫煞
  final String jieSha;

  // === 新增 (2026-07-01) ===
  /// 灾煞
  final String zaiSha;
  /// 亡神
  final String wangShen;
  /// 孤辰
  final String guChen;
  /// 寡宿
  final String guaSu;

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
    this.hongLuan = '',
    this.tianXi = '',
    this.jieSha = '',
    this.zaiSha = '',
    this.wangShen = '',
    this.guChen = '',
    this.guaSu = '',
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
      'hongLuan': hongLuan,
      'tianXi': tianXi,
      'jieSha': jieSha,
      'zaiSha': zaiSha,
      'wangShen': wangShen,
      'guChen': guChen,
      'guaSu': guaSu,
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
      hongLuan: json['hongLuan'] as String? ?? '',
      tianXi: json['tianXi'] as String? ?? '',
      jieSha: json['jieSha'] as String? ?? '',
      zaiSha: json['zaiSha'] as String? ?? '',
      wangShen: json['wangShen'] as String? ?? '',
      guChen: json['guChen'] as String? ?? '',
      guaSu: json['guaSu'] as String? ?? '',
    );
  }

  /// 是否为空
  bool isEmpty() {
    return tianYi.isEmpty && yiMa.isEmpty && huaGai.isEmpty &&
        xianChi.isEmpty && tianYiShen.isEmpty && luShen.isEmpty &&
        wenChang.isEmpty && jiangXing.isEmpty && yangRen.isEmpty &&
        hongLuan.isEmpty && tianXi.isEmpty && jieSha.isEmpty &&
        zaiSha.isEmpty && wangShen.isEmpty && guChen.isEmpty && guaSu.isEmpty;
  }

  @override
  String toString() {
    List<String> parts = [];
    if (tianYi.isNotEmpty) parts.add('天乙:$tianYi');
    if (yiMa.isNotEmpty) parts.add('驿马:$yiMa');
    if (xianChi.isNotEmpty) parts.add('咸池:$xianChi');
    if (luShen.isNotEmpty) parts.add('禄神:$luShen');
    if (huaGai.isNotEmpty) parts.add('华盖:$huaGai');
    if (tianYiShen.isNotEmpty) parts.add('天医:$tianYiShen');
    if (wenChang.isNotEmpty) parts.add('文昌:$wenChang');
    if (jiangXing.isNotEmpty) parts.add('将星:$jiangXing');
    if (yangRen.isNotEmpty) parts.add('羊刃:$yangRen');
    if (hongLuan.isNotEmpty) parts.add('红鸾:$hongLuan');
    if (tianXi.isNotEmpty) parts.add('天喜:$tianXi');
    if (jieSha.isNotEmpty) parts.add('劫煞:$jieSha');
    if (zaiSha.isNotEmpty) parts.add('灾煞:$zaiSha');
    if (wangShen.isNotEmpty) parts.add('亡神:$wangShen');
    if (guChen.isNotEmpty) parts.add('孤辰:$guChen');
    if (guaSu.isNotEmpty) parts.add('寡宿:$guaSu');
    return 'ShenshaResult(${parts.join(', ')})';
  }
}
