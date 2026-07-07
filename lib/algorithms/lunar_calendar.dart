/// 农历转换器（基于 lunar 包）
library;

import 'package:lunar/lunar.dart';

/// 农历转换器类
class LunarCalendar {
  /// 农历月份名称
  static const List<String> lunarMonthNames = [
    '正月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月',
  ];

  /// 农历日期名称
  static const List<String> lunarDayNames = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
  ];

  /// 公历日期转农历日期
  /// 返回：[农历年, 农历月（1-12，负数表示闰月），农历日]
  static List<int> solarToLunar(DateTime solarDate) {
    final lunar = Lunar.fromDate(solarDate);
    final month = lunar.getMonth(); // 负数为闰月
    return [lunar.getYear(), month, lunar.getDay()];
  }

  /// 获取农历日期字符串
  /// 格式：如"二月初五"、"闰四月十五"
  static String getLunarDateString(DateTime solarDate) {
    final lunar = Lunar.fromDate(solarDate);
    if (lunar.getMonth() < 0) {
      return '闰${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    }
    return '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }

  /// 获取农历年份（农历年，以正月初一为界）
  static int getLunarYear(DateTime solarDate) {
    return Lunar.fromDate(solarDate).getYear();
  }
}
