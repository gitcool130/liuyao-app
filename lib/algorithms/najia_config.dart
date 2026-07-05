/// 纳甲装卦配置
/// 为各爻分配地支、五行
library;

import '../models/yao_line.dart';
import 'constants.dart';

/// 纳甲装卦器
class NajiaConfig {
  /// 为六爻分配纳甲地支和天干
  /// 根据内卦和外卦编号查表
  /// 八卦纳支表是六个爻的地支，内卦用前三个，外卦用后三个
  static void assignDiZhi(List<YaoLine> yaoLines, int innerGuaId, int outerGuaId) {
    // 获取内卦和外卦的地支配置
    List<String> innerDiZhi = baGuaDiZhi[innerGuaId] ?? [];
    List<String> outerDiZhi = baGuaDiZhi[outerGuaId] ?? [];

    // 下卦（初、二、三爻）用内卦地支的前三个
    // 上卦（四、五、上爻）用外卦地支的后三个（索引3,4,5）
    List<String> allDiZhi = [
      innerDiZhi[0], // 初爻
      innerDiZhi[1], // 二爻
      innerDiZhi[2], // 三爻
      outerDiZhi[3], // 四爻（外卦纳支表的后三个）
      outerDiZhi[4], // 五爻
      outerDiZhi[5], // 上爻
    ];

    // 内卦天干与外卦天干
    String innerGan = getBaGuaTianGan(innerGuaId, false);
    String outerGan = getBaGuaTianGan(outerGuaId, true);

    // 为每个爻分配天干、地支和五行
    for (int i = 0; i < 6; i++) {
      String zhi = allDiZhi[i];
      String gan = i < 3 ? innerGan : outerGan;
      yaoLines[i] = yaoLines[i].copyWith(
        tianGan: gan,
        ganZhi: zhi,
        wuXing: diZhiWuXing[zhi] ?? '',
      );
    }
  }

  /// 为所有爻分配变卦信息（包括非动爻）
  /// 变卦的纳甲也按同样的规则
  static void assignBianYaoDiZhi(List<YaoLine> yaoLines, int bianInnerGuaId, int bianOuterGuaId) {
    // 获取变卦的地支配置
    List<String> innerDiZhi = baGuaDiZhi[bianInnerGuaId] ?? [];
    List<String> outerDiZhi = baGuaDiZhi[bianOuterGuaId] ?? [];

    List<String> allDiZhi = [
      innerDiZhi[0],
      innerDiZhi[1],
      innerDiZhi[2],
      outerDiZhi[3], // 外卦用后三个
      outerDiZhi[4],
      outerDiZhi[5],
    ];

    // 变卦的天干与地支配置
    String innerGan = getBaGuaTianGan(bianInnerGuaId, false);
    String outerGan = getBaGuaTianGan(bianOuterGuaId, true);

    // 为所有爻分配变爻信息（动爻阴阳互换，静爻保持不变）
    for (int i = 0; i < 6; i++) {
      String zhi = allDiZhi[i];
      String gan = i < 3 ? innerGan : outerGan;
      // 变爻类型：动爻阴阳互换，静爻保持不变
      YaoType bianYaoType;
      if (yaoLines[i].yaoType == YaoType.laoYang) {
        bianYaoType = YaoType.shaoYin; // 老阳变少阴
      } else if (yaoLines[i].yaoType == YaoType.laoYin) {
        bianYaoType = YaoType.shaoYang; // 老阴变少阳
      } else {
        bianYaoType = yaoLines[i].yaoType; // 静爻不变
      }

      yaoLines[i] = yaoLines[i].copyWith(
        bianYaoType: bianYaoType,
        bianTianGan: gan,
        bianGanZhi: zhi,
        bianWuXing: diZhiWuXing[zhi] ?? '',
      );
    }
  }

  /// 获取八卦的纳干
  /// 乾纳甲壬，坤纳乙癸，震纳庚，巽纳辛，坎纳戊，离纳己，艮纳丙，兑纳丁
  static String getBaGuaTianGan(int guaId, bool isOuter) {
    // 内卦纳干
    const Map<int, String> innerGuaGan = {
      1: '甲', // 乾内卦
      2: '丁', // 兑
      3: '己', // 离
      4: '庚', // 震
      5: '辛', // 巽
      6: '戊', // 坎
      7: '丙', // 艮
      8: '乙', // 坤内卦
    };

    // 外卦纳干
    const Map<int, String> outerGuaGan = {
      1: '壬', // 乾外卦
      2: '丁', // 兑（内外相同）
      3: '己', // 离（内外相同）
      4: '庚', // 震（内外相同）
      5: '辛', // 巽（内外相同）
      6: '戊', // 坎（内外相同）
      7: '丙', // 艮（内外相同）
      8: '癸', // 坤外卦
    };

    return isOuter ? (outerGuaGan[guaId] ?? '') : (innerGuaGan[guaId] ?? '');
  }

  /// 获取爻的完整纳甲干支（天干+地支）
  /// 注意：六爻排盘通常只用地支，天干主要用于纳甲装卦说明
  static String getYaoGanZhi(int guaId, int yaoPosition, bool isOuter) {
    String gan = getBaGuaTianGan(guaId, isOuter);
    List<String> zhiList = baGuaDiZhi[guaId] ?? [];
    String zhi = zhiList[(yaoPosition - 1) % 6];

    return '$gan$zhi';
  }
}