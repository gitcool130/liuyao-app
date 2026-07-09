import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/privacy_screen.dart';

class PrivacyConsentDialog extends StatefulWidget {
  final VoidCallback onAccepted;

  const PrivacyConsentDialog({super.key, required this.onAccepted});

  @override
  State<PrivacyConsentDialog> createState() => _PrivacyConsentDialogState();
}

class _PrivacyConsentDialogState extends State<PrivacyConsentDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.privacy_tip_outlined,
                size: 64,
                color: Color(0xFF8B4513),
              ),
              const SizedBox(height: 24),
              const Text(
                '隐私政策提示',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '在使用六爻助手之前，请仔细阅读并同意隐私政策。\n\n'
                '您可以在"关于"页面随时查看完整隐私政策。',
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Card(
                color: Color(0xFFF5F0E8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('隐私政策概要：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 6),
                      Text('• 排盘数据仅存储在本地，不上传服务器', style: TextStyle(fontSize: 12)),
                      SizedBox(height: 4),
                      Text('• 摇卦手摇模式需使用重力加速度传感器', style: TextStyle(fontSize: 12)),
                      SizedBox(height: 4),
                      Text('• 拍照功能用于OCR识别，处理在本地完成', style: TextStyle(fontSize: 12)),
                      SizedBox(height: 4),
                      Text('• 内置浏览器用于访问易青岚论坛', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 明示同意复选框
              CheckboxListTile(
                value: _agreed,
                onChanged: (value) {
                  setState(() {
                    _agreed = value ?? false;
                  });
                },
                title: const Text(
                  '我已阅读并同意隐私政策',
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF8B4513),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agreed ? widget.onAccepted : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('同意并继续', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  );
                },
                child: const Text('阅读完整隐私政策'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('提示'),
                      content: const Text(
                        '您选择拒绝隐私政策，将无法使用本应用。\n\n'
                        '如果您同意，请点击"返回"按钮返回上一页并勾选同意隐私政策。',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('返回'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            // 退出应用
                            SystemNavigator.pop();
                          },
                          child: const Text('拒绝并退出', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('拒绝', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
