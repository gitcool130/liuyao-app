/// 世应定位配置
/// 根据卦在宫中的位置确定世爻和应爻
library;

import '../models/gua_info.dart';
import '../models/yao_line.dart';
import 'constants.dart';

/// 世应配置器
class ShiYingConfig {
  /// 获取卦在宫中的位置（0-7）
  /// 直接使用预定义的位置表gua64Position
  /// 位置：0=八纯卦, 1=一世卦, 2=二世卦, 3=三世卦
  ///      4=四世卦, 5=五世卦, 6=游魂卦, 7=归魂卦
  static int getGuaPositionInGong(GuaInfo benGua, int gongNum) {
    // 直接从预定义的位置表获取
    int guaIndex = benGua.gua64Index;
    if (guaIndex >= 0 && guaIndex < gua64Position.length) {
      return gua64Position[guaIndex];
    }
    // 默认返回八纯卦位置
    return 0;
  }

  /// 为六爻配置世应位置
  static void assignShiYing(List<YaoLine> yaoLines, GuaInfo benGua, int gongNum) {
    // 先清除所有世应标记
    for (int i = 0; i < yaoLines.length; i++) {
      yaoLines[i] = yaoLines[i].copyWith(isShi: false, isYing: false);
    }

    // 获取卦在宫中的位置
    int position = getGuaPositionInGong(benGua, gongNum);

    // 获取世应位置
    var (shiPos, yingPos) = getShiYingPos(position);

    // 标记世应
    yaoLines[shiPos - 1] = yaoLines[shiPos - 1].copyWith(isShi: true);
    yaoLines[yingPos - 1] = yaoLines[yingPos - 1].copyWith(isYing: true);
  }

  /// 获取世爻位置说明
  static String getShiYaoExplanation(int position) {
    const Map<int, String> explanations = {
      0: '八纯卦：世爻在六爻，应爻在三爻',
      1: '一世卦：世爻在初爻，应爻在四爻',
      2: '二世卦：世爻在二爻，应爻在五爻',
      3: '三世卦：世爻在三爻，应爻在六爻',
      4: '四世卦：世爻在四爻，应爻在初爻',
      5: '五世卦：世爻在五爻，应爻在二爻',
      6: '游魂卦：世爻在四爻，应爻在初爻',
      7: '归魂卦：世爻在三爻，应爻在六爻',
    };
    return explanations[position] ?? '';
  }

  /// 获取卦位名称
  static String getPositionName(int position) {
    const Map<int, String> names = {
      0: '八纯卦',
      1: '一世卦',
      2: '二世卦',
      3: '三世卦',
      4: '四世卦',
      5: '五世卦',
      6: '游魂卦',
      7: '归魂卦',
    };
    return names[position] ?? '';
  }
}