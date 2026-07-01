import 'dart:convert';
import '../models/divination_record.dart';
import '../algorithms/liuqin_config.dart';
import '../algorithms/constants.dart';

/// Markdown 导出/导入帮助类
class ExportHelper {
  /// 导出单条记录为 Markdown
  static String exportToMarkdown(DivinationRecord record, {String? exporterName}) {
    final buffer = StringBuffer();

    buffer.writeln('# 六爻排盘记录');
    buffer.writeln();

    // 基本信息
    if (exporterName != null && exporterName.isNotEmpty) {
      buffer.writeln('**导出者**：$exporterName');
    }
    if (record.querentName.isNotEmpty) {
      buffer.writeln('**起卦人**：${record.querentName}${record.querentGender.isNotEmpty ? '（${record.querentGender}）' : ''}');
    }
    buffer.writeln('**起卦时间**：${record.formattedDivTime}');
    buffer.writeln('**干支**：${record.formattedGanZhi}');
    buffer.writeln('**旬空**：${record.xunKong}');
    if (record.question.isNotEmpty) {
      buffer.writeln('**所问**：${record.question}');
    }
    buffer.writeln();

    // 卦象信息
    buffer.writeln('## 本卦：${record.benGua.guaName} ${record.benGua.guaSymbol}');
    if (record.bianGua != null && record.hasDongYao()) {
      buffer.writeln('→ 变卦：${record.bianGua!.guaName} ${record.bianGua!.guaSymbol}');
    }
    buffer.writeln('**卦宫**：${record.benGua.gongName ?? ''}   **五行**：${record.benGua.guaWuXing ?? ''}');
    buffer.writeln();

    // 六爻详情表格
    buffer.writeln(_buildYaoTable(record));
    buffer.writeln();

    // 神煞
    buffer.writeln('**神煞**：');
    final shenshaParts = <String>[];
    if (record.shensha.tianYi.isNotEmpty) shenshaParts.add('天乙:${record.shensha.tianYi}');
    if (record.shensha.yiMa.isNotEmpty) shenshaParts.add('驿马:${record.shensha.yiMa}');
    if (record.shensha.huaGai.isNotEmpty) shenshaParts.add('华盖:${record.shensha.huaGai}');
    if (record.shensha.xianChi.isNotEmpty) shenshaParts.add('咸池:${record.shensha.xianChi}');
    if (record.shensha.tianYiShen.isNotEmpty) shenshaParts.add('天医:${record.shensha.tianYiShen}');
    if (record.shensha.luShen.isNotEmpty) shenshaParts.add('禄神:${record.shensha.luShen}');
    buffer.writeln(shenshaParts.join('  '));
    buffer.writeln();

    // 解卦笔记
    if (record.interpretation != null && record.interpretation!.isNotEmpty) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## 📝 解卦笔记');
      buffer.writeln();
      buffer.writeln(record.interpretation!);
    }

    // JSON 元数据（用于导入恢复，对阅读者不可见）
    buffer.writeln();
    buffer.writeln('<!-- LIUYAO_DATA:');
    buffer.writeln(jsonEncode(record.toJson()));
    buffer.writeln('LIYAO_DATA_END -->');

