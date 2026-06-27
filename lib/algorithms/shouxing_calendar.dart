import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'constants.dart';

/// 节气数据（从JSON表加载）
class JieQiData {
  final String name;
  final int monthZhiIdx;
  final DateTime time;

  JieQiData({
    required this.name,
    required this.monthZhiIdx,
    required this.time,
  });

  factory JieQiData.fromJson(Map<String, dynamic> json) {
    return JieQiData(
      name: json['n'] as String,
      monthZhiIdx: json['m'] as int,
      time: DateTime.utc(
        json['y'] as int,
        json['M'] as int,
        json['d'] as int,
        json['h'] as int,
        json['min'] as int,
      ),
    );
  }

  String get monthZhi => diZhi[monthZhiIdx - 1];

  @override
  String toString() => '$name: $time → $monthZhi月';
}

/// 寿星万年历 — 24节气计算
/// 策略：内置查表优先 + 在线更新 + Meeus算法兜底
class ShouXingCalendar {
  /// 24节气名称
  static const List<String> jieQiNames = [
    '小寒', '大寒', '立春', '雨水', '惊蛰', '春分',
    '清明', '谷雨', '立夏', '小满', '芒种', '夏至',
    '小暑', '大暑', '立秋', '处暑', '白露', '秋分',
    '寒露', '霜降', '立冬', '小雪', '大雪', '冬至',
  ];

  /// 24节气对应的太阳黄经角度
  static const List<double> jieQiAngles = [
    285.0, 300.0, 315.0, 330.0, 345.0, 0.0,
    15.0, 30.0, 45.0, 60.0, 75.0, 90.0,
    105.0, 120.0, 135.0, 150.0, 165.0, 180.0,
    195.0, 210.0, 225.0, 240.0, 255.0, 270.0,
  ];

  /// 节气对应的月支索引
  static const List<int> jieQiToMonthZhi = [
    2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7,
    8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 1, 1,
  ];

  /// 内置节气表
  static Map<int, List<JieQiData>> _table = {};
  static int _minYear = 0;
  static int _maxYear = 0;
  static bool _initialized = false;

  /// 初始化节气表
  /// 优先加载高精度数据（2026-2030），再加载基础数据（1900-2100）
  static Future<void> init() async {
    if (_initialized) return;

    // 1. 尝试加载用户下载的新表（Documents目录）
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final userTableFile = File('${docDir.path}/jieqi_table.json');
      if (userTableFile.existsSync()) {
        final content = await userTableFile.readAsString();
        await _parseTable(content);
      }
    } catch (e) {
      // 文件不存在或读取失败，继续
    }

    // 2. 加载高精度节气数据（2026-2030）
    try {
      final content = await rootBundle.loadString('assets/jieqi_2026_2030.json');
      await _parseHighPrecisionTable(content);
    } catch (e) {
      // 高精度数据加载失败
    }

    // 3. 加载基础节气数据（1900-2100）作为兜底
    if (_table.isEmpty) {
      try {
        final content = await rootBundle.loadString('assets/jieqi_table.json');
        await _parseTable(content);
      } catch (e) {
        // 内置表加载失败，将依赖 Meeus 兜底计算
      }
    }

