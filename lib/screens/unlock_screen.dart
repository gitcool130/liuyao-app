/// 功能解锁页面
/// 输入验证码解锁高级功能
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/feature_lock_service.dart';
import '../providers/settings_provider.dart';
import 'course_notes_screen.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _codeController = TextEditingController();
  final _remarkController = TextEditingController();
  bool _verifying = false;
  bool _submitting = false;
  bool _requestSubmitted = false;
  List<String> _unlockedFeatures = [];
  String? _deviceId;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final deviceId = await FeatureLockService.getDeviceId();
    final unlocked = await FeatureLockService.getUnlockedFeatures();
    setState(() {
      _deviceId = deviceId;
      _unlockedFeatures = unlocked;
    });
    // 启动时自动检查申请状态
    if (deviceId != null && !unlocked.contains('F005')) {
      _checkAutoUnlock(deviceId);
    }
  }

  /// 自动检查申请状态（审批通过则自动解锁）
  Future<void> _checkAutoUnlock(String deviceId) async {
    final result = await FeatureLockService.checkRequestStatus(deviceId);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['status'] == 'approved' && data['code'] != null) {
        final code = data['code'] as String;
        final verifyResult = await FeatureLockService.verifyCode(deviceId: deviceId, code: code);
        if (verifyResult.valid && mounted) {
          for (final feature in lockedFeatures) {
            await FeatureLockService.unlock(feature.code, verifyResult.expireDate);
          }
          setState(() {
            _unlockedFeatures = lockedFeatures.map((f) => f.code).toList();
            _message = '✅ 申请已通过，功能已自动解锁！';
          });
        }
      }
    }
  }

  /// 提交解锁申请
  Future<void> _submitRequest() async {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    setState(() { _submitting = true; _message = null; });

    final result = await FeatureLockService.submitRequest(
      deviceId: deviceId,
      remark: _remarkController.text.trim(),
    );

    setState(() { _submitting = false; });
    if (mounted) {
      if (result['success'] == true) {
        final data = (result['data'] as Map<String, dynamic>?) ?? {};
        final msg = data['message'] ?? '申请已提交';
        setState(() { _requestSubmitted = true; _message = '✅ $msg'; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $msg'),
          duration: const Duration(seconds: 4),
        ));
      } else {
        setState(() => _message = '❌ ${result['message'] ?? '提交失败，请稍后重试'}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${result['message'] ?? '提交失败'}'),
        ));
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _message = '请输入8位验证码');
      return;
    }

    setState(() {
      _verifying = true;
      _message = null;
    });

    bool anyUnlocked = false;
    String? expireDate;
    final deviceId = _deviceId;
    if (deviceId == null) { setState(() => _verifying = false); return; }

    // 纯服务器验证（App不存储密钥）
    final result = await FeatureLockService.verifyCode(
      deviceId: deviceId,
      code: code,
    );

    if (result.valid) {
      for (final feature in lockedFeatures) {
        if (!_unlockedFeatures.contains(feature.code)) {
          await FeatureLockService.unlock(feature.code, result.expireDate);
          _unlockedFeatures.add(feature.code);
        }
      }
      anyUnlocked = true;
      expireDate = result.expireDate;
      setState(() => _message = '✅ 全部功能已解锁！有效期至 ${result.expireDate}');
    } else {
      setState(() => _message = '❌ 验证码无效或已过期（服务器验证）');
    }

    setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('功能解锁'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 设备ID（带复制按钮）
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('设备ID', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const Spacer(),
                      SizedBox(
                        height: 28,
                        child: TextButton.icon(
                          onPressed: () {
                            if (_deviceId != null) {
                              Clipboard.setData(ClipboardData(text: _deviceId!));
                              setState(() => _message = '设备ID已复制');
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _message = null);
                              });
                            }
                          },
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('复制', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: const Color(0xFF8B4513),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _deviceId ?? '加载中...',
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '将设备ID提供给管理员以申请验证码',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 提交解锁申请
          Card(
            color: _requestSubmitted ? Colors.green.shade50 : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(_requestSubmitted ? Icons.check_circle : Icons.send,
                        size: 18, color: _requestSubmitted ? Colors.green : const Color(0xFF1565C0)),
                    const SizedBox(width: 6),
                    Text(_requestSubmitted ? '申请已提交' : '提交解锁申请',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                            color: _requestSubmitted ? Colors.green : const Color(0xFF1565C0))),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    _requestSubmitted
                        ? '管理员审批通过后将自动解锁，请耐心等待'
                        : '提交后管理员审批通过将自动解锁',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (!_requestSubmitted) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarkController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        hintText: '输入身份确认信息（如姓名或订单号）',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                        isDense: true,
                        counterText: '',
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submitRequest,
                        icon: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: Text(_submitting ? '提交中...' : '提交申请'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 验证码输入（离线兜底）
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('输入验证码（离线兜底）', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    maxLength: 8,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 20, letterSpacing: 4, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'XXXXXXXX',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _verifyCode(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _verifying ? null : _verifyCode,
                      icon: _verifying
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.lock_open),
                      label: Text(_verifying ? '验证中...' : '验证解锁'),
                    ),
                  ),

                  // 提示消息
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_message ?? '', style: const TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 易青岚高级课笔记（已解锁时显示进入按钮）
          if (_unlockedFeatures.contains('F006'))
            Card(
              color: Colors.brown.shade50,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: const Icon(Icons.menu_book, color: Color(0xFF5D4037), size: 28),
                title: const Text('易青岚高级课笔记', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                subtitle: const Text('40课时六爻进阶课程', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseNotesScreen()));
                },
              ),
            ),

          const SizedBox(height: 16),

          // 已解锁功能
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('功能列表', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...lockedFeatures.map((feature) {
                    final isUnlocked = _unlockedFeatures.contains(feature.code);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isUnlocked ? Icons.lock_open : Icons.lock,
                        color: isUnlocked ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      title: Text(feature.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(feature.description, style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        isUnlocked ? '已解锁' : '未解锁',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? Colors.green : Colors.grey,
                          fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
