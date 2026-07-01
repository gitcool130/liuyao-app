import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/history_provider.dart';
import '../models/divination_record.dart';
import '../utils/export_helper.dart';
import 'result_screen.dart';

/// 历史记录列表页
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<HistoryProvider>(
          builder: (context, provider, child) {
            if (provider.searchKeyword.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('历史记录'),
                  Text(
                    '搜索：${provider.searchKeyword} (${provider.records.length}条)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            }
            return const Text('历史记录');
          },
        ),
        actions: [
          // 清除搜索按钮（搜索模式下显示）
          Consumer<HistoryProvider>(
            builder: (context, provider, child) {
              if (provider.searchKeyword.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: '清除搜索',
                  onPressed: () => provider.search(''),
                );
              }
              return IconButton(
                icon: const Icon(Icons.search),
                tooltip: '搜索',
                onPressed: _showSearchDialog,
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无历史记录', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('完成排盘后可在此查看', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 记录列表
              Expanded(
                child: ListView.builder(
                  itemCount: provider.records.length,
                  itemBuilder: (context, index) {
                    final record = provider.records[index];
                    return _buildRecordItem(context, provider, record);
                  },
                ),
              ),

              // 底部操作栏（有选中时显示）
              if (provider.hasSelection())
                _buildBottomBar(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordItem(
    BuildContext context,
    HistoryProvider provider,
    DivinationRecord record,
  ) {
    final isSelected = record.id != null && provider.isSelected(record.id!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          if (provider.hasSelection()) {
            // 选择模式下点击切换选择
            if (record.id != null) {
              provider.toggleSelection(record.id!);
            }
          } else {
            // 正常模式下点击进入详情
            _navigateToDetail(context, record);
          }
        },
        onLongPress: () {
          // 长按进入选择模式
          if (record.id != null) {
            provider.toggleSelection(record.id!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 选择框（选择模式下显示）
              if (provider.hasSelection())
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (record.id != null) {
                      provider.toggleSelection(record.id!);
                    }
                  },
                ),

              // 记录内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 时间（起卦时间 + 添加时间）
                    Row(
                      children: [
                        Text(
                          record.formattedDivTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '记录于 ${record.formattedCreatedAt}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 起卦人
                    if (record.querentName.isNotEmpty)
                      Text(
                        '起卦人：${record.querentName}${record.querentGender.isNotEmpty ? '(${record.querentGender})' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),

                    // 问题摘要
                    if (record.question.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '问：${record.question.length > 30 ? '${record.question.substring(0, 30)}...' : record.question}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),

                    const SizedBox(height: 4),

                    // 卦象
                    Row(
                      children: [
                        Text(
                          record.benGua.guaName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                        if (record.bianGua != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '→ ${record.bianGua!.guaName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, HistoryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          // 全选按钮
          TextButton(
            onPressed: () => provider.toggleSelectAll(),
            child: Text(provider.isAllSelected() ? '取消全选' : '全选'),
          ),

          const SizedBox(width: 16),

          // 选中数量
          Text('已选 ${provider.selectedIds.length} 条'),

          const Spacer(),

          // 导出选中
          ElevatedButton.icon(
            onPressed: () => _exportSelected(context, provider),
            icon: const Icon(Icons.share),
            label: const Text('导出'),
          ),

          const SizedBox(width: 8),

          // 删除选中
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDeleteSelected(context, provider),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, DivinationRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(record: record),
      ),
    );
  }

  void _showSearchDialog() {
    final provider = Provider.of<HistoryProvider>(context, listen: false);
    final searchController = TextEditingController(text: provider.searchKeyword);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('搜索记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: '输入关键词',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              '搜索范围：问题内容、起卦人姓名',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchController.clear();
            },
            child: const Text('清空'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // 清除搜索，显示全部记录
              provider.search('');
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final keyword = searchController.text.trim();
              Navigator.pop(dialogContext);
              // 执行搜索
              await provider.search(keyword);
              // 显示搜索结果提示
              if (keyword.isNotEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('找到 ${provider.records.length} 条匹配记录'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: '清除',
                      onPressed: () => provider.search(''),
                    ),
                  ),
                );
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _exportSelected(BuildContext context, HistoryProvider provider) async {
    final records = provider.getSelectedRecords();
    if (records.isEmpty) return;

    final markdown = ExportHelper.exportMultiple(records);
    final dir = await getTemporaryDirectory();
    final fileName = ExportHelper.getBatchFileName(records.length);
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(markdown);
    await Share.shareXFiles([XFile(file.path)], subject: '六爻助手记录集');
  }

  void _confirmDeleteSelected(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除选中的 ${provider.selectedIds.length} 条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteSelected();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}