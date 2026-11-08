/// 干支排盘页面
///
/// 与「摇卦」「手工输入」并列的第三种起卦方式：
/// 不依赖公历时间，直接指定 **年 / 月建 / 日辰 / 时辰**，
/// 再逐爻指定阴阳与动静（默认六爻皆阳 = 乾为天）。
///
/// 用途：录入古籍卦例（如「戌月 丁亥日 占财」）、复盘他人卦例。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/constants.dart';
import '../algorithms/ganzhi_converter.dart';
import '../algorithms/gua_calculator.dart';
import '../algorithms/gua_generator.dart';
import '../algorithms/xunkong_calculator.dart';
import '../models/gua_info.dart';
import '../models/yao_line.dart';
import '../providers/divination_provider.dart';

class GanZhiPaiPanScreen extends StatefulWidget {
  const GanZhiPaiPanScreen({super.key});

  @override
  State<GanZhiPaiPanScreen> createState() => _GanZhiPaiPanScreenState();
}

class _GanZhiPaiPanScreenState extends State<GanZhiPaiPanScreen> {
  /// 六爻状态用「背面数」表示，与引擎一致：
  /// 1=少阳（阳静） 2=少阴（阴静） 3=老阳（阳动） 0=老阴（阴动）
  List<int> _backCounts = [1, 1, 1, 1, 1, 1];

  String _yearGz = '';
  String _monthZhi = '';
  String _dayGz = '';
  String _hourZhi = '';
  String? _error;

  final TextEditingController _questionCtrl = TextEditingController();

  static const List<String> _positionNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

  /// 时辰标签
  static const Map<String, String> _shiChenLabels = {
    '子': '子时 23-1', '丑': '丑时 1-3', '寅': '寅时 3-5', '卯': '卯时 5-7',
    '辰': '辰时 7-9', '巳': '巳时 9-11', '午': '午时 11-13', '未': '未时 13-15',
    '申': '申时 15-17', '酉': '酉时 17-19', '戌': '戌时 19-21', '亥': '亥时 21-23',
  };

