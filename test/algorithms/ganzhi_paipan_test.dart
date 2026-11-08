/// 干支排盘（不经公历）回归测试
///
/// 重点验证：
/// 1. 只给「月建 + 日辰」也能装卦，六神按日干起、旬空按日辰定
/// 2. 时支能由五鼠遁补出时干
/// 3. 年、时辰缺失时格式化结果不出现空的「年」「时」
/// 4. 动爻 → 变卦正确
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_app/algorithms/ganzhi_converter.dart';
import 'package:liuyao_app/algorithms/gua_calculator.dart';

void main() {
  group('五鼠遁时柱', () {
    test('丁日起庚子（丁壬起庚子）', () {
      expect(GanZhiConverter.hourGzFromZhi('丁亥', '子'), '庚子');
      expect(GanZhiConverter.hourGzFromZhi('丁亥', '丑'), '辛丑');
      expect(GanZhiConverter.hourGzFromZhi('丁亥', '亥'), '辛亥');
    });

    test('甲日起甲子', () {
      expect(GanZhiConverter.hourGzFromZhi('甲子', '子'), '甲子');
      expect(GanZhiConverter.hourGzFromZhi('甲子', '卯'), '丁卯');
    });

    test('癸日起壬子', () {
      expect(GanZhiConverter.hourGzFromZhi('癸亥', '子'), '壬子');
    });
  });

  group('干支排盘 — 乾为天 静卦', () {
    late final record = GuaCalculator.calculateFromGanZhi(
      backCounts: const [1, 1, 1, 1, 1, 1], // 六爻皆少阳
      dayGz: '丁亥',
      monthGz: '戌',
      question: '占财',
    );

    test('本卦为乾为天，无变卦', () {
      expect(record.benGua.guaName, '乾为天');
      expect(record.bianGua, isNull);
    });

    test('旬空由日辰定：丁亥 → 午未', () {
      expect(record.xunKong, '午未');
    });

    test('六神按日干起：丁日初爻朱雀，上爻青龙', () {
      expect(record.yaoLines[0].liuShen, '朱雀');
      expect(record.yaoLines[1].liuShen, '勾陈');
      expect(record.yaoLines[5].liuShen, '青龙');
    });

    test('只给月支时，格式化不出现空的「年」「时」', () {
      expect(record.formattedGanZhi, '戌月 丁亥日');
      expect(record.hourGz, '');
    });

    test('起卦方式标记为 ganzhi', () {
      expect(record.startMethod, 'ganzhi');
    });

    test('纳甲装卦：乾卦初爻甲子水', () {
      final yao = record.yaoLines[0];
      expect('${yao.tianGan}${yao.ganZhi}${yao.wuXing}', '甲子水');
    });
  });

  group('干支排盘 — 动爻与变卦', () {
    test('乾为天初爻老阳 → 天风姤', () {
      final record = GuaCalculator.calculateFromGanZhi(
        backCounts: const [3, 1, 1, 1, 1, 1], // 初爻老阳（阳动）
        dayGz: '甲子',
        monthGz: '子',
      );
      expect(record.benGua.guaName, '乾为天');
      expect(record.bianGua?.guaName, '天风姤');
      expect(record.yaoLines[0].isDong, isTrue);
    });

    test('乾为天上爻老阳 → 泽天夬', () {
      final record = GuaCalculator.calculateFromGanZhi(
        backCounts: const [1, 1, 1, 1, 1, 3], // 上爻老阳
        dayGz: '甲子',
        monthGz: '子',
      );
      expect(record.benGua.guaName, '乾为天');
      expect(record.bianGua?.guaName, '泽天夬');
    });
  });

  group('干支排盘 — 输入容错', () {
    test('月柱给完整干支时取地支', () {
      final a = GuaCalculator.calculateFromGanZhi(
        backCounts: const [1, 1, 1, 1, 1, 1],
        dayGz: '丁亥',
        monthGz: '甲戌',
      );
      final b = GuaCalculator.calculateFromGanZhi(
        backCounts: const [1, 1, 1, 1, 1, 1],
        dayGz: '丁亥',
        monthGz: '戌',
      );
      expect(a.xunKong, b.xunKong);
      expect(a.benGua.guaName, b.benGua.guaName);
    });

    test('给时支自动补时干', () {
      final record = GuaCalculator.calculateFromGanZhi(
        backCounts: const [1, 1, 1, 1, 1, 1],
        dayGz: '丁亥',
        monthGz: '戌',
        hourGz: '子',
      );
      expect(record.hourGz, '庚子');
      expect(record.formattedGanZhi, '戌月 丁亥日 庚子时');
    });

    test('日柱长度不对时报错', () {
      expect(
        () => GuaCalculator.calculateFromGanZhi(
          backCounts: const [1, 1, 1, 1, 1, 1],
          dayGz: '丁',
          monthGz: '戌',
        ),
        throwsArgumentError,
      );
    });
  });
}
