import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/divination_record.dart';
import '../providers/divination_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/yao_table.dart';
import '../widgets/yao_relations_painter.dart';
import '../widgets/shensha_card.dart';
import '../algorithms/dizhi_quantification.dart';
import '../algorithms/dizhi_relations.dart';
import '../algorithms/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../algorithms/lunar_calendar.dart';
import '../algorithms/shouxing_calendar.dart';
import '../providers/settings_provider.dart';
import '../utils/export_helper.dart';
import '../models/app_settings.dart';

/// 解卦结果页面（增强版）
/// 支持数字量化、冲合生克关系显示
/// 从历史记录打开时可传入 record 参数
class ResultScreen extends StatefulWidget {
  final DivinationRecord? record;

  const ResultScreen({super.key, this.record});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late TextEditingController _interpretationController;
  bool _isEditing = false;
  int? _savedRecordId;

  // 开关状态
  bool _showQuantification = false; // 数字量化
  bool _showChong = false;          // 冲
  bool _showHe = false;             // 合
  bool _showSheng = false;          // 生
  bool _showKe = false;             // 克
  bool _showSanHe = false;          // 三合局

  @override
  void initState() {
    super.initState();
    _interpretationController = TextEditingController(
      text: widget.record?.interpretation ?? '',
    );
  }

  @override
  void dispose() {
    _interpretationController.dispose();
    super.dispose();
  }

  /// 计算量化值
  List<QuantificationResult> _calculateQuantification(DivinationRecord record) {
    // 提取月建和日辰地支
    final monthZhi = _extractDiZhi(record.monthGz);
    final dayZhi = _extractDiZhi(record.dayGz);

    // 提取六爻地支（从初爻到上爻）
    final yaoDiZhiList = record.yaoLines
        .map((y) => y.ganZhi ?? '')
        .where((z) => z.isNotEmpty)
        .toList();

    return DiZhiQuantification.calculateAll(yaoDiZhiList, monthZhi, dayZhi);
  }

  /// 提取地支（从干支字符串，如"丙寅"提取"寅"）
  String _extractDiZhi(String ganZhi) {
    if (ganZhi.length >= 2) {
      return ganZhi.substring(1);
    }
    return ganZhi;
  }

