/// 内置网页浏览器
/// 指向易青岚六爻学习社区
/// 支持恢复上次访问页面（1-2小时内）
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserScreen extends StatefulWidget {
  final String title;
  final String url;

  const BrowserScreen({
    super.key,
    this.title = '易青岚论坛',
    this.url = 'https://bbs.qlyxt.com',
  });

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;

  static const String _prefsKeyUrl = 'browser_last_url';
  static const String _prefsKeyTime = 'browser_last_time';
  static const Duration _maxAge = Duration(hours: 2);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() => _loading = true);
          _saveCurrentUrl(url);
        },
        onPageFinished: (_) => setState(() => _loading = false),
        onProgress: (p) => setState(() => _progress = p / 100),
      ))
      ..loadRequest(Uri.parse(widget.url));

    // 异步恢复上次访问页面（2小时内）
    _tryRestore();
  }

  /// 异步尝试恢复上次访问页面
  Future<void> _tryRestore() async {
    final savedUrl = await _getLastBrowserUrl();
    if (savedUrl != null && savedUrl != widget.url && mounted) {
      await _controller.loadRequest(Uri.parse(savedUrl));
    }
  }

  /// 从 SharedPreferences 读取上次访问 URL（2小时内有效）
  Future<String?> _getLastBrowserUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUrl = prefs.getString(_prefsKeyUrl);
    final lastTime = prefs.getInt(_prefsKeyTime);
    if (lastUrl == null || lastTime == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - lastTime > _maxAge.inMilliseconds) {
      return null;
    }
    return lastUrl;
  }

  /// 持久化当前页面URL
  Future<void> _saveCurrentUrl(String url) async {
    if (url.isEmpty || url == 'about:blank') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyUrl, url);
    await prefs.setInt(_prefsKeyTime, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading)
            LinearProgressIndicator(value: _progress, minHeight: 2),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
