/// 排盘文字解析器
/// 从OCR识别的文字中解析排盘数据
///
/// 简化识别策略：
/// 1. 只需识别卦名（本卦、变卦）和日柱干支
/// 2. 其他信息（六爻、六亲、六神、神煞等）通过现有算法自动推算
/// 3. 动爻信息可以从图片中识别或手动指定
///
/// OCR容错处理：
/// - "巳"可能被识别为"已"
/// - "问"可能被识别为"间"
/// - 干支格式可能有多种写法

import '../models/image_recognition_result.dart';
import '../algorithms/constants.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 排盘解析器
class PaipanParser {
  // 常量定义
  static const List<String> _diZhi = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'
  ];

  static const List<String> _tianGan = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'
  ];

  // 六十甲子列表（用于干支验证和兜底匹配）
  static final List<String> _ganZhi60List = ganzhi60.toList();

  // OCR常见误识别映射
  static const Map<String, String> _ocrCorrectionMap = {
    '已': '巳',  // 巳常被识别为已
    '间': '问',  // 问常被识别为间
    '后': '姤',  // 姤常被识别为后
    '末': '未',  // 未常被识别为末
    '末位': '未位',
  };

  // 64卦名称（按八宫排列）
  // 八宫系统：每宫8卦，共64卦，无重复
  static const Map<String, int> _guaIndexMap = {
    // 乾宫 (纯乾卦及变卦)
    '乾为天': 1, '天风姤': 2, '天山遁': 3, '天地否': 4,
    '风地观': 5, '山地剥': 6, '火地晋': 7, '火天大有': 8,
    // 坎宫 (纯坎卦及变卦)
    '坎为水': 9, '水泽节': 10, '水雷屯': 11, '水火既济': 12,
    '泽火革': 13, '雷火丰': 14, '地火明夷': 15, '地水师': 16,
    // 艮宫 (纯艮卦及变卦)
    '艮为山': 17, '山火贲': 18, '山天大畜': 19, '山泽损': 20,
    '火泽睽': 21, '天泽履': 22, '风泽中孚': 23, '风山渐': 24,
    // 震宫 (纯震卦及变卦)
    '震为雷': 25, '雷地豫': 26, '雷水解': 27, '雷风恒': 28,
    '地风升': 29, '水风井': 30, '泽风大过': 31, '泽雷随': 32,
    // 巽宫 (纯巽卦及变卦)
    '巽为风': 33, '风天小畜': 34, '风火家人': 35, '风雷益': 36,
    '天雷无妄': 37, '火雷噬嗑': 38, '山雷颐': 39, '山风蛊': 40,
    // 离宫 (纯离卦及变卦)
    '离为火': 41, '火山旅': 42, '火风鼎': 43, '火水未济': 44,
    '山水蒙': 45, '风水涣': 46, '天水讼': 47, '天火同人': 48,
    // 坤宫 (纯坤卦及变卦)
    '坤为地': 49, '地雷复': 50, '地泽临': 51, '地天泰': 52,
    '雷天大壮': 53, '泽天夬': 54, '水天需': 55, '水地比': 56,
    // 兑宫 (纯兑卦及变卦)
    '兑为泽': 57, '泽山咸': 58, '泽地萃': 59, '泽水困': 60,
    '山水蹇': 61, '地山谦': 62, '雷山小过': 63, '雷泽归妹': 64,
    // 简称（常用单字名）
    '乾': 1, '姤': 2, '遁': 3, '否': 4,
    '观': 5, '剥': 6, '晋': 7, '大有': 8,
    '坎': 9, '节': 10, '屯': 11, '既济': 12,
    '革': 13, '丰': 14, '明夷': 15, '师': 16,
    '艮': 17, '贲': 18, '大畜': 19, '损': 20,
    '睽': 21, '履': 22, '中孚': 23, '渐': 24,
    '震': 25, '豫': 26, '解': 27, '恒': 28,
    '升': 29, '井': 30, '大过': 31, '随': 32,
    '巽': 33, '小畜': 34, '家人': 35, '益': 36,
    '无妄': 37, '噬嗑': 38, '颐': 39, '蛊': 40,
    '离': 41, '旅': 42, '鼎': 43, '未济': 44,
    '蒙': 45, '涣': 46, '讼': 47, '同人': 48,
    '坤': 49, '复': 50, '临': 51, '泰': 52,
    '大壮': 53, '夬': 54, '需': 55, '比': 56,
    '兑': 57, '咸': 58, '萃': 59, '困': 60,
    '蹇': 61, '谦': 62, '小过': 63, '归妹': 64,
    // 其他常见写法/异体字
    '天风后': 2, '天山遯': 3, '天地否闭': 4,
    '地雷复卦': 50, '泽天夬卦': 54,
  };

  /// 解析OCR识别的文字
  ///
  /// [rawText] - OCR识别的全部文字
  /// [blocks] - 文字块信息（包含位置）
  ImageRecognitionResult parse(String rawText, List<TextBlock> blocks) {
    try {
      // 首先对OCR文本进行校正
      String correctedText = _correctOcrErrors(rawText);

      // 核心识别字段
      String? yearGanZhi;
      String? monthGanZhi;
      String? dayGanZhi;  // 最重要，用于排纳甲
      String? hourGanZhi;
      String? benGuaName;
      String? bianGuaName;
      List<int>? dongYaoPositions;
      String? gender;
      String? question;

      // ========== 1. 识别干支信息 ==========

      // 格式0: "干支:乙巳年己丑月 乙酉日己卯时" (易青岚排盘格式)
      final ganZhiPattern0 = RegExp(
        r'干支[:：]\s*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])年'
        r'\s*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])月\s*'
        r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])日'
        r'\s*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])时'
      );
      var match = ganZhiPattern0.firstMatch(correctedText);
      if (match != null) {
        yearGanZhi = _correctGanZhi(match.group(1)!);
        monthGanZhi = _correctGanZhi(match.group(2)!);
        dayGanZhi = _correctGanZhi(match.group(3)!);
        hourGanZhi = _correctGanZhi(match.group(4)!);
      }

      // 格式1: "乙巳年 己丑月 乙酉日 己卯时" (空格分隔)
      if (dayGanZhi == null) {
        final ganZhiPattern1 = RegExp(
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])年\s*'
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])月\s*'
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])日\s*'
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])时'
        );
        match = ganZhiPattern1.firstMatch(correctedText);
        if (match != null) {
          yearGanZhi = _correctGanZhi(match.group(1)!);
          monthGanZhi = _correctGanZhi(match.group(2)!);
          dayGanZhi = _correctGanZhi(match.group(3)!);
          hourGanZhi = _correctGanZhi(match.group(4)!);
        }
      }

      // 格式2: 单独查找干支组合（带年月日时标记）
      if (dayGanZhi == null) {
        // 查找所有干支组合及其位置（包括"已"作为"巳"的误识别）
        final gzPattern = RegExp(r'[甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已]');

        // 查找带标记的干支
        for (final gzMatch in gzPattern.allMatches(correctedText)) {
          final start = gzMatch.start;
          final end = gzMatch.end;
          // 查找前后文字判断是年月日时
          final beforeStart = start > 10 ? start - 10 : 0;
          final afterEnd = end + 10 < correctedText.length ? end + 10 : correctedText.length;
          final context = correctedText.substring(beforeStart, afterEnd);

          final gz = _correctGanZhi(gzMatch.group(0)!);
          if (context.contains('年') && !context.contains('月') && !context.contains('日')) {
            yearGanZhi = gz;
          } else if (context.contains('月') && !context.contains('年') && !context.contains('日')) {
            monthGanZhi = gz;
          } else if (context.contains('日') && !context.contains('月')) {
            dayGanZhi = gz;
          } else if (context.contains('时') && !context.contains('日')) {
            hourGanZhi = gz;
          }
        }
      }

      // 格式3: 查找"日柱"、"日辰"关键字
      if (dayGanZhi == null) {
        final dayPattern = RegExp(r'(日柱|日辰)[:：\s]*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])');
        match = dayPattern.firstMatch(correctedText);
        if (match != null) {
          dayGanZhi = _correctGanZhi(match.group(2)!);
        }
      }

      // 格式4: 使用六十甲子列表 + 带后缀(年/月/日/时)的精确匹配
      // 策略：先找"XX年""XX月""XX日""XX时"这种明确带后缀的干支组合，
      // 再与六十甲子表比对验证，确保四柱分配准确
      if (dayGanZhi == null || yearGanZhi == null || monthGanZhi == null || hourGanZhi == null) {
        // 匹配带后缀的干支：XX年、XX月、XX日、XX时（含误识别校正）
        final gzWithSuffix = RegExp(
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已末])\s*([年y月r日d时h])'
        );

        for (final m in gzWithSuffix.allMatches(correctedText)) {
          String candidate = m.group(1)!;
          final suffix = m.group(2)!;

          // 校正常见误识别
          candidate = candidate
              .replaceAll('已', '巳')
              .replaceAll('末', '未');

          // 验证是否在六十甲子表中
          if (!_ganZhi60List.contains(candidate)) continue;

          switch (suffix) {
            case '年':
              yearGanZhi ??= candidate;
            case '月':
              monthGanZhi ??= candidate;
            case '日':
              dayGanZhi ??= candidate;
            case '时':
              hourGanZhi ??= candidate;
          }
        }
      }

      // ========== 2. 识别卦名（支持模糊匹配）==========

      /// 计算两个字符串的逐字符匹配率（按位置比较）
      double _charMatchRate(String a, String b) {
        if (a.isEmpty || b.isEmpty) return 0;
        final len = a.length < b.length ? a.length : b.length;
        int matched = 0;
        for (int i = 0; i < len; i++) {
          if (a[i] == b[i]) matched++;
        }
        return matched / (a.length > b.length ? a.length : b.length);
      }

      /// 在文本中搜索卦名（全称>别名>简写>模糊）
      List<Map<String, dynamic>> _findGuaNames(String text) {
        final fullResults = <Map<String, dynamic>>[];    // 3字以上精确
        final aliasResults = <Map<String, dynamic>>[];   // 别名精确
        final shortResults = <Map<String, dynamic>>[];   // 1-2字精确（仅兜底）
        final fuzzyResults = <Map<String, dynamic>>[];   // 模糊匹配
        final seen = <String>{};

        for (final entry in _guaIndexMap.entries) {
          final guaName = entry.key;
          if (seen.contains(guaName)) continue;
          seen.add(guaName);
          if (guaName.length < 1) continue;

          int idx = text.indexOf(guaName);
          if (idx != -1) {
            if (guaName.length >= 3) {
              fullResults.add({'name': guaName, 'index': idx, 'score': 1.0});
            } else {
              // 1-2字简写暂存，仅当无全称匹配时才使用
              shortResults.add({'name': guaName, 'index': idx, 'score': 1.0});
            }
            continue;
          }

          // 3字以上卦名的模糊匹配（仅在无精确匹配时兜底）
          if (guaName.length >= 3) {
            for (int i = 0; i <= text.length - guaName.length; i++) {
              final segment = text.substring(i, i + guaName.length);
              final rate = _charMatchRate(segment, guaName);
              if (rate >= 0.66 && rate < 1.0) {
                fuzzyResults.add({'name': guaName, 'index': i, 'score': rate});
                break;
              }
            }
          }
        }

        // 优先使用全称精确匹配
        if (fullResults.isNotEmpty) {
          fullResults.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
          return fullResults;
        }

        // 有模糊匹配时优先返回模糊结果（比简写更可靠）
        if (fuzzyResults.isNotEmpty) {
          fuzzyResults.sort((a, b) {
            final posCmp = (a['index'] as int).compareTo(b['index'] as int);
            if (posCmp != 0) return posCmp;
            return (b['score'] as double).compareTo(a['score'] as double);
          });
          return fuzzyResults;
        }

        // 最后才用简写兜底
        if (shortResults.isNotEmpty) {
          shortResults.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
          return shortResults;
        }

        return [];
      }

      // 执行卦名匹配（精确优先，模糊兜底）
      final foundGuas = _findGuaNames(correctedText);

      // 取前2个不同位置的卦名作为本卦和变卦
      if (foundGuas.isNotEmpty) {
        benGuaName = foundGuas.first['name'] as String;
        if (foundGuas.length > 1) {
          bianGuaName = foundGuas[1]['name'] as String;
        }
      }

      // ========== 3. 识别动爻 ==========

      // 查找动爻标记（○、动、老阳、老阴、X）
      final dongPositions = <int>[];

      // 方法1: 查找"某爻动"的文字
      final dongPattern1 = RegExp(r'([一二三四五六上初])[爻]\s*[动○X]');
      for (final m in dongPattern1.allMatches(correctedText)) {
        final pos = _convertYaoNameToPosition(m.group(1)!);
        if (pos != null && !dongPositions.contains(pos)) {
          dongPositions.add(pos);
        }
      }

      // 方法2: 查找老阳、老阴标记或X符号
      // 从OCR文本中查找X标记（通常表示动爻）

      if (dongPositions.isNotEmpty) {
        dongYaoPositions = dongPositions;
      }

      // ========== 4. 识别公历时间 ==========

      DateTime? gregorianTime;

      // 格式1: "公历：2026年6月27日 14:30"
      final gregPattern1 = RegExp(
        r'公历[:：\s]*(\d{4})年(\d{1,2})月(\d{1,2})日[^\d]*(\d{1,2})[:时点](\d{1,2})?分?'
      );
      match = gregPattern1.firstMatch(correctedText);
      if (match != null) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
        gregorianTime = DateTime(year, month, day, hour, minute);
      }

      // 格式2: "公历：2026年6月27日"（无时分）
      if (gregorianTime == null) {
        final gregPattern2 = RegExp(r'公历[:：\s]*(\d{4})年(\d{1,2})月(\d{1,2})日');
        match = gregPattern2.firstMatch(correctedText);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          gregorianTime = DateTime(year, month, day);
        }
      }

      // 格式3: "2026-06-27 14:30" 或 "2026/6/27 14:30"
      if (gregorianTime == null) {
        final gregPattern3 = RegExp(
          r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})日?[^\d]*(\d{1,2})[:时点](\d{1,2})?'
        );
        match = gregPattern3.firstMatch(correctedText);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
          gregorianTime = DateTime(year, month, day, hour, minute);
        }
      }

      // 格式4: 直接查找年月日时分格式（无"公历"标记）
      if (gregorianTime == null) {
        final gregPattern4 = RegExp(
          r'(\d{4})年(\d{1,2})月(\d{1,2})日[^\d]*(\d{1,2})[:时点](\d{1,2})?[分]?'
        );
        match = gregPattern4.firstMatch(correctedText);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
          gregorianTime = DateTime(year, month, day, hour, minute);
        }
      }

      // ========== 5. 识别性别和问事 ==========

      // 性别识别 - 多种格式
      // 格式1: "性别：男" 或 "性别：女"
      final genderPattern1 = RegExp(r'性别[:：]\s*(男|女)');
      match = genderPattern1.firstMatch(correctedText);
      if (match != null) {
        gender = match.group(1);
      }

      // 格式2: "男占" 或 "女占"
      if (gender == null) {
        final genderPattern2 = RegExp(r'(男|女)占');
        match = genderPattern2.firstMatch(correctedText);
        if (match != null) {
          gender = match.group(1);
        }
      }

      // 格式3: "占卜人：男" 或 "求测人：女"
      if (gender == null) {
        final genderPattern3 = RegExp(r'(占卜人|求测人|起卦人)[:：]\s*(男|女)');
        match = genderPattern3.firstMatch(correctedText);
        if (match != null) {
          gender = match.group(2);
        }
      }

      // 格式4: 单独的"男"或"女"字（排除卦象中的乾男、坤女）
      if (gender == null) {
        // 查找"男"字，排除乾男
        if (correctedText.contains('男')) {
          final malePattern = RegExp(r'[^\u4e00-\u9fa5]男[^\u4e00-\u9fa5]|^男|男$');
          if (malePattern.hasMatch(correctedText) && !correctedText.contains('乾男')) {
            gender = '男';
          }
        }
        // 查找"女"字，排除坤女
        if (gender == null && correctedText.contains('女')) {
          final femalePattern = RegExp(r'[^\u4e00-\u9fa5]女[^\u4e00-\u9fa5]|^女|女$');
          if (femalePattern.hasMatch(correctedText) && !correctedText.contains('坤女')) {
            gender = '女';
          }
        }
      }

      // 占问内容识别
      // 策略：从"占问/问念/背景"关键字开始，到"公历/卦名/干支"结束

      /// 提取关键字后面的内容，直到遇到结束标记
      String? extractQuestionAfter(String text, int kwStart, String kw) {
        final startIdx = kwStart + kw.length;
        String after = text.substring(startIdx);

        // 去除开头的冒号、空格、换行
        int contentStart = 0;
        while (contentStart < after.length &&
            (after[contentStart] == ':' ||
                after[contentStart] == '：' ||
                after[contentStart] == ' ' ||
                after[contentStart] == '\t' ||
                after[contentStart] == '\n')) {
          contentStart++;
        }
        if (contentStart >= after.length) return null;
        after = after.substring(contentStart);

        // 查找结束位置
        final endMarkers = ['公历', '年柱', '月柱', '日柱', '时柱',
            '干支', '本卦', '变卦', '起卦时间', '旬空'];
        int endPos = after.length;
        for (final marker in endMarkers) {
          final idx = after.indexOf(marker);
          if (idx != -1 && idx < endPos) endPos = idx;
        }

        // 干支年份作为结束标记
        final gzPattern = RegExp(r'[甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已末]年');
        final gzMatch = gzPattern.firstMatch(after);
        if (gzMatch != null && gzMatch.start < endPos) endPos = gzMatch.start;

        return after.substring(0, endPos).trim();
      }

      // 查找所有关键字位置
      final qKeywords = ['占问', '问念', '占间', '问事', '求测', '测事', '问题'];
      final bgKeywords = ['背景', '背景情况'];

      // 1. 优先提取问念/占问内容
      int? qKeywordStart;
      String? qKeywordFound;
      for (final kw in qKeywords) {
        final idx = correctedText.indexOf(kw);
        if (idx != -1) {
          qKeywordStart = idx;
          qKeywordFound = kw;
          break;
        }
      }

      if (qKeywordStart != null) {
        question = extractQuestionAfter(correctedText, qKeywordStart, qKeywordFound!);
      }

      // 2. 提取背景内容，拼接到问念后面
      String? backgroundContent;
      for (final kw in bgKeywords) {
        final idx = correctedText.indexOf(kw);
        if (idx != -1) {
          // 跳过作为问念结束标记的情况（背景在问念附近时不重复提取）
          if (qKeywordFound != null && (idx - (qKeywordStart ?? 0)).abs() < 5) continue;
          final bg = extractQuestionAfter(correctedText, idx, kw);
          if (bg != null && bg.isNotEmpty) {
            backgroundContent = bg;
            break;
          }
        }
      }

      // 3. 如有背景内容，拼接到问念后面
      if (backgroundContent != null && backgroundContent.isNotEmpty) {
        if (question != null && question.isNotEmpty) {
          question = '$question（背景：$backgroundContent）';
        } else {
          question = backgroundContent;
        }
      }

      // 方法3: 原有的简单正则匹配作为后备
      if (question == null || question.isEmpty) {
        final qPatternFallback = RegExp(
            r'(占问|问念|占间|问事|求测|测事|问题)[:：]\s*(.{2,100}?)[\n\r]');
        match = qPatternFallback.firstMatch(correctedText);
        if (match != null) {
          question = match.group(2)?.trim();
        }
      }

      // 最后兜底：查找任何包含"问"字的关键词
      if (question == null || question.isEmpty) {
        final qPatternAny = RegExp(
            r'[^问](问)[:：\s]*(\S[^]{2,60}?)[\n\r]');
        match = qPatternAny.firstMatch(correctedText);
        if (match != null) {
          question = match.group(2)?.trim();
        }
      }

      // ========== 6. 识别旬空（日空） ==========

      List<String>? xunKong;
      // 格式: "日空:午、末" 或 "旬空:午、末"
      final xunKongPattern = RegExp(r'(日空|旬空)[:：]\s*([子丑寅卯辰巳午未申酉戌亥、，]+)');
      match = xunKongPattern.firstMatch(correctedText);
      if (match != null) {
        final xunKongText = match.group(2)!;
        // 提取地支
        xunKong = [];
        for (final zhi in _diZhi) {
          if (xunKongText.contains(zhi)) {
            xunKong.add(zhi);
          }
        }
      }

      // ========== 构建结果 ==========

      final data = ParsedDivinationData(
        gender: gender,
        question: question,
        gregorianTime: gregorianTime,
        lunarTime: null,  // 农历时间通常与干支一起标注，暂不识别
        yearGanZhi: yearGanZhi,
        monthGanZhi: monthGanZhi,
        dayGanZhi: dayGanZhi,
        hourGanZhi: hourGanZhi,
        benGuaName: benGuaName,
        bianGuaName: bianGuaName,
        dongYaoPositions: dongYaoPositions,
        // 旬空从OCR识别，如果没有识别到则由算法计算
        xunKong: xunKong,
        // 六爻数据将由校正计算自动生成
        liuShen: null,  // 将由LiuShenConfig根据日干计算
        liuQin: null,   // 将由LiuQinConfig根据卦宫五行和地支计算
        diZhi: null,    // 将由NajiaConfig根据卦和爻位计算
        shiPosition: null,  // 将由ShiYingConfig根据卦计算
        yingPosition: null, // 将由ShiYingConfig根据卦计算
        shenSha: null,      // 将由ShenshaCalculator根据干支计算
      );

      // 计算置信度（基于核心字段是否识别成功）
      final coreFields = [
        dayGanZhi != null,
        benGuaName != null,
        gregorianTime != null,
        question != null,
        gender != null,
      ];
      final filledCount = coreFields.where((v) => v).length;
      final confidence = filledCount / coreFields.length;

      // 检查缺失的核心字段
      final missingFields = <String>[];
      if (dayGanZhi == null) missingFields.add('日柱干支');
      if (benGuaName == null) missingFields.add('本卦卦名');
      if (gregorianTime == null) missingFields.add('公历时间');
      if (question == null) missingFields.add('占问内容');
      if (gender == null) missingFields.add('性别');

      return ImageRecognitionResult.success(
        data: data,
        rawText: rawText,
        confidence: confidence,
        needsConfirmation: missingFields.isNotEmpty ? missingFields : null,
      );

    } catch (e) {
      return ImageRecognitionResult.failure('解析失败: $e');
    }
  }

  /// 将爻名称转换为位置数字
  int? _convertYaoNameToPosition(String name) {
    switch (name) {
      case '初':
        return 1;
      case '一':
        return 1;
      case '二':
        return 2;
      case '三':
        return 3;
      case '四':
        return 4;
      case '五':
        return 5;
      case '六':
        return 6;
      case '上':
        return 6;
      default:
        return null;
    }
  }

  /// 获取所有支持的卦名列表（用于显示）
  static List<String> getSupportedGuaNames() {
    return _guaIndexMap.keys.toList();
  }

  /// 校正OCR常见误识别
  String _correctOcrErrors(String text) {
    String corrected = text;
    for (final entry in _ocrCorrectionMap.entries) {
      corrected = corrected.replaceAll(entry.key, entry.value);
    }
    return corrected;
  }

  /// 校正单个干支中的误识别（如"已"→"巳")
  String _correctGanZhi(String ganZhi) {
    if (ganZhi.length != 2) return ganZhi;
    final gan = ganZhi[0];
    final zhi = ganZhi[1];
    // 校正地支中的误识别（已→巳）
    if (zhi == '已') return '$gan巳';
    return ganZhi;
  }
}

/// String扩展方法
extension StringExtension on String {
  /// 查找第一个非分隔符字符的索引
  /// 分隔符包括：冒号（中英文）、空格、制表符
  int indexOfFirstNonDelimiter() {
    for (int i = 0; i < length; i++) {
      final char = this[i];
      if (char != ':' && char != '：' && char != ' ' && char != '\t') {
        return i;
      }
    }
    return -1;  // 全部都是分隔符
  }
}