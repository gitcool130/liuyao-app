import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shensha_result.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

/// 神煞信息卡片组件
/// 自适应wrap布局，点击可收缩/展开
class ShenshaCard extends StatefulWidget {
  final ShenshaResult shensha;

  const ShenshaCard({super.key, required this.shensha});

  @override
  State<ShenshaCard> createState() => _ShenshaCardState();
}

class _ShenshaCardState extends State<ShenshaCard> {
  bool _expanded = true;

  /// 神煞名称列表
  static const _shenshaDisplayNames = [
    '天乙贵人', '驿马', '咸池', '禄神', '华盖', '天医',
    '文昌', '将星', '羊刃', '红鸾', '天喜', '劫煞',
    '灾煞', '亡神', '孤辰', '寡宿',
  ];

  static String _getShenshaValue(ShenshaResult s, String displayName) {
    switch (displayName) {
      case '天乙贵人': return s.tianYi;
      case '驿马': return s.yiMa;
      case '咸池': return s.xianChi;
      case '禄神': return s.luShen;
      case '华盖': return s.huaGai;
      case '天医': return s.tianYiShen;
      case '文昌': return s.wenChang;
      case '将星': return s.jiangXing;
      case '羊刃': return s.yangRen;
      case '红鸾': return s.hongLuan;
      case '天喜': return s.tianXi;
      case '劫煞': return s.jieSha;
      case '灾煞': return s.zaiSha;
      case '亡神': return s.wangShen;
      case '孤辰': return s.guChen;
      case '寡宿': return s.guaSu;
      default: return '';
    }
  }

  static const _fieldToName = {
    'tianYi': '天乙贵人', 'yiMa': '驿马', 'xianChi': '咸池',
    'luShen': '禄神', 'huaGai': '华盖', 'tianYiShen': '天医',
    'wenChang': '文昌', 'jiangXing': '将星', 'yangRen': '羊刃',
    'hongLuan': '红鸾', 'tianXi': '天喜', 'jieSha': '劫煞',
    'zaiSha': '灾煞', 'wangShen': '亡神', 'guChen': '孤辰', 'guaSu': '寡宿',
  };

  @override
  Widget build(BuildContext context) {
    if (widget.shensha.isEmpty()) return const SizedBox.shrink();

    final settings = context.watch<SettingsProvider>().settings;
    final fontSize = settings.shenshaFontSize;
    final visibleFields = settings.visibleShensha.toSet();

    // 过滤出用户选择且非空的神煞
    final items = <_ShenshaItem>[];
    for (final displayName in _shenshaDisplayNames) {
      final fieldName = _fieldToName.entries
          .firstWhere((e) => e.value == displayName, orElse: () => MapEntry('', '')).key;
      if (fieldName.isEmpty) continue;
      if (!visibleFields.contains(fieldName)) continue;
      final value = _getShenshaValue(widget.shensha, displayName);
      if (value.isEmpty) continue;
      items.add(_ShenshaItem(displayName, value, fieldName));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    // 估算每行可显示的项数（根据字号）
    final approxPerRow = fontSize > 15 ? 3 : (fontSize > 12 ? 4 : 5);
    final hasMultiRows = items.length > approxPerRow;
    final showing = _expanded || !hasMultiRows ? items : items.take(approxPerRow).toList();

    return GestureDetector(
      onTap: hasMultiRows ? () => setState(() => _expanded = !_expanded) : null,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: showing.map((item) => Text(
                  '${item.name}：${item.value}',
                  style: TextStyle(fontSize: fontSize),
                  overflow: TextOverflow.ellipsis,
                )).toList(),
              ),
              if (hasMultiRows)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _expanded ? '▲ 收起' : '▼ 展开全部',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShenshaItem {
  final String name;
  final String value;
  final String fieldName;
  const _ShenshaItem(this.name, this.value, this.fieldName);
}
