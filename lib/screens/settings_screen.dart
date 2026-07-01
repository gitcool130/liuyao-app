/// 设置界面
/// 自定义爻颜色、连线颜色、爻象字体大小
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _temp;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _temp = context.read<SettingsProvider>().settings.copyWith();
      _initialized = true;
    }
  }

  /// 选择颜色的底部弹窗
  Future<void> _pickColor(String title, Color current, ValueChanged<Color> onPicked) async {
    final selected = await showModalBottomSheet<Color>(
      context: context,
      builder: (ctx) => _ColorPickerSheet(title: title, current: current),
    );
    if (selected != null) {
      setState(() => onPicked(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('颜色设置'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // 不保存，直接返回
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '保存',
            onPressed: () async {
              await _temp.save();
              if (context.mounted) {
                context.read<SettingsProvider>().update(_temp);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === 爻颜色 ===
          _sectionHeader('爻颜色'),
          const SizedBox(height: 8),
          _colorItem(
            '静爻颜色',
            _temp.staticYaoColor,
            (c) => _temp.staticYaoColor = c,
          ),
          _colorItem(
            '动爻颜色',
            _temp.dongYaoColor,
            (c) => _temp.dongYaoColor = c,
          ),
          _fontSizeItem(
            '爻象字体大小',
            _temp.yaoFontSize,
            (v) => _temp.yaoFontSize = v,
          ),

          const Divider(height: 32),

          // === 连线颜色 ===
          _sectionHeader('连线颜色'),
          const SizedBox(height: 8),
          _colorItem(
            '冲线颜色',
            _temp.chongLineColor,
            (c) => _temp.chongLineColor = c,
          ),
          _colorItem(
            '合线颜色',
            _temp.heLineColor,
            (c) => _temp.heLineColor = c,
          ),
          _colorItem(
            '生线颜色',
            _temp.shengLineColor,
            (c) => _temp.shengLineColor = c,
          ),
          _colorItem(
            '克线颜色',
            _temp.keLineColor,
            (c) => _temp.keLineColor = c,
          ),

          const Divider(height: 32),

          // === 显示选项 ===
          _sectionHeader('显示选项'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('地支五行彩色显示', style: TextStyle(fontSize: 15)),
            subtitle: const Text('水蓝 火红 木绿 金黄 土棕'),
            value: _temp.showColoredWuXing,
            onChanged: (v) => setState(() => _temp.showColoredWuXing = v),
          ),

          const Divider(height: 32),

          // === 示例预览 ===
          _sectionHeader('预览'),
          const SizedBox(height: 8),
          _buildPreviewRow('───', '静爻', _temp.staticYaoColor),
          _buildPreviewRow('───○', '动爻', _temp.dongYaoColor),
          const SizedBox(height: 8),
          _buildLinePreview('冲线', _temp.chongLineColor),
          _buildLinePreview('合线', _temp.heLineColor),
          _buildLinePreview('生线', _temp.shengLineColor),
          _buildLinePreview('克线', _temp.keLineColor),

          const SizedBox(height: 32),

          // === 重置按钮 ===
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _temp = AppSettings();
                });
              },
              icon: const Icon(Icons.restore),
              label: const Text('恢复默认'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5D4037),
      ),
    );
  }

  Widget _colorItem(String label, Color current, ValueChanged<Color> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: GestureDetector(
        onTap: () => _pickColor(label, current, onChanged),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: current,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _fontSizeItem(String label, double current, ValueChanged<double> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: SizedBox(
        width: 160,
        child: Row(
          children: [
            Text('${current.toInt()}', style: const TextStyle(fontSize: 15)),
            Expanded(
              child: Slider(
                value: current,
                min: 10,
                max: 18,
                divisions: 8,
                label: current.toInt().toString(),
                onChanged: (v) => setState(() => onChanged(v)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String symbol, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(symbol, style: TextStyle(fontSize: _temp.yaoFontSize, color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildLinePreview(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 40, height: 3, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}

/// 颜色选择底部弹窗
class _ColorPickerSheet extends StatelessWidget {
  final String title;
  final Color current;

  const _ColorPickerSheet({required this.title, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: presetColors.map((opt) {
              final isSelected = opt.color.value == current.value;
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(opt.color),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: opt.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