  @override
  void initState() {
    super.initState();
    // 默认取今天的月建与日柱，年与时辰留「无」
    try {
      final gz = GanZhiConverter.convert(DateTime.now());
      _monthZhi = gz.monthZhi;
      _dayGz = gz.dayGz;
    } catch (_) {
      _monthZhi = '子';
      _dayGz = '甲子';
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  bool _isYang(int i) => _backCounts[i] == 1 || _backCounts[i] == 3;
  bool _isDong(int i) => _backCounts[i] == 0 || _backCounts[i] == 3;

  void _setYao(int i, {bool? yang, bool? dong}) {
    final y = yang ?? _isYang(i);
    final d = dong ?? _isDong(i);
    setState(() {
      if (y && d) {
        _backCounts[i] = 3;
      } else if (y && !d) {
        _backCounts[i] = 1;
      } else if (!y && d) {
        _backCounts[i] = 0;
      } else {
        _backCounts[i] = 2;
      }
    });
  }

  List<YaoLine> _yaoLins() => _backCounts
      .asMap()
      .entries
      .map((e) => YaoLine.fromBackCount(e.key + 1, e.value))
      .toList();

  /// 当前爻象对应的本卦 / 变卦（用于预览）
  ({GuaInfo ben, GuaInfo? bian}) get _preview {
    final lines = _yaoLins();
    return (
      ben: GuaGenerator.generateBenGua(lines),
      bian: GuaGenerator.generateBianGua(lines),
    );
  }

  void _submit() {
    setState(() => _error = null);
    if (_dayGz.length != 2) {
      setState(() => _error = '请选择日辰（六十甲子）');
      return;
    }
    try {
      final record = GuaCalculator.calculateFromGanZhi(
        backCounts: _backCounts,
        dayGz: _dayGz,
        monthGz: _monthZhi,
        yearGz: _yearGz,
        hourGz: _hourZhi,
        question: _questionCtrl.text.trim(),
      );
      if (!mounted) return;
      final provider = Provider.of<DivinationProvider>(context, listen: false);
      provider.setRecord(record);
      Navigator.pushNamed(context, '/result');
    } catch (e) {
      setState(() => _error = '排盘失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pv = _preview;
    return Scaffold(
      appBar: AppBar(
        title: const Text('干支排盘'),
        actions: [
          IconButton(
            tooltip: '全部重置为六阳',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(() {
              _backCounts = [1, 1, 1, 1, 1, 1];
              _yearGz = '';
              _hourZhi = '';
              _questionCtrl.clear();
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildGanZhiCard(),
          const SizedBox(height: 8),
          _buildYaoCard(),
          const SizedBox(height: 8),
          _buildQuestionCard(),
          const SizedBox(height: 8),
          _buildSummary(pv),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('开始排盘', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 8),
          const Text(
            '说明：干支排盘不依赖公历时间，直接按干支起局，'
            '六神由日干起、旬空由日辰定，与古籍卦例口径一致。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- 干支区 ----
  Widget _buildGanZhiCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('干支', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _labeled('年', _yearDropdown())),
                const SizedBox(width: 8),
                Expanded(child: _labeled('月建', _monthDropdown())),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _labeled('日辰', _dayDropdown())),
                const SizedBox(width: 8),
                Expanded(child: _labeled('时辰', _hourDropdown())),
              ],
            ),
            if (_monthZhi.isNotEmpty || _dayGz.length == 2) ...[
              const SizedBox(height: 10),
              Text(
                '${_monthZhi.isEmpty ? '' : '$_monthZhi月  '}$_dayGz日'
                '${_hourZhi.isEmpty ? '' : '  ${GanZhiConverter.hourGzFromZhi(_dayGz, _hourZhi)}时'}'
                '${_dayGz.length == 2 ? '　旬空：${XunKongCalculator.getXunKongStr(_dayGz)}' : ''}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8B4513)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _dd<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _yearDropdown() => _dd<String>(
        value: _yearGz,
        items: [
          const DropdownMenuItem(value: '', child: Text('（无）', style: TextStyle(fontSize: 14))),
          ...ganzhi60.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14)))),
        ],
        onChanged: (v) => setState(() => _yearGz = v ?? ''),
      );

  Widget _monthDropdown() => _dd<String>(
        value: _monthZhi.isEmpty ? null : _monthZhi,
        items: diZhi
            .map((z) => DropdownMenuItem(value: z, child: Text('$z月', style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: (v) => setState(() => _monthZhi = v ?? ''),
      );

  Widget _dayDropdown() => _dd<String>(
        value: _dayGz.length == 2 ? _dayGz : null,
        items: ganzhi60
            .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: (v) => setState(() => _dayGz = v ?? ''),
      );

  Widget _hourDropdown() => _dd<String>(
        value: _hourZhi,
        items: [
          const DropdownMenuItem(value: '', child: Text('（无）', style: TextStyle(fontSize: 14))),
          ...diZhi.map((z) => DropdownMenuItem(
                value: z,
                child: Text(_shiChenLabels[z] ?? z, style: const TextStyle(fontSize: 14)),
              )),
        ],
        onChanged: (v) => setState(() => _hourZhi = v ?? ''),
      );

  // ---- 按爻区 ----
  Widget _buildYaoCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('按爻', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('默认六爻皆阳', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 5; i >= 0; i--) _buildYaoRow(i),
            const Divider(height: 20),
            Text(
              '点爻画切换阴阳，勾「动」即为动爻（阳动○／阴动×）',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYaoRow(int i) {
    final yang = _isYang(i);
    final dong = _isDong(i);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(_positionNames[i],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          // 爻画：点一下切阴阳
          Expanded(
            child: InkWell(
              onTap: () => _setYao(i, yang: !yang),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: yang ? const Color(0xFF8B4513).withValues(alpha: 0.08) : Colors.blueGrey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 72, height: 8, color: const Color(0xFF5D4037)),
                    if (!yang) ...[
                      const SizedBox(width: 18),
                      Container(width: 72, height: 8, color: const Color(0xFF5D4037)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              dong ? (yang ? '○动' : '×动') : '静',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: dong ? FontWeight.bold : FontWeight.normal,
                color: dong ? const Color(0xFFC62828) : Colors.grey,
              ),
            ),
          ),
          Checkbox(
            value: dong,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => _setYao(i, dong: v ?? false),
          ),
        ],
      ),
    );
  }

  // ---- 占问 ----
  Widget _buildQuestionCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('占问', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _questionCtrl,
              decoration: const InputDecoration(
                hintText: '如：占财、占婚姻（可留空）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 预览 ----
  Widget _buildSummary(({GuaInfo ben, GuaInfo? bian}) pv) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFF3EEE3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本卦：${pv.ben.guaName}（${pv.ben.gongName}${pv.ben.guaWuXing}）',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              pv.bian == null
                  ? '静卦，无变卦'
                  : '变卦：${pv.bian!.guaName}（${pv.bian!.gongName}${pv.bian!.guaWuXing}）',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 4),
            Text(
              '动爻 ${_backCounts.where((c) => c == 0 || c == 3).length} 个',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
