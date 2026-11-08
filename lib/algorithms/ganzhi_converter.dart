/// 干支转换器
/// 公历日期时间 → 天干地支（年柱、月柱、日柱、时柱）
library;

import 'constants.dart';
import 'shouxing_calendar.dart';
import 'lunar_calendar.dart';

/// 干支转换结果
class GanZhiResult {
  final String yearGz;   // 年柱
  final String monthGz;  // 月柱
  final String dayGz;    // 日柱
  final String hourGz;   // 时柱

  /// 农历日期
  final String lunarDate; // 农历日期字符串，如"二月初五"

  /// 节气信息（如果当天是节气日）
  final String? jieQiInfo; // 节气名称和交割时间，如"立春 05:32"

  /// 年干
  String get yearGan => yearGz[0];

  /// 年支
  String get yearZhi => yearGz[1];

  /// 月干
  String get monthGan => monthGz[0];

  /// 月支
  String get monthZhi => monthGz[1];

  /// 日干
  String get dayGan => dayGz[0];

  /// 日支
  String get dayZhi => dayGz[1];

  /// 时干
  String get hourGan => hourGz[0];

  /// 时支
  String get hourZhi => hourGz[1];

  GanZhiResult({
    required this.yearGz,
    required this.monthGz,
    required this.dayGz,
    required this.hourGz,
    this.lunarDate = '',
    this.jieQiInfo,
  });

  @override
  String toString() => '$yearGz年 $monthGz月 $dayGz日 $hourGz时';
}

/// 干支转换器类
class GanZhiConverter {
  /// 将公历日期时间转换为干支
  static GanZhiResult convert(DateTime dateTime) {
    String yearGz = _getYearGanZhi(dateTime);
    String monthGz = _getMonthGanZhi(dateTime, yearGz);
    String dayGz = _getDayGanZhi(dateTime);
    String hourGz = _getHourGanZhi(dateTime, dayGz);
    String lunarDate = _getLunarDate(dateTime);
    String? jieQiInfo = _getJieQiInfo(dateTime);

    return GanZhiResult(
      yearGz: yearGz,
      monthGz: monthGz,
      dayGz: dayGz,
      hourGz: hourGz,
      lunarDate: lunarDate,
      jieQiInfo: jieQiInfo,
    );
  }

  /// 获取节气信息（如果当天是节气日）
  static String? _getJieQiInfo(DateTime dateTime) {
    int year = dateTime.year;
    final jieQiList = ShouXingCalendar.getJieQiList(year);

    // 检查当天是否是某个节气日
    for (var jieQi in jieQiList) {
      DateTime jieQiTime = jieQi.time;
      // 判断是否同一天
      if (jieQiTime.year == dateTime.year &&
          jieQiTime.month == dateTime.month &&
          jieQiTime.day == dateTime.day) {
        // 格式化时间
        String timeStr = '${jieQiTime.hour.toString().padLeft(2, '0')}:${jieQiTime.minute.toString().padLeft(2, '0')}';
        return '${jieQi.name} $timeStr';
      }
    }
    return null;
  }

  /// 计算农历日期（使用精确算法）
  static String _getLunarDate(DateTime dateTime) {
    return LunarCalendar.getLunarDateString(dateTime);
  }

  /// 年柱计算
  /// 以立春为界，立春前算上一年（使用寿星万年历精确立春时间）
  /// 1984年是甲子年（基准）
  static String _getYearGanZhi(DateTime dateTime) {
    int year = dateTime.year;

    // 使用寿星万年历判断是否在立春之前
    bool beforeLichun = ShouXingCalendar.isBeforeLichun(dateTime);

    int effectiveYear = beforeLichun ? year - 1 : year;

    // 1984年是甲子年（基准）
    // 2024年也是甲子年（60年一轮回）
    int offset = (effectiveYear - 1984) % 60;
    if (offset < 0) offset += 60;

    return ganzhi60[offset];
  }

  /// 月柱计算
  /// 使用寿星万年历精确节气判定月支
  /// 月干 = (年干序号 × 2 + 月支序号) % 10
  static String _getMonthGanZhi(DateTime dateTime, String yearGz) {
    // 使用寿星万年历获取精确月支索引
    int zhiIdx = ShouXingCalendar.getMonthZhiIndex(dateTime);
    String monthZhi = diZhi[zhiIdx - 1];

    // 月干计算
    // 甲年寅月起丙，公式：月干 = (年干序号 × 2 + 月支序号) % 10
    // 子=1, 丑=2, 寅=3, 卯=4, 辰=5, 巳=6, 午=7, 未=8, 申=9, 酉=10, 戌=11, 亥=12
    String yearGan = yearGz[0];
    int yearGanIdx = tianGan.indexOf(yearGan); // 0-9

    // 月干公式：(年干序号 × 2 + 月支序号) % 10
    // 注意：月支序号从子=1开始，但月干起点要减1
    // 甲年寅月(3) → (0 × 2 + (3-1)) % 10 = 2 → 丙 ✓
    int monthGanIdx = (yearGanIdx * 2 + zhiIdx - 1) % 10;
    String monthGan = tianGan[monthGanIdx];

    return '$monthGan$monthZhi';
  }

