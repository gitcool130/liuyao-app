/// 设置界面
/// 颜色设置、字体设置、神煞设置三个分页
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

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppSettings _temp;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _temp = context.read<SettingsProvider>().settings.copyWith();
      _initialized = true;
    }
  }

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
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '颜色', icon: Icon(Icons.color_lens, size: 18)),
            Tab(text: '字体', icon: Icon(Icons.text_fields, size: 18)),
            Tab(text: '神煞', icon: Icon(Icons.star, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildColorTab(),
          _buildFontTab(),
          _buildShenshaTab(),
        ],
      ),
    );
  }

  // ==================== 颜色设置 ====================

  Widget _buildColorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('爻颜色'),
        const SizedBox(height: 8),
        _colorItem('静爻颜色', _temp.staticYaoColor, (c) => _temp.staticYaoColor = c),
        _colorItem('动爻颜色', _temp.dongYaoColor, (c) => _temp.dongYaoColor = c),
        _fontSizeItem('爻象字体大小', _temp.yaoFontSize, (v) => _temp.yaoFontSize = v, 10, 18),

        const Divider(height: 32),

        _sectionHeader('连线颜色'),
        const SizedBox(height: 8),
        _colorItem('冲线颜色', _temp.chongLineColor, (c) => _temp.chongLineColor = c),
        _colorItem('合线颜色', _temp.heLineColor, (c) => _temp.heLineColor = c),
        _colorItem('生线颜色', _temp.shengLineColor, (c) => _temp.shengLineColor = c),
        _colorItem('克线颜色', _temp.keLineColor, (c) => _temp.keLineColor = c),

        const Divider(height: 32),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('地支五行彩色显示', style: TextStyle(fontSize: 15)),
          subtitle: const Text('水蓝 火红 木绿 金黄 土棕'),
          value: _temp.showColoredWuXing,
          onChanged: (v) => setState(() => _temp.showColoredWuXing = v),
        ),

        const Divider(height: 32),

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

        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() => _temp = AppSettings());
            },
            icon: const Icon(Icons.restore),
            label: const Text('恢复默认'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  // ==================== 字体设置 ====================

  Widget _buildFontTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('神煞字体大小'),
        const SizedBox(height: 4),
        const Text('控制神煞栏显示字体大小', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        _fontSizeItem('神煞字体', _temp.shenshaFontSize, (v) => _temp.shenshaFontSize = v, 10, 20),

        const Divider(height: 32),

        _sectionHeader('信息栏字体大小'),
        const SizedBox(height: 4),
        const Text('控制起卦时间、农历、旬空、问念等文字大小（干支四柱不变）', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        _fontSizeItem('信息字体', _temp.infoFontSize, (v) => _temp.infoFontSize = v, 10, 18),

        const Divider(height: 32),

        _sectionHeader('示例预览'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '2026年6月25日 21:45',
                style: TextStyle(fontSize: _temp.infoFontSize),
              ),
              const SizedBox(height: 4),
              const Text(
                '丙午年 甲午月 庚午日 丁亥时',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '旬空：',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    TextSpan(
                      text: '戌亥',
                      style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF8B4513)),
                    ),
                    const TextSpan(
                      text: '  卦宫：乾宫(金)',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                  style: TextStyle(fontSize: _temp.infoFontSize),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '神煞：天乙:丑未  驿马:申  咸池:卯',
                style: TextStyle(fontSize: _temp.shenshaFontSize, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 神煞设置 ====================

  Widget _buildShenshaTab() {
    // 所有神煞项，按显示顺序排列
    const items = [
      ('tianYi', '天乙贵人'),
      ('yiMa', '驿马'),
      ('huaGai', '华盖'),
      ('xianChi', '咸池'),
      ('luShen', '禄神'),
      ('tianYiShen', '天医'),
      ('wenChang', '文昌'),
      ('jiangXing', '将星'),
      ('yangRen', '羊刃'),
      ('hongLuan', '红鸾'),
      ('tianXi', '天喜'),
      ('jieSha', '劫煞'),
      ('zaiSha', '灾煞'),
      ('wangShen', '亡神'),
      ('guChen', '孤辰'),
      ('guaSu', '寡宿'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('神煞显示设置'),
        const SizedBox(height: 4),
        const Text('选择在排盘结果中显示的神煞项', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),

        // 全选/取消全选
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _temp.visibleShensha = items.map((e) => e.$1).toList();
                });
              },
              icon: const Icon(Icons.select_all, size: 18),
              label: const Text('全选', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _temp.visibleShensha = []);
              },
              icon: const Icon(Icons.deselect, size: 18),
              label: const Text('取消全选', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),

        const Divider(),

        // 神煞列表
        ...items.map((item) {
          final isChecked = _temp.visibleShensha.contains(item.$1);
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.$2, style: const TextStyle(fontSize: 15)),
            value: isChecked,
            activeColor: const Color(0xFF8B4513),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _temp.visibleShensha.add(item.$1);
                } else {
                  _temp.visibleShensha.remove(item.$1);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // ==================== 公用组件 ====================

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

  Widget _fontSizeItem(String label, double current, ValueChanged<double> onChanged, double min, double max) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: SizedBox(
        width: 180,
        child: Row(
          children: [
            Text('${current.toInt()}', style: const TextStyle(fontSize: 15)),
            Expanded(
              child: Slider(
                value: current,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
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
