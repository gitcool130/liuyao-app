/// 排盘导入中转界面
/// 自动解析分享文件后跳转到排盘结果页
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/export_helper.dart';
import '../models/divination_record.dart';
import '../providers/divination_provider.dart';
import '../providers/history_provider.dart';
import 'result_screen.dart';
import 'history_screen.dart';

class ImportScreen extends StatefulWidget {
  /// 从分享接收的文件内容
  final String? sharedContent;

  const ImportScreen({super.key, this.sharedContent});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.sharedContent != null && widget.sharedContent!.isNotEmpty) {
      _parseContent(widget.sharedContent!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _parseContent(String content) {
    // 格式检查
    if (!content.contains('LIUYAO_DATA:')) {
      setState(() {
        _isLoading = false;
        _errorMessage = '文件格式不正确，无法导入\n\n'
            '请确认文件是由六爻排盘App导出的.md排盘文档。';
      });
      return;
    }

    try {
      final result = ExportHelper.importFromMarkdown(content);
      if (result.records.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '未能从文件中解析出排盘数据\n\n'
              '文件格式可能已损坏，请联系分享者重新导出。';
        });
        return;
      }

      if (mounted) {
        // 多条记录：弹窗确认后批量导入
        if (result.records.length > 1) {
          _showMultiImportDialog(result.records);
          return;
        }

        // 单条记录：直接跳转排盘结果页
        final provider = Provider.of<DivinationProvider>(context, listen: false);
        provider.setRecord(result.records.first);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ResultScreen()),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '文件解析失败：\n$e\n\n'
            '文件格式可能已损坏，请联系分享者重新导出。';
      });
    }
  }

  void _showMultiImportDialog(List<DivinationRecord> records) async {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('发现多条排盘记录'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('该文档包含 ${records.length} 条排盘记录，是否全部导入？'),
              const SizedBox(height: 12),
              for (int i = 0; i < records.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${records[i].benGua.guaName}  ${records[i].formattedGanZhi}',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('导入全部（${records.length}条）'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 批量保存到历史记录
      for (final record in records) {
        await historyProvider.saveRecord(record);
      }

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          }
        });
      }
    } else if (mounted) {
      // 用户取消：返回首页
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入排盘')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 24),
              const Text('导入失败',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回首页'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_download_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text('等待分享文件...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              '在微信、QQ等App中收到排盘文档后：\n'
              '1. 打开文档 → 点右上角"更多"\n'
              '2. 选择"用其他应用打开"\n'
              '3. 选择"六爻排盘"',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
