/// 隐私政策页面
library;

import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '隐私政策',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 16),
            _section('1. 信息收集',
              '本应用（六爻助手）不会主动收集您的个人身份信息。\n\n'
              '排盘记录仅存储在您的设备本地数据库中，不会上传至任何服务器。'),
            _section('2. 相机权限',
              '拍照识别功能需要相机权限，仅用于拍摄排盘图片进行OCR文字识别。'
              '拍摄的照片仅在设备本地处理，不会上传。'),
            _section('3. 存储权限',
              '用于保存排盘截图和导出Markdown排盘文档。'
              '所有文件均存储在设备本地。'),
            _section('4. 网络使用',
              '本应用为纯离线应用，除内置网页浏览器外，不会主动访问网络。\n'
              '• 内置浏览器：仅用于访问易青岚六爻学习社区（bbs.qlyxt.com），不会收集您的浏览数据\n'
              '• 排盘计算、OCR识别等核心功能完全离线运行，不会上传任何图片或数据'),
            _section('5. 数据安全',
              '所有排盘数据仅保存在您的设备本地SQLite数据库中，'
              '不会传输到互联网。您可以通过导出功能自行备份数据。'),
            _section('6. 第三方服务',
              '本应用集成了Google ML Kit（OCR文字识别），'
              '识别过程在设备本地完成，无需网络连接。'),
            _section('7. 政策更新',
              '本隐私政策可能不时更新。更新后的政策将在应用内公布。'),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '最后更新：2026年6月29日',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }
}
