/// 地支关系计算模块
/// 提供六冲、六合、三合、半合、生、克等地支关系判断
class DiZhiRelations {
  /// 十二地支
  static const List<String> diZhi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  /// 地支五行
  static const Map<String, String> diZhiWuXing = {
    '子': '水', '亥': '水',
    '丑': '土', '辰': '土', '未': '土', '戌': '土',
    '寅': '木', '卯': '木',
    '巳': '火', '午': '火',
    '申': '金', '酉': '金',
  };

  // ============================================================================
  // 六冲关系
  // ============================================================================

  /// 六冲对照表（一对一）
  static const Map<String, String> liuChong = {
    '子': '午', '午': '子',
    '丑': '未', '未': '丑',
    '寅': '申', '申': '寅',
    '卯': '酉', '酉': '卯',
    '辰': '戌', '戌': '辰',
    '巳': '亥', '亥': '巳',
  };

  /// 检查两个地支是否六冲
  static bool isChong(String dz1, String dz2) {
    return liuChong[dz1] == dz2;
  }

  /// 获取冲的地支
  static String? getChong(String dz) {
    return liuChong[dz];
  }

  // ============================================================================
  // 六合关系
  // ============================================================================

  /// 六合对照表（一对一）
  static const Map<String, String> liuHe = {
    '子': '丑', '丑': '子',
    '寅': '亥', '亥': '寅',
    '卯': '戌', '戌': '卯',
    '辰': '酉', '酉': '辰',
    '巳': '申', '申': '巳',
    '午': '未', '未': '午',
  };

  /// 检查两个地支是否六合
  static bool isHe(String dz1, String dz2) {
    return liuHe[dz1] == dz2;
  }

  /// 获取合的地支
  static String? getHe(String dz) {
    return liuHe[dz];
  }

  // ============================================================================
  // 三合局
  // ============================================================================

  /// 三合局（四组）
  static const List<List<String>> sanHe = [
    ['申', '子', '辰'], // 水局
    ['寅', '午', '戌'], // 火局
    ['巳', '酉', '丑'], // 金局
    ['亥', '卯', '未'], // 木局
  ];

  /// 检查三个地支是否组成三合局
  static bool isSanHe(String dz1, String dz2, String dz3) {
    final set = {dz1, dz2, dz3};
    for (final ju in sanHe) {
      if (set.containsAll(ju) && set.length == 3) return true;
    }
    return false;
  }

  /// 获取三合局（如果有）
  static List<String>? getSanHe(String dz1, String dz2, String dz3) {
    final set = {dz1, dz2, dz3};
    for (final ju in sanHe) {
      if (set.containsAll(ju) && set.length == 3) return ju;
    }
    return null;
  }

  /// 检查两个地支是否同属一个三合局（内部辅助方法）
  /// 六爻无"半三合"概念，仅供内部计算使用
  static bool _isInSameSanHeGroup(String dz1, String dz2) {
    for (final ju in sanHe) {
      final has1 = ju.contains(dz1);
      final has2 = ju.contains(dz2);
      if (has1 && has2 && dz1 != dz2) return true;
    }
    return false;
  }

  /// 获取三合局的第三个地支（内部辅助）
  static String? _getSanHeThird(String dz1, String dz2) {
    for (final ju in sanHe) {
      if (ju.contains(dz1) && ju.contains(dz2) && dz1 != dz2) {
        return ju.firstWhere((d) => d != dz1 && d != dz2);
      }
    }
    return null;
  }

  // ============================================================================
  // 五行生克
  // ============================================================================

  /// 五行相生：金→水→木→火→土→金
  static const Map<String, String> wuXingSheng = {
    '金': '水',
    '水': '木',
    '木': '火',
    '火': '土',
    '土': '金',
  };

  /// 五行相克：金→木→土→水→火→金
  static const Map<String, String> wuXingKe = {
    '金': '木',
    '木': '土',
    '土': '水',
    '水': '火',
    '火': '金',
  };

  /// 检查两个地支是否相生（dz1生dz2）
  static bool isSheng(String dz1, String dz2) {
    final wx1 = diZhiWuXing[dz1];
    final wx2 = diZhiWuXing[dz2];
    if (wx1 == null || wx2 == null) return false;
    return wuXingSheng[wx1] == wx2;
  }

  /// 检查两个地支是否相克（dz1克dz2）
  static bool isKe(String dz1, String dz2) {
    final wx1 = diZhiWuXing[dz1];
    final wx2 = diZhiWuXing[dz2];
    if (wx1 == null || wx2 == null) return false;
    return wuXingKe[wx1] == wx2;
  }

  /// 获取生克关系描述
  /// 注意：六爻无"半三合"概念，两个地支同属三合组不单独显示
  static String? getRelationDesc(String dz1, String dz2) {
    if (isChong(dz1, dz2)) return '冲';
    if (isHe(dz1, dz2)) return '合';
    if (isSheng(dz1, dz2)) return '生';
    if (isKe(dz1, dz2)) return '克';
    return null;
  }

  // ============================================================================
  // 关系类型枚举
  // ============================================================================

  /// 关系类型
  static const int relationNone = 0;
  static const int relationChong = 1;   // 冲
  static const int relationHe = 2;        // 合
  static const int relationSanHe = 3;     // 三合
  static const int relationSheng = 4;     // 生
  static const int relationKe = 5;        // 克

  /// 获取关系类型（优先级：冲>合>生>克）
  /// 注意：六爻只有三合局（三个齐全），无半三合概念
  /// 两个地支同属三合组不单独判断为关系
  static int getRelationType(String dz1, String dz2) {
    if (isChong(dz1, dz2)) return relationChong;
    if (isHe(dz1, dz2)) return relationHe;
    if (isSheng(dz1, dz2)) return relationSheng;
    if (isKe(dz1, dz2)) return relationKe;
    return relationNone;
  }

  /// 关系颜色（用于连线）
  static const Map<int, int> relationColors = {
    relationChong: 0xFFE53935, // 红色
    relationHe: 0xFF43A047,      // 绿色
    relationSanHe: 0xFF43A047,   // 绿色（三合）
    relationSheng: 0xFFFFB300,   // 黄色
    relationKe: 0xFF1E88E5,      // 蓝色
  };

  /// 获取关系颜色
  static int getRelationColor(int relationType) {
    return relationColors[relationType] ?? 0xFF757575;
  }
}

/// 爻关系信息（用于绘制连线）
class YaoRelation {
  /// 源爻位置（1-6，0表示月建/日辰）
  final int fromPosition;

  /// 目标爻位置（1-6）
  final int toPosition;

  /// 源类型：'month'=月建, 'day'=日辰, 'yao'=卦爻, 'bian'=变爻, 'fu'=伏神
  final String fromType;

  /// 目标类型：'yao'=卦爻, 'fu'=伏神
  final String toType;

  /// 关系类型
  final int relationType;

  /// 关系描述
  final String description;

  /// 源地支
  final String fromDiZhi;

  /// 目标地支
  final String toDiZhi;

  YaoRelation({
    required this.fromPosition,
    required this.toPosition,
    required this.fromType,
    required this.toType,
    required this.relationType,
    required this.description,
    required this.fromDiZhi,
    required this.toDiZhi,
  });

  /// 获取颜色
  int get color => DiZhiRelations.getRelationColor(relationType);

  @override
  String toString() {
    return '$fromDiZhi($fromType$fromPosition) → $toDiZhi($toType$toPosition): $description';
  }
}
