/// 卦计算总协调器
/// 整合所有算法，从背面数到完整排盘结果
library;

import '../models/divination_record.dart';
import '../models/gua_info.dart';
import '../models/shensha_result.dart';
import '../models/yao_line.dart';
import 'ganzhi_converter.dart';
import 'gua_generator.dart';
import 'najia_config.dart';
import 'liuqin_config.dart';
import 'liushen_config.dart';
import 'xunkong_calculator.dart';
import 'shiying_config.dart';
import 'fushen_finder.dart';
import 'shensha_calculator.dart';

/// 卦计算器（总协调器）
class GuaCalculator {
  /// 入口方法：根据背面数和起卦时间生成完整排盘数据
  static DivinationRecord calculate({
    required List<int> backCounts,  // 6个背面数 [0-3]
    required DateTime divTime,      // 起卦时间
    required String question,       // 所问问题
    String startMethod = 'manual',  // 起卦方式
    String querentName = '',        // 起卦人姓名
    String querentGender = '',      // 起卦人性别
  }) {
    // 1. 干支转换
    GanZhiResult ganZhi = GanZhiConverter.convert(divTime);

    return _assemble(
      backCounts: backCounts,
      divTime: divTime,
      question: question,
      startMethod: startMethod,
      querentName: querentName,
      querentGender: querentGender,
      yearGz: ganZhi.yearGz,
      monthGz: ganZhi.monthGz,
      dayGz: ganZhi.dayGz,
      hourGz: ganZhi.hourGz,
    );
  }

  /// 入口方法二：直接指定干支（月建 + 日辰 + 年 + 时辰），不经公历换算
  ///
  /// 用于「干支排盘」：按古法卦例，只知“戌月 丁亥日”这类干支信息时，
  /// 无法反推公历，只能直接给定干支来装卦。
  ///
  /// - [monthGz] 只需月支（如 '戌'），也可传完整月柱（'甲戌'）
  /// - [dayGz] 必须是完整日柱（如 '丁亥'），六神与旬空都由它决定
  /// - [hourGz] 可留空（表示不记时辰）；也可传时支（'子'），
  ///   由五鼠遁按日干补全时干
  static DivinationRecord calculateFromGanZhi({
    required List<int> backCounts,   // 6个背面数 [0-3]
    required String dayGz,           // 日柱，如 '丁亥'
    String monthGz = '',             // 月建，如 '戌' 或 '甲戌'
    String yearGz = '',              // 年柱，如 '癸丑'
    String hourGz = '',              // 时辰，如 '子' 或 '庚子'，空=不记
    String question = '',            // 所问问题
    String startMethod = 'ganzhi',   // 起卦方式
    String querentName = '',         // 起卦人姓名
    String querentGender = '',       // 起卦人性别
    DateTime? divTime,               // 仅用于记录的显示时间，默认当前
  }) {
    if (dayGz.length != 2) {
      throw ArgumentError('日柱必须是两个字，如「丁亥」');
    }

    // 月建：只给地支时原样使用；给了月干则取地支
    String monthZhi = monthGz.isEmpty
        ? ''
        : (monthGz.length >= 2 ? monthGz[1] : monthGz);

    // 时柱：只给时支时，用五鼠遁按日干补全
    String hourFull = '';
    if (hourGz.isNotEmpty) {
      hourFull = hourGz.length >= 2
          ? hourGz
          : GanZhiConverter.hourGzFromZhi(dayGz, hourGz);
    }

    return _assemble(
      backCounts: backCounts,
      divTime: divTime ?? DateTime.now(),
      question: question,
      startMethod: startMethod,
      querentName: querentName,
      querentGender: querentGender,
      yearGz: yearGz,
      monthGz: monthGz.isEmpty ? '' : (monthGz.length >= 2 ? monthGz : monthGz),
      dayGz: dayGz,
      hourGz: hourFull,
      monthZhiOverride: monthZhi,
    );
  }

