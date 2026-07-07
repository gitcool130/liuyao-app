/// 手动排盘页面
/// 支持输入背面数和手动指定爻象两种方式
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../algorithms/constants.dart';
import '../providers/divination_provider.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;
  bool _manualSpecify = false;
  late List<YaoType?> _selectedTypes;

  static const _positionNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
  static const _emptyHint = '请选择';

  @override
  void initState() {
    super.initState();
    _selectedTypes = List.filled(6, null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _yaoTypeToBackCount(YaoType type) {
    switch (type) {
      case YaoType.laoYin: return 0;
      case YaoType.shaoYang: return 1;
      case YaoType.shaoYin: return 2;
      case YaoType.laoYang: return 3;
    }
  }

  void _submit() {
    setState(() => _errorMessage = null);

    List<int> backCounts;
    if (_manualSpecify) {
      // 检查是否有未选择的爻
      final nullIndex = _selectedTypes.indexOf(null);
      if (nullIndex >= 0) {
        setState(() => _errorMessage = '请为「${_positionNames[nullIndex]}」选择爻象');
        return;
      }
      backCounts = _selectedTypes.map((t) => _yaoTypeToBackCount(t!)).toList();
    } else {
      String text = _controller.text.trim();
      if (text.isEmpty) {
        setState(() => _errorMessage = '请输入6个背面数');
        return;
      }
      if (text.length == 6 && RegExp(r'^[0-3]{6}$').hasMatch(text)) {
        backCounts = text.split('').map((c) => int.parse(c)).toList();
      } else {
        List<String> parts = text.split(RegExp(r'[,\s]+')).where((p) => p.isNotEmpty).toList();
        if (parts.length != 6) {
          setState(() => _errorMessage = '需要输入6个数字（初爻到上爻），每个数字为0-3');
          return;
        }
        backCounts = [];
        for (int i = 0; i < 6; i++) {
          int? value = int.tryParse(parts[i]);
          if (value == null || value < 0 || value > 3) {
            setState(() => _errorMessage = '第${i + 1}个数字必须是0-3');
            return;
          }
          backCounts.add(value);
        }
      }
    }

    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setBackCounts(backCounts);
    provider.calculate();
    Navigator.pushNamed(context, '/result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手动排盘'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 模式切换开关
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text('输入背数', style: TextStyle(
                      fontSize: 14,
                      color: _manualSpecify ? Colors.grey : Colors.black87,
                      fontWeight: _manualSpecify ? FontWeight.normal : FontWeight.bold,
                    )),
                    const SizedBox(width: 8),
                    Switch(
                      value: _manualSpecify,
                      activeColor: const Color(0xFF5D4037),
                      onChanged: (v) => setState(() => _manualSpecify = v),
                    ),
                    const SizedBox(width: 8),
                    Text('手动指定', style: TextStyle(
                      fontSize: 14,
                      color: _manualSpecify ? Colors.black87 : Colors.grey,
                      fontWeight: _manualSpecify ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_manualSpecify)
              _buildManualSpecify()
            else
              _buildBackCountInput(),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('开始排盘', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('背面数含义', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('每次掷三枚铜钱，统计背面数量：', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                _buildRuleRow('0背', '三个正面', '老阴（动爻）', '×'),
                _buildRuleRow('1背', '两正一反', '少阳（静爻）', '—'),
                _buildRuleRow('2背', '一正两反', '少阴（静爻）', '- -'),
                _buildRuleRow('3背', '三个反面', '老阳（动爻）', '○'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('请输入6个背面数（从初爻到上爻）',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('示例：210132 或 2,1,0,1,3,2',
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '输入6个数字（每个0-3）',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _controller.clear(),
            ),
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildManualSpecify() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('为每个爻指定爻象', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // 上爻在上，初爻在下
            for (int i = 5; i >= 0; i--)...[if (i < 5) const Divider(height: 4),
              _buildYaoSelector(i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYaoSelector(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              _positionNames[index],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<YaoType?>(
              value: _selectedTypes[index],
              hint: const Text('请选择', style: TextStyle(fontSize: 13, color: Colors.grey)),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
                  onChanged: (v) => setState(() => _selectedTypes[index] = v),
              items: [
                _dropdownItem(YaoType.laoYin, '老阴（动爻）', '×'),
                _dropdownItem(YaoType.shaoYang, '少阳（静爻）', '—'),
                _dropdownItem(YaoType.shaoYin, '少阴（静爻）', '- -'),
                _dropdownItem(YaoType.laoYang, '老阳（动爻）', '○'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<YaoType?> _dropdownItem(YaoType type, String label, String symbol) {
    return DropdownMenuItem(
      value: type,
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(symbol, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D4037),
          )),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String back, String coins, String type, String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40, alignment: Alignment.center,
            child: Text(back, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('$coins → $type')),
          Container(
            width: 30, alignment: Alignment.center,
            child: Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
          ),
        ],
      ),
    );
  }
}
