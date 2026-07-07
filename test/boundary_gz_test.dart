import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_app/algorithms/ganzhi_converter.dart';
import 'package:liuyao_app/algorithms/shouxing_calendar.dart';

void main() {
  setUpAll(() async => await ShouXingCalendar.init());

  group('节气交月边界', () {
    test('2026年7月7日小暑前后', () {
      // 小暑北京时间 2026-07-07 09:57
      final before = GanZhiConverter.convert(DateTime(2026, 7, 7, 9, 0));
      final after = GanZhiConverter.convert(DateTime(2026, 7, 7, 10, 0));
      expect(before.monthZhi, '午', reason: '小暑前应属午月');
      expect(after.monthZhi, '未', reason: '小暑后应属未月');
    });

    test('2026年6月5日芒种前后', () {
      // 芒种北京时间 2026-06-05 23:48
      final before = GanZhiConverter.convert(DateTime(2026, 6, 5, 22, 0));
      final after = GanZhiConverter.convert(DateTime(2026, 6, 5, 23, 50));
      expect(before.monthZhi, '巳', reason: '芒种前应属巳月');
      expect(after.monthZhi, '午', reason: '芒种后应属午月');
    });

    test('2026年2月4日立春前后', () {
      // 立春北京时间 2026-02-04 04:02
      final before = GanZhiConverter.convert(DateTime(2026, 2, 4, 3, 0));
      final after = GanZhiConverter.convert(DateTime(2026, 2, 4, 5, 0));
      expect(before.yearZhi, '巳', reason: '立春前应属蛇年');
      expect(after.yearZhi, '午', reason: '立春后应属马年');
    });
  });
}