  /// 装配完整盘面（所有入口共用）
  static DivinationRecord _assemble({
    required List<int> backCounts,
    required DateTime divTime,
    required String question,
    required String startMethod,
    required String querentName,
    required String querentGender,
    required String yearGz,
    required String monthGz,
    required String dayGz,
    required String hourGz,
    String? monthZhiOverride,
  }) {
    // 2. 创建六爻基础数据
    List<YaoLine> yaoLines = _createYaoLines(backCounts);

    // 3. 生成本卦、变卦、互卦
    GuaInfo benGua = GuaGenerator.generateBenGua(yaoLines);
    GuaInfo? bianGua = GuaGenerator.generateBianGua(yaoLines);
    GuaInfo? huGua = GuaGenerator.generateHuGua(yaoLines);

    // 4. 纳甲装卦（为各爻分配地支）
    NajiaConfig.assignDiZhi(yaoLines, benGua.innerGuaId, benGua.outerGuaId);

    // 5. 为动爻的变爻分配地支（如有变卦）
    if (bianGua != null) {
      NajiaConfig.assignBianYaoDiZhi(yaoLines, bianGua.innerGuaId, bianGua.outerGuaId);
    }

    // 6. 六亲配置
    String gongWuXing = benGua.guaWuXing ?? '';
    LiuQinConfig.assignLiuQin(yaoLines, gongWuXing);

    // 7. 为变爻配置六亲
    if (bianGua != null) {
      LiuQinConfig.assignBianYaoLiuQin(yaoLines, gongWuXing);
    }

    // 8. 六神配置（按日干起）
    String dayGan = dayGz[0];
    String dayZhi = dayGz[1];
    LiuShenConfig.assignLiuShen(yaoLines, dayGan);

    // 9. 旬空判断
    XunKongCalculator.assignXunKong(yaoLines, dayGz);
    String xunKong = XunKongCalculator.getXunKongStr(dayGz);

    // 10. 世应定位
    int gongNum = benGua.gongNum ?? 0;
    ShiYingConfig.assignShiYing(yaoLines, benGua, gongNum);

    // 11. 伏神查找
    FuShenFinder.findFuShen(yaoLines, gongNum, gongWuXing);

    // 12. 神煞计算
    String monthZhi = monthZhiOverride ??
        (monthGz.length >= 2 ? monthGz[1] : monthGz);
    String yearZhi = yearGz.length >= 2 ? yearGz[1] : yearGz;
    ShenshaResult shensha = ShenShaCalculator.calculate(
      dayGan: dayGan,
      dayZhi: dayZhi,
      yearZhi: yearZhi,
      monthZhi: monthZhi,
    );

    // 13. 组装完整记录
    return DivinationRecord(
      createdAt: DateTime.now(),
      divTime: divTime,
      question: question,
      startMethod: startMethod,
      querentName: querentName,
      querentGender: querentGender,
      yearGz: yearGz,
      monthGz: monthGz,
      dayGz: dayGz,
      hourGz: hourGz,
      xunKong: xunKong,
      benGua: benGua,
      bianGua: bianGua,
      huGua: huGua,
      backCounts: backCounts,
      yaoLines: yaoLines,
      shensha: shensha,
    );
  }

  /// 创建六爻基础数据
  static List<YaoLine> _createYaoLines(List<int> backCounts) {
    if (backCounts.length != 6) {
      throw ArgumentError('必须提供6个背面数');
    }

    return backCounts
        .asMap()
        .entries
        .map((e) => YaoLine.fromBackCount(e.key + 1, e.value))
        .toList();
  }

  /// 快速验证方法：用于测试
  /// 返回排盘摘要信息
  static String getSummary(DivinationRecord record) {
    StringBuffer sb = StringBuffer();
    sb.writeln('=== 六爻排盘 ===');
    sb.writeln('起卦时间: ${record.formattedDivTime}');
    sb.writeln('干支: ${record.formattedGanZhi}');
    sb.writeln('旬空: ${record.xunKong}');
    sb.writeln('');
    sb.writeln('本卦: ${record.benGua.guaName} ${record.benGua.guaSymbol}');
    sb.writeln('卦宫: ${record.benGua.gongName} 五行: ${record.benGua.guaWuXing}');
    if (record.bianGua != null) {
      sb.writeln('变卦: ${record.bianGua!.guaName} ${record.bianGua!.guaSymbol}');
    }
    if (record.huGua != null) {
      sb.writeln('互卦: ${record.huGua!.guaName} ${record.huGua!.guaSymbol}');
    }
    sb.writeln('');
    sb.writeln('=== 六爻详情 ===');
    for (int i = 5; i >= 0; i--) {
      YaoLine yao = record.yaoLines[i];
      String shi = yao.isShi == true ? '世' : '';
      String ying = yao.isYing == true ? '应' : '';
      String dong = yao.isDong ? '○' : '';
      String kong = yao.isXunKong == true ? '空' : '';
      sb.writeln('${yao.positionName}: ${yao.liuShen} ${yao.liuQin} ${yao.tianGan}${yao.ganZhi}${yao.wuXing} $shi$ying$dong$kong');
    }
    sb.writeln('');
    sb.writeln('=== 神煞 ===');
    sb.writeln('贵人: ${record.shensha.tianYi}    文昌: ${record.shensha.wenChang}');
    sb.writeln('驿马: ${record.shensha.yiMa}        将星: ${record.shensha.jiangXing}');
    sb.writeln('桃花: ${record.shensha.xianChi}        天喜: ${record.shensha.tianXi}');
    sb.writeln('禄神: ${record.shensha.luShen}        羊刃: ${record.shensha.yangRen}');
    sb.writeln('华盖: ${record.shensha.huaGai}        劫煞: ${record.shensha.jieSha}');
    sb.writeln('天医: ${record.shensha.tianYiShen}        灾煞: ${record.shensha.zaiSha}');
    sb.writeln('谋星: ${record.shensha.mouXing}');

    return sb.toString();
  }
}