    _initialized = true;
  }

  /// 解析高精度节气表（新格式）
  static Future<void> _parseHighPrecisionTable(String content) async {
    final json = jsonDecode(content) as Map<String, dynamic>;

    for (final entry in json.entries) {
      // 跳过备注字段
      if (entry.key == '备注' || entry.key == '时区') continue;

      final year = int.parse(entry.key);
      final list = (entry.value as List).map((e) {
        final item = e as Map<String, dynamic>;
        // 解析时间字符串 "HH:MM"
        final timeStr = item['time'] as String;
        final timeParts = timeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // 获取月支索引
        final jieQiName = item['name'] as String;
        final jieQiIdx = jieQiNames.indexOf(jieQiName);
        final monthZhiIdx = jieQiIdx >= 0 ? jieQiToMonthZhi[jieQiIdx] : 1;

        return JieQiData(
          name: jieQiName,
          monthZhiIdx: monthZhiIdx,
          time: DateTime.utc(
            year,
            item['month'] as int,
            item['day'] as int,
            hour,
            minute,
          ),
        );
      }).toList();

      // 覆盖或添加到表中
      _table[year] = list;
    }

    if (_table.isNotEmpty) {
      final years = _table.keys.toList();
      _minYear = years.reduce(min);
      _maxYear = years.reduce(max);
    }
  }

  /// 解析JSON节气表
  static Future<void> _parseTable(String content) async {
    final json = jsonDecode(content) as Map<String, dynamic>;
    _table.clear();

    for (final entry in json.entries) {
      final year = int.parse(entry.key);
      final list = (entry.value as List)
          .map((e) => JieQiData.fromJson(e as Map<String, dynamic>))
          .toList();
      _table[year] = list;
    }

    if (_table.isNotEmpty) {
      final years = _table.keys.toList();
      _minYear = years.reduce(min);
      _maxYear = years.reduce(max);
    }
  }

  /// 检查是否需要更新节气表
  static bool needsUpdate(int year) => year > _maxYear || year < _minYear;

  /// 下载并更新节气表
  static Future<void> downloadUpdate(String url) async {
    // TODO: 实现 HTTP 下载并写入 Documents 目录
    // http.get(url) → 写到 Documents/jieqi_table.json
    // 重新调用 _parseTable
  }

  /// 获取指定年份的节气列表
  /// 优先查表，Meeus兜底
  static List<JieQiData> getJieQiList(int year) {
    if (_table.containsKey(year)) {
      return _table[year]!;
    }
    return _meeusCalculate(year);
  }

  /// Meeus算法兜底计算
  static List<JieQiData> _meeusCalculate(int year) {
    List<JieQiData> results = [];
    for (int i = 0; i < 24; i++) {
      double angle = jieQiAngles[i];
      double jd = findJdByAngle(year, angle);
      DateTime time = jdToDateTime(jd);
      results.add(JieQiData(
        name: jieQiNames[i],
        monthZhiIdx: jieQiToMonthZhi[i],
        time: time,
      ));
    }
    return results;
  }

  /// 获取指定节气时间
  static DateTime getJieQiTime(int year, int index) {
    final list = getJieQiList(year);
    return list[index].time;
  }

  /// 获取立春时间
  static DateTime getLichunTime(int year) => getJieQiTime(year, 2);

  /// 根据DateTime获取当前月支索引
  static int getMonthZhiIndex(DateTime dateTime) {
    int year = dateTime.year;
    final jieQiList = getJieQiList(year);

    for (int i = jieQiList.length - 1; i >= 0; i--) {
      if (dateTime.compareTo(jieQiList[i].time) >= 0) {
        return jieQiList[i].monthZhiIdx;
      }
    }
    return 1; // 小寒之前用子月
  }

  /// 判断是否在立春之前（用于年柱判定）
  static bool isBeforeLichun(DateTime dateTime) {
    DateTime lichun = getLichunTime(dateTime.year);
    return dateTime.compareTo(lichun) < 0;
  }

  // === Meeus算法（保留作为兜底）===

  /// 儒略日转DateTime（UTC）
  static DateTime jdToDateTime(double jd) {
    double daysSinceJ2000 = jd - 2451545.0;
    DateTime j2000 = DateTime.utc(2000, 1, 1, 12, 0);
    int totalDays = daysSinceJ2000.floor();
    double fraction = daysSinceJ2000 - totalDays;
    int hours = (fraction * 24).floor();
    int minutes = ((fraction * 24 - hours) * 60).floor();
    return j2000.add(Duration(days: totalDays, hours: hours, minutes: minutes));
  }

  /// DateTime转儒略日
  static double dateTimeToJD(DateTime dt) {
    int year = dt.year;
    int month = dt.month;
    double day = dt.day + dt.hour / 24.0 + dt.minute / 1440.0;
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    int a = year ~/ 100;
    int b = 2 - a + a ~/ 4;
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day + b - 1524.5;
  }

  /// 牛顿迭代求解精确儒略日
  static double findJdByAngle(int year, double angle) {
    double jd = estimateJD(year, angle);
    for (int i = 0; i < 20; i++) {
      double lng = sunLongitude(jd);
      double diff = lng - angle;
      while (diff > 180) diff -= 360;
      while (diff < -180) diff += 360;
      if (diff.abs() < 0.0001) break;
      double lng2 = sunLongitude(jd + 0.001);
      double dailyMotion = (lng2 - lng) / 0.001;
      if (dailyMotion.abs() < 0.5) dailyMotion = 0.9856;
      jd -= diff / dailyMotion;
    }
    return jd;
  }

  /// 估计节气儒略日
  static double estimateJD(int year, double angle) {
    int month, day;
    if (angle == 270.0) { month = 12; day = 21; }
    else if (angle == 285.0) { month = 1; day = 6; }
    else if (angle == 300.0) { month = 1; day = 20; }
    else if (angle == 315.0) { month = 2; day = 4; }
    else if (angle == 330.0) { month = 2; day = 19; }
    else if (angle == 345.0) { month = 3; day = 6; }
    else if (angle == 0.0) { month = 3; day = 21; }
    else if (angle == 15.0) { month = 4; day = 5; }
    else if (angle == 30.0) { month = 4; day = 20; }
    else if (angle == 45.0) { month = 5; day = 6; }
    else if (angle == 60.0) { month = 5; day = 21; }
    else if (angle == 75.0) { month = 6; day = 6; }
    else if (angle == 90.0) { month = 6; day = 21; }
    else if (angle == 105.0) { month = 7; day = 7; }
    else if (angle == 120.0) { month = 7; day = 23; }
    else if (angle == 135.0) { month = 8; day = 8; }
    else if (angle == 150.0) { month = 8; day = 23; }
    else if (angle == 165.0) { month = 9; day = 8; }
    else if (angle == 180.0) { month = 9; day = 23; }
    else if (angle == 195.0) { month = 10; day = 8; }
    else if (angle == 210.0) { month = 10; day = 24; }
    else if (angle == 225.0) { month = 11; day = 8; }
    else if (angle == 240.0) { month = 11; day = 22; }
    else if (angle == 255.0) { month = 12; day = 7; }
    else { month = 1; day = 15; }
    return dateTimeToJD(DateTime.utc(year, month, day, 12, 0));
  }

  /// 太阳视黄经（Meeus公式）
  static double sunLongitude(double jd) {
    double T = (jd - 2451545.0) / 36525.0;
    double L0 = normalize360(280.46646 + 36000.76983 * T + 0.0003032 * T * T);
    double M = normalize360(357.52911 + 35999.05029 * T - 0.0001537 * T * T);
    double e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T;
    double Mrad = toRadians(M);
    double C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mrad)
             + (0.019993 - 0.000101 * T) * sin(2 * Mrad)
             + 0.000289 * sin(3 * Mrad);
    double sunLon = L0 + C;
    double omega = 125.04452 - 1934.136261 * T + 0.0020708 * T * T + T * T * T / 450000;
    double omegaRad = toRadians(normalize360(omega));
    double LsunRad = toRadians(L0);
    double Lmoon = 218.3165 + 481267.8813 * T;
    double LmoonRad = toRadians(normalize360(Lmoon));
    double dPsi = -17.20 * sin(omegaRad) - 1.32 * sin(2 * LsunRad)
                 - 0.23 * sin(2 * LmoonRad) + 0.21 * sin(2 * omegaRad);
    sunLon += dPsi / 3600.0;
    double k = 20.4955;
    double abberation = k / (1 + e * cos(Mrad));
    sunLon -= abberation / 3600.0;
    return normalize360(sunLon);
  }

  static double normalize360(double angle) {
    angle = angle % 360;
    if (angle < 0) angle += 360;
    return angle;
  }

  static double toRadians(double degrees) => degrees * pi / 180.0;
}

/// 保留旧类名兼容
class JieQiResult extends JieQiData {
  final double angle;
  final double jd;

  JieQiResult({
    required super.name,
    required this.angle,
    required this.jd,
    required super.time,
    required super.monthZhiIdx,
  });
}