    return buffer.toString();
  }

  /// 导出多条记录为 Markdown
  static String exportMultiple(List<DivinationRecord> records) {
    final buffer = StringBuffer();

    buffer.writeln('# 六爻排盘记录集');
    buffer.writeln();
    buffer.writeln('共 ${records.length} 条记录');
    buffer.writeln();

    for (int i = 0; i < records.length; i++) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## 记录 ${i + 1}');
      buffer.writeln();
      buffer.write(exportToMarkdown(records[i]));
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 构建六爻表格
  static String _buildYaoTable(DivinationRecord record) {
    final buffer = StringBuffer();
    final gongWuXing = record.benGua.guaWuXing ?? '';

    // 从上爻到初爻排序
    final sortedLines = record.yaoLines.toList()
      ..sort((a, b) => b.position.compareTo(a.position));

    // 判断是否有动爻（决定是否显示变卦列）
    final hasDongYao = record.hasDongYao();

    // 表头
    if (hasDongYao) {
      buffer.writeln('| 六神 | 伏神 | 六亲 | 地支 | 世应 | 本卦 | 变卦 |');
      buffer.writeln('|------|------|------|------|------|------|------|');
    } else {
      buffer.writeln('| 六神 | 伏神 | 六亲 | 地支 | 世应 | 本卦 |');
      buffer.writeln('|------|------|------|------|------|------|');
    }

    // 表格内容
    for (var yao in sortedLines) {
      final parts = <String>[];

      // 六神（首字）
      parts.add((yao.liuShen?.isNotEmpty ?? false) ? yao.liuShen![0] : '');

      // 伏神：六亲首字+地支（动态计算）
      if (yao.fuShen != null && yao.fuShen!.isNotEmpty) {
        String fuShenLiuQin = LiuQinConfig.getLiuQin(gongWuXing, diZhiWuXing[yao.fuShen] ?? '');
        String fuShenDisplay = fuShenLiuQin.isNotEmpty ? fuShenLiuQin[0] : '';
        fuShenDisplay += yao.fuShen!;
        parts.add(fuShenDisplay);
      } else {
        parts.add('');
      }

      // 六亲（完整两个字）
      parts.add(yao.liuQin ?? '');

      // 地支+五行（紧凑，不留空）
      if (yao.isXunKong == true) {
        parts.add('*${yao.ganZhi ?? ''}${yao.wuXing ?? ''}*');
      } else {
        parts.add('${yao.ganZhi ?? ''}${yao.wuXing ?? ''}');
      }

      // 世应
      parts.add(yao.isShi == true ? '世' : (yao.isYing == true ? '应' : ''));

      // 本卦爻象
      parts.add(yao.yaoTypeSymbol);

      // 变卦（仅动爻有，显示爻象+六亲+地支五行）
      if (hasDongYao) {
        if (yao.isDong) {
          String bianSymbol = yao.isYang ? '▅▅▅▅▅' : '▅▅  ▅▅';
          String bianInfo = '';
          if (yao.bianLiuQin != null && yao.bianLiuQin!.isNotEmpty) {
            bianInfo = yao.bianLiuQin!;
            if (yao.bianGanZhi != null) {
              bianInfo += yao.bianGanZhi!;
              if (yao.bianWuXing != null) {
                bianInfo += yao.bianWuXing!;
              }
            }
          } else if (yao.bianGanZhi != null) {
            bianInfo = yao.bianGanZhi!;
            if (yao.bianWuXing != null) {
              bianInfo += yao.bianWuXing!;
            }
          }
          parts.add(bianInfo.isNotEmpty ? '$bianSymbol $bianInfo' : bianSymbol);
        } else {
          parts.add('');
        }
      }

      buffer.writeln('| ${parts.join(' | ')} |');
    }

    return buffer.toString();
  }

  /// 从 Markdown 文本中解析导入排盘记录
  /// 返回解析出的记录列表和导出者信息
  static ({List<DivinationRecord> records, String? exporterName}) importFromMarkdown(String markdown) {
    final records = <DivinationRecord>[];
    String? exporterName;

    // 提取导出者
    final exporterMatch = RegExp(r'\*\*导出者\*\*[：:]\s*(.+)').firstMatch(markdown);
    if (exporterMatch != null) {
      exporterName = exporterMatch.group(1)?.trim();
    }

    // 提取 JSON 元数据（支持单条和多条）
    final dataMatches = RegExp(r'<!-- LIUYAO_DATA:\n([\s\S]*?)\nLIYAO_DATA_END -->').allMatches(markdown);
    for (final match in dataMatches) {
      try {
        final jsonStr = match.group(1)?.trim();
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          records.add(DivinationRecord.fromJson(jsonMap));
        }
      } catch (_) {
        // 跳过无法解析的数据
      }
    }

    return (records: records, exporterName: exporterName);
  }

  /// 获取导出文件名（单条记录）
  static String getFileName(DivinationRecord record) {
    final dateStr = '${record.divTime.year}${record.divTime.month.toString().padLeft(2, '0')}${record.divTime.day.toString().padLeft(2, '0')}';
    final guaName = record.benGua.guaName.replaceAll(' ', '_');
    return '六爻_${dateStr}_${guaName}.md';
  }

  /// 获取导出文件名（多条记录）
  static String getBatchFileName(int count) {
    final dateStr = DateTime.now().toString().substring(0, 10);
    return '六爻记录集_${dateStr}_${count}条.md';
  }
}