  /// 日柱计算
  /// 使用儒略日法计算日柱
  static String _getDayGanZhi(DateTime dateTime) {
    int jd = _gregorianToJD(dateTime.year, dateTime.month, dateTime.day);

    // 日干支序号计算
    // 以1900年1月31日（甲子日，JD=2415080）为基准
    // 或者用公式：日干支 = (JD + 49) % 60
    // 这里用更精确的算法

    // 2024年1月1日是甲子日（JD=2460311）
    // 偏移量 = JD - 2460311
    int baseJD = 2460311; // 2024-01-01 甲子
    int offset = (jd - baseJD) % 60;
    if (offset < 0) offset += 60;

    return ganzhi60[offset];
  }

  /// 公历转儒略日
  static int _gregorianToJD(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    int a = year ~/ 100;
    int b = 2 - a + a ~/ 4;
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day + b - 1524;
  }

  /// 时柱计算
  /// 五鼠遁：甲己起甲子，乙庚起丙子，丙辛起戊子，丁壬起庚子，戊癸起壬子
  static String _getHourGanZhi(DateTime dateTime, String dayGz) {
    int hour = dateTime.hour;

    // 时辰对应
    // 23-1点: 子时(23:00-00:59)
    // 1-3点: 丑时(01:00-02:59)
    // 3-5点: 寅时(03:00-04:59)
    // ...以此类推
    int shiChenIdx;
    if (hour == 23 || hour == 0) {
      shiChenIdx = 0; // 子时
    } else {
      // 1-2点→丑(1), 3-4点→寅(2), 5-6点→卯(3)...
      shiChenIdx = ((hour - 1) ~/ 2) + 1;
    }
    String hourZhi = diZhi[shiChenIdx];

    // 日干确定时干起点
    String dayGan = dayGz[0];
    int dayGanIdx = tianGan.indexOf(dayGan); // 0-9

    // 五鼠遁起法
    // 甲己(0,5) → 甲子 → 时干起点=0
    // 乙庚(1,6) → 丙子 → 时干起点=2
    // 丙辛(2,7) → 戊子 → 时干起点=4
    // 丁壬(3,8) → 庚子 → 时干起点=6
    // 戊癸(4,9) → 壬子 → 时干起点=8
    int hourGanBase;
    switch (dayGanIdx) {
      case 0: // 甲
      case 5: // 己
        hourGanBase = 0; // 甲
        break;
      case 1: // 乙
      case 6: // 庚
        hourGanBase = 2; // 丙
        break;
      case 2: // 丙
      case 7: // 辛
        hourGanBase = 4; // 戊
        break;
      case 3: // 丁
      case 8: // 壬
        hourGanBase = 6; // 庚
        break;
      case 4: // 戊
      case 9: // 癸
        hourGanBase = 8; // 壬
        break;
      default:
        hourGanBase = 0;
    }

    // 时干 = (base + shiChenIdx) % 10
    int hourGanIdx = (hourGanBase + shiChenIdx) % 10;
    String hourGan = tianGan[hourGanIdx];

    return '$hourGan$hourZhi';
  }

  /// 由日柱 + 时支推出完整时柱（五鼠遁）
  ///
  /// 干支排盘时用户只选时辰地支，时干由日干决定：
  /// 甲己日起甲子、乙庚日起丙子、丙辛日起戊子、丁壬日起庚子、戊癸日起壬子。
  static String hourGzFromZhi(String dayGz, String hourZhi) {
    if (dayGz.length < 1) return hourZhi;
    int dayGanIdx = tianGan.indexOf(dayGz[0]);
    int zhiIdx = diZhi.indexOf(hourZhi);
    if (dayGanIdx < 0 || zhiIdx < 0) return hourZhi;
    int hourGanIdx = ((dayGanIdx % 5) * 2 + zhiIdx) % 10;
    return '${tianGan[hourGanIdx]}$hourZhi';
  }

  /// 获取当前时辰
  static String getCurrentShiChen(DateTime dateTime) {
    int hour = dateTime.hour;
    int shiChenIdx;
    if (hour == 23 || hour == 0) {
      shiChenIdx = 0; // 子时 (23:00-00:59)
    } else {
      // 1-2点→丑(1), 3-4点→寅(2), 5-6点→卯(3)...
      // 公式: (hour - 1) / 2 + 1
      shiChenIdx = ((hour - 1) ~/ 2) + 1;
    }
    return diZhi[shiChenIdx];
  }

  /// 获取时辰名称
  static String getShiChenName(String zhi) {
    const Map<String, String> shiChenNames = {
      '子': '子时',
      '丑': '丑时',
      '寅': '寅时',
      '卯': '卯时',
      '辰': '辰时',
      '巳': '巳时',
      '午': '午时',
      '未': '未时',
      '申': '申时',
      '酉': '酉时',
      '戌': '戌时',
      '亥': '亥时',
    };
    return shiChenNames[zhi] ?? '';
  }
}