  /// 计算爻关系
  List<YaoRelation> _calculateRelations(DivinationRecord record) {
    final relations = <YaoRelation>[];
    final monthZhi = _extractDiZhi(record.monthGz);
    final dayZhi = _extractDiZhi(record.dayGz);

    // 1. 月建、日辰对六爻的关系
    for (final yao in record.yaoLines) {
      if (yao.ganZhi == null || yao.ganZhi!.isEmpty) continue;
      final yaoZhi = yao.ganZhi!;

      // 月建关系
      if (_showChong && DiZhiRelations.isChong(monthZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationChong,
          description: '月冲',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showHe && DiZhiRelations.isHe(monthZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationHe,
          description: '月合',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showSheng && DiZhiRelations.isSheng(monthZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationSheng,
          description: '月生',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showKe && DiZhiRelations.isKe(monthZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationKe,
          description: '月克',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      }

      // 日辰关系
      if (_showChong && DiZhiRelations.isChong(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationChong,
          description: '日冲',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showHe && DiZhiRelations.isHe(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationHe,
          description: '日合',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showSheng && DiZhiRelations.isSheng(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationSheng,
          description: '日生',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showKe && DiZhiRelations.isKe(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationKe,
          description: '日克',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
        ));
      }
    }

    // 2. 动爻对静爻（含伏藏）的关系
    final dongYaos = record.yaoLines.where((y) => y.isDong).toList();
    final jingYaos = record.yaoLines.where((y) => !y.isDong).toList();

    for (final dongYao in dongYaos) {
      if (dongYao.ganZhi == null || dongYao.ganZhi!.isEmpty) continue;
      final dongZhi = dongYao.ganZhi!;

      // 对静爻
      for (final jingYao in jingYaos) {
        if (jingYao.ganZhi == null || jingYao.ganZhi!.isEmpty) continue;
        final jingZhi = jingYao.ganZhi!;

        if (_showChong && DiZhiRelations.isChong(dongZhi, jingZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationChong,
            description: '动冲静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        } else if (_showHe && DiZhiRelations.isHe(dongZhi, jingZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationHe,
            description: '动合静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        } else if (_showSheng && DiZhiRelations.isSheng(dongZhi, jingZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationSheng,
            description: '动生静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        } else if (_showKe && DiZhiRelations.isKe(dongZhi, jingZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationKe,
            description: '动克静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        }
      }

      // 对伏神（如果有）- 只考虑冲合，不考虑生克
      for (final yao in record.yaoLines) {
        if (yao.fuShen != null && yao.fuShen!.isNotEmpty) {
          if (_showChong && DiZhiRelations.isChong(dongZhi, yao.fuShen!)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: yao.position,
              fromType: 'yao',
              toType: 'fu',
              relationType: DiZhiRelations.relationChong,
              description: '动冲伏',
              fromDiZhi: dongZhi,
              toDiZhi: yao.fuShen!,
            ));
          } else if (_showHe && DiZhiRelations.isHe(dongZhi, yao.fuShen!)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: yao.position,
              fromType: 'yao',
              toType: 'fu',
              relationType: DiZhiRelations.relationHe,
              description: '动合伏',
              fromDiZhi: dongZhi,
              toDiZhi: yao.fuShen!,
            ));
          }
          // 生克不考虑伏神
        }
      }
    }

    // 3. 变爻对动爻的关系
    if (record.bianGua != null) {
      for (final dongYao in dongYaos) {
        if (dongYao.bianGanZhi != null && dongYao.bianGanZhi!.isNotEmpty) {
          final bianZhi = dongYao.bianGanZhi!;
          final dongZhi = dongYao.ganZhi ?? '';

          if (dongZhi.isEmpty) continue;

          if (_showChong && DiZhiRelations.isChong(bianZhi, dongZhi)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationChong,
              description: '变冲动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          } else if (_showHe && DiZhiRelations.isHe(bianZhi, dongZhi)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationHe,
              description: '变合动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          } else if (_showSheng && DiZhiRelations.isSheng(bianZhi, dongZhi)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationSheng,
              description: '变生动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          } else if (_showKe && DiZhiRelations.isKe(bianZhi, dongZhi)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationKe,
              description: '变克动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          }
        }
      }
    }

    return relations;
  }

  @override
  Widget build(BuildContext context) {
    // 支持两种数据来源：直接传参（历史记录）或 Provider（新排盘）
    final record = widget.record ?? Provider.of<DivinationProvider>(context).record;
    final bool isHistoryView = widget.record != null;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('排盘结果')),
        body: const Center(
          child: Text('无排盘数据，请先进行起卦'),
        ),
      );
    }

    // 计算量化值
    final quantificationResults = _calculateQuantification(record);

    // 计算关系
    final relations = (_showChong || _showHe || _showSheng || _showKe)
        ? _calculateRelations(record)
        : <YaoRelation>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(isHistoryView ? '${record.benGua.guaName} ${record.benGua.guaSymbol}' : '排盘结果'),
        titleSpacing: 0,  // 紧凑标题间距
        toolbarHeight: 44,  // 减小 AppBar 高度
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportRecord(record),
            tooltip: '导出分享',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveRecord(record),
            tooltip: isHistoryView ? '更新解卦' : '保存记录',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          if (isHistoryView)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteRecord(record),
              tooltip: '删除',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(6),  // 减小整体 padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 起卦人信息
            if (record.querentName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '起卦人：${record.querentName}${record.querentGender.isNotEmpty ? " (${record.querentGender})" : ""}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),

            const SizedBox(height: 4),

            // 六爻详情表格（带关系连线）
            YaoRelationsOverlay(
              relations: relations,
              monthZhi: _extractDiZhi(record.monthGz),
              dayZhi: _extractDiZhi(record.dayGz),
              showQuantification: _showQuantification,
              settings: context.read<SettingsProvider>().settings,
              infoCard: _buildInfoCard(record),
              shenshaCard: ShenshaCard(shensha: record.shensha),
              child: YaoTable(
                yaoLines: record.yaoLines,
                gongWuXing: record.benGua.guaWuXing ?? '',
                benGuaName: record.benGua.guaName,
                bianGuaName: record.bianGua?.guaName,
                benGuaLabel: getGuaChongHeLabel(record.benGua.gua64Index),
                bianGuaLabel: record.bianGua != null ? getGuaChongHeLabel(record.bianGua!.gua64Index) : null,
                hasDongYao: record.hasDongYao(),
                showQuantification: _showQuantification,
                quantificationResults: quantificationResults,
              ),
            ),

            const SizedBox(height: 4),

            // 辅助开关栏（移到YaoTable下方）
            _buildHelperSwitches(),

            if (_showSanHe) ...[
              const SizedBox(height: 4),
              _buildSanHeDisplay(record),
            ],

            const SizedBox(height: 10),

            // 解卦输入区
            _buildInterpretationCard(record),
          ],
        ),
      ),
    );
  }

  /// 构建辅助开关栏
  Widget _buildHelperSwitches() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: [
            _buildSwitch(
              label: '数字量化',
              value: _showQuantification,
              onChanged: (v) => setState(() => _showQuantification = v),
              activeColor: Colors.purple,
            ),
            _buildSwitch(
              label: '冲',
              value: _showChong,
              onChanged: (v) => setState(() => _showChong = v),
              activeColor: Colors.red,
            ),
            _buildSwitch(
              label: '合',
              value: _showHe,
              onChanged: (v) => setState(() => _showHe = v),
              activeColor: Colors.green,
            ),
            _buildSwitch(
              label: '生',
              value: _showSheng,
              onChanged: (v) => setState(() => _showSheng = v),
              activeColor: Colors.orange,
            ),
            _buildSwitch(
              label: '克',
              value: _showKe,
              onChanged: (v) => setState(() => _showKe = v),
              activeColor: Colors.blue,
            ),
            _buildSwitch(
              label: '三合',
              value: _showSanHe,
              onChanged: (v) => setState(() => _showSanHe = v),
              activeColor: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个开关（使用小勾选方框）
  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: activeColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 三合局组和中神
  static const Map<String, List<String>> _sanHeGroups = {
    '水局': ['申', '子', '辰'],
    '火局': ['寅', '午', '戌'],
    '金局': ['巳', '酉', '丑'],
    '木局': ['亥', '卯', '未'],
  };
  // 中神（三合局中间的地支）
  static const Map<String, String> _sanHeZhongShen = {
    '申': '子', '子': '子', '辰': '子',
    '寅': '午', '午': '午', '戌': '午',
    '巳': '酉', '酉': '酉', '丑': '酉',
    '亥': '卯', '卯': '卯', '未': '卯',
  };

  /// 计算三合局，返回(被标记的爻位置集合, 描述文本列表)
  /// 六爻三合局必须三个地支齐全（本卦三爻、或本卦二爻+日月、或本变对位）
  ({Set<int> markedPositions, List<String> descriptions}) _calculateSanHe(DivinationRecord record) {
    final marked = <int>{};
    final descs = <String>[];
    final monthZhi = _extractDiZhi(record.monthGz);
    final dayZhi = _extractDiZhi(record.dayGz);

    // 本卦六爻地支（位置1-6）
    final benZhi = <int, String>{};
    for (final yao in record.yaoLines) {
      if (yao.ganZhi != null && yao.ganZhi!.isNotEmpty) {
        benZhi[yao.position] = yao.ganZhi!;
      }
    }

    // 变卦地支（只取有变爻的位置）
    final bianZhi = <int, String>{};
    if (record.bianGua != null) {
      for (final yao in record.yaoLines) {
        if (yao.isDong && yao.bianGanZhi != null && yao.bianGanZhi!.isNotEmpty) {
          bianZhi[yao.position] = yao.bianGanZhi!;
        }
      }
    }

    for (final entry in _sanHeGroups.entries) {
      final group = entry.value;
      final heName = entry.key;
      final zhongShen = group[1]; // 中神：子、午、酉、卯

      // ---- 类型1: 本卦三个不同地支组成三合（必须三个不同地支齐全）----
      final benMatches = benZhi.entries.where((e) => group.contains(e.value)).map((e) => e.key).toList()..sort();
      final benUnique = benZhi.entries.where((e) => group.contains(e.value)).map((e) => e.value).toSet();
      if (benUnique.length == 3) {
        marked.addAll(benMatches);
        descs.add('本卦${benMatches.join("、")}爻 → $heName');
        continue; // 已凑齐，无需继续判断该组
      }

      // ---- 类型2: 本卦+变卦对位三合 ----
      if (bianZhi.isNotEmpty) {
        // 初爻三爻组
        final b13 = [bianZhi[1], bianZhi[3]].whereType<String>().toList();
        final bg13 = [benZhi[1], benZhi[3]].whereType<String>().toList();
        final all13 = {...b13, ...bg13};
        if (all13.length >= 3) {
          final g13 = all13.where((z) => group.contains(z)).toList()..sort();
          if (g13.length == 3) {
            for (final z in g13) {
              for (final e in benZhi.entries) { if (e.value == z) marked.add(e.key); }
              for (final e in bianZhi.entries) { if (e.value == z) marked.add(e.key); }
            }
            descs.add('初爻三爻 本变三合 → $heName');
          }
        }

        // 四爻上爻组
        final b46 = [bianZhi[4], bianZhi[6]].whereType<String>().toList();
        final bg46 = [benZhi[4], benZhi[6]].whereType<String>().toList();
        final all46 = {...b46, ...bg46};
        if (all46.length >= 3) {
          final g46 = all46.where((z) => group.contains(z)).toList()..sort();
          if (g46.length == 3) {
            for (final z in g46) {
              for (final e in benZhi.entries) { if (e.value == z) marked.add(e.key); }
              for (final e in bianZhi.entries) { if (e.value == z) marked.add(e.key); }
            }
            descs.add('四爻上爻 本变三合 → $heName');
          }
        }
      }

      // ---- 类型3: 本卦至少两个不同地支 + 日月参与三合 ----
      // 本卦中至少有两个不同的地支属于该组（去重后计数）
      // 中神（子午卯酉）必须在**本卦爻**上，不能由日月充当
      final benGroupValues = benZhi.entries.where((e) => group.contains(e.value)).map((e) => e.value).toSet();
      if (benGroupValues.length >= 2 && benGroupValues.contains(zhongShen)) {
        final allZhi = {...benZhi.values, monthZhi, dayZhi}.where((z) => group.contains(z)).toList();
        if (allZhi.length == 3) {
          // 标记本卦中属于该三合组的地支
          for (final e in benZhi.entries) {
            if (group.contains(e.value)) marked.add(e.key);
          }
          // 日月来源描述
          final sources = <String>[];
          if (group.contains(monthZhi)) sources.add('月$monthZhi');
          if (group.contains(dayZhi)) sources.add('日$dayZhi');
          descs.add('本卦${benGroupValues.join("、")}爻 ${sources.join(" ")} → $heName');
        }
      }
    }

    return (markedPositions: marked, descriptions: descs);
  }

  Widget _buildSanHeDisplay(DivinationRecord record) {
    final result = _calculateSanHe(record);
    if (result.descriptions.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('未发现三合局', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('三合局', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final desc in result.descriptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(desc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建解卦卡片
  Widget _buildInterpretationCard(DivinationRecord record) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, size: 18),
                const SizedBox(width: 6),
                const Text(
                  '解卦笔记',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  ElevatedButton(
                    onPressed: () => _finishEditing(record),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('完成', style: TextStyle(fontSize: 12)),
                  )
                else
                  TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('编辑', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isEditing)
              TextField(
                controller: _interpretationController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '请输入解卦内容...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
                style: const TextStyle(fontSize: 13),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _interpretationController.text.isEmpty
                      ? '（点击编辑输入解卦内容）'
                      : _interpretationController.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: _interpretationController.text.isEmpty
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 导出分享
  void _exportRecord(DivinationRecord record) async {
    // 导出时带上最新的解卦内容
    final recordToExport = _savedRecordId != null
        ? record.copyWith(interpretation: _interpretationController.text)
        : record;
    final markdown = ExportHelper.exportToMarkdown(recordToExport, exporterName: record.querentName.isNotEmpty ? record.querentName : null);

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${ExportHelper.getFileName(recordToExport)}');
      await file.writeAsString(markdown);
      await Share.shareXFiles([XFile(file.path)], subject: '六爻助手：${recordToExport.benGua.guaName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  /// 删除记录
  void _deleteRecord(DivinationRecord record) async {
    if (record.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条排盘记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('删除'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      await historyProvider.deleteRecord(record.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// 保存记录
  void _saveRecord(DivinationRecord record) async {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    try {
      // 优先使用 _savedRecordId 再取 record.id（新排盘首次保存后 record.id 仍为 null）
      final existingId = record.id ?? _savedRecordId;

      if (existingId != null) {
        // 已有记录：更新解卦内容
        await historyProvider.updateInterpretation(existingId, _interpretationController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已更新解卦内容')),
        );
        return;
      }

      // 新排盘：保存到历史记录
      final recordWithInterpretation = record.copyWith(
        interpretation: _interpretationController.text,
      );
      _savedRecordId = await historyProvider.saveRecord(recordWithInterpretation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存到历史记录')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  /// 完成编辑 — 自动保存
  void _finishEditing(DivinationRecord record) {
    setState(() => _isEditing = false);

    final recordId = _savedRecordId ?? record.id;
    if (recordId != null) {
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.updateInterpretation(
        recordId,
        _interpretationController.text,
      );
    }
  }

  /// 构建信息卡片（紧凑版）
  Widget _buildInfoCard(DivinationRecord record) {
    // 农历显示：干支年 + 农历月日
    final lunarDateStr = LunarCalendar.getLunarDateString(record.divTime);
    // 时辰显示：干支时柱
    final hourGz = record.hourGz;

    // 检查是否是节气日
    String jieQiStr = '';
    try {
      final jieQiList = ShouXingCalendar.getJieQiList(record.divTime.year);
      for (final jieQi in jieQiList) {
        // 检查起卦时间是否在节气交割时间前后2小时内
        final diff = record.divTime.difference(jieQi.time).abs();
        if (diff.inHours < 2) {
          jieQiStr = '${jieQi.name} ${jieQi.time.hour.toString().padLeft(2, '0')}:${jieQi.time.minute.toString().padLeft(2, '0')}';
          break;
        }
      }
    } catch (e) {
      // 节气检查失败，忽略
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：起卦时间 + 农历（干支年 + 月日）
            Row(
              children: [
                Text(
                  record.formattedDivTime,
                  style: const TextStyle(fontSize: 11),
                ),
                Expanded(
                  child: Text(
                    '  ${record.yearGz}年 $lunarDateStr $hourGz时',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // 第二行：干支四柱
            Text(
              '${record.yearGz}年 ${record.monthGz}月 ${record.dayGz}日 ${record.hourGz}时',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),

            // 节气提示（如有）
            if (jieQiStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '节气：$jieQiStr',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                ),
              ),

            const SizedBox(height: 3),

            // 旬空 + 卦宫
            Text(
              '旬空：${record.xunKong}  卦宫：${record.benGua.gongName}(${record.benGua.guaWuXing})',
              style: const TextStyle(fontSize: 11),
            ),

            // 问题（如有）
            if (record.question.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '问：${record.question}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
