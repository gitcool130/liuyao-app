/// 六爻助手解锁 - 管理员工具
/// 手动生成验证码 + 待审批申请列表
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

const String _secretKey = 'LiuYaoAssistant-2026-KeyCode';
const String _serverUrl = 'http://182.92.214.89:3456';
const String _adminKey = 'LiyaoAdmin_Secret_2026';

const List<Map<String, String>> _features = [
  {'code': 'F005', 'name': '神煞详解', 'desc': '神煞含义详解与吉凶分析'},
  {'code': 'F006', 'name': '易青岚高级课笔记', 'desc': '45课时六爻进阶课程'},
  {'code': 'F007', 'name': '易青岚论坛', 'desc': '访问易青岚六爻学习社区'},
];

String generateCode(String deviceId, String featureCode, String expireDate) {
  final data = utf8.encode('$deviceId|$featureCode|$expireDate');
  final key = utf8.encode(_secretKey);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(data);
  return digest.toString().substring(0, 8).toUpperCase();
}

String defaultExpireDate() {
  final n = DateTime.now().add(const Duration(days: 365));
  return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
}

void main() => runApp(const AdminToolApp());

class AdminToolApp extends StatelessWidget {
  const AdminToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '六爻助手解锁',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D4037)),
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4513), foregroundColor: Colors.white, centerTitle: true,
        ),
      ),
      home: const AdminToolScreen(),
    );
  }
}

class AdminToolScreen extends StatefulWidget {
  const AdminToolScreen({super.key});

  @override
  State<AdminToolScreen> createState() => _AdminToolScreenState();
}

class _AdminToolScreenState extends State<AdminToolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('六爻助手解锁'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '手动生成', icon: Icon(Icons.vpn_key, size: 18)),
            Tab(text: '待审批', icon: Icon(Icons.pending_actions, size: 18)),
            Tab(text: '配置', icon: Icon(Icons.settings, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ManualGenerateTab(),
          _PendingRequestsTab(onApproved: () => _tabCtrl.animateTo(0)),
          _ConfigTab(),
        ],
      ),
    );
  }
}

// ==================== Tab 1: 手动生成验证码 ====================

class _ManualGenerateTab extends StatefulWidget {
  @override
  State<_ManualGenerateTab> createState() => _ManualGenerateTabState();
}

class _ManualGenerateTabState extends State<_ManualGenerateTab> {
  final _deviceIdCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  late Map<String, bool> _selections;
  final _results = <_CodeResult>[];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = defaultExpireDate();
    _selections = {for (final f in _features) f['code']!: true};
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String get _combinedCode =>
      _selections.entries.where((e) => e.value).map((e) => e.key).join(',');
  bool get _anySelected => _selections.values.any((v) => v);

  void _doGenerate() {
    final deviceId = _deviceIdCtrl.text.trim();
    if (deviceId.isEmpty) { _msg('请输入设备ID'); return; }
    if (!_anySelected) { _msg('请至少选择一个功能'); return; }
    final dateStr = _dateCtrl.text.trim();
    if (dateStr.length != 8 || int.tryParse(dateStr) == null) { _msg('日期格式错误'); return; }

    final code = generateCode(deviceId, _combinedCode, dateStr);
    final names = _selections.entries
        .where((e) => e.value)
        .map((e) => _features.firstWhere((f) => f['code'] == e.key)['name']!)
        .join(', ');

    setState(() => _results.insert(0, _CodeResult(deviceId, code, names, dateStr)));
    _msg('验证码已生成: $code');
  }

  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card([const Text('设备ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _deviceIdCtrl, maxLines: 3,
          decoration: InputDecoration(hintText: '粘贴用户发来的设备ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(icon: const Icon(Icons.paste),
              onPressed: () async {
                final d = await Clipboard.getData(Clipboard.kTextPlain);
                if (d?.text != null) _deviceIdCtrl.text = d!.text!.trim(); },),),)]),

      const SizedBox(height: 12),
      _card([Row(children: [const Text('选择功能', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _selections = {for (final f in _features) f['code']!: true}),
          child: const Text('全选', style: TextStyle(fontSize: 12))),]),
        ..._features.map((f) => CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true,
          title: Text('${f['code']} ${f['name']}', style: const TextStyle(fontSize: 14)),
          value: _selections[f['code']] ?? false,
          activeColor: const Color(0xFF5D4037),
          onChanged: (v) => setState(() => _selections[f['code']!] = v ?? false),)),]),

      const SizedBox(height: 12),
      _card([const Text('过期日期', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _dateCtrl, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          _chip('3月', dateStr(Duration(days: 90))), _chip('6月', dateStr(Duration(days: 180))),
          _chip('1年', dateStr(Duration(days: 365))), _chip('永久', '20991231'),]),]),

      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 48,
        child: ElevatedButton.icon(onPressed: _doGenerate, icon: const Icon(Icons.vpn_key),
          label: const Text('生成验证码', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white))),

      if (_results.isNotEmpty) ...[
        const SizedBox(height: 16),
        ..._results.map((r) => Card(color: Colors.brown.shade50, margin: const EdgeInsets.only(bottom: 12),
          child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: SelectableText(r.code,
                style: const TextStyle(fontSize: 28, letterSpacing: 4, fontFamily: 'monospace',
                    fontWeight: FontWeight.bold, color: Color(0xFF5D4037)))),
                IconButton(icon: const Icon(Icons.copy), onPressed: () {
                  Clipboard.setData(ClipboardData(text: r.code));
                  _msg('已复制'); }),]),
              Text(r.featureNames, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              Text('设备: ${r.deviceId}  过期: ${r.expireDate}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),],)),)),
      ],
    ]);
  }

  Widget _card(List<Widget> c) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: c)));
  Widget _chip(String l, String d) => ActionChip(label: Text(l, style: const TextStyle(fontSize: 12)), onPressed: () => setState(() => _dateCtrl.text = d));

  String dateStr(Duration d) {
    final n = DateTime.now().add(d);
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }
}

class _CodeResult {
  final String deviceId, code, featureNames, expireDate;
  _CodeResult(this.deviceId, this.code, this.featureNames, this.expireDate);
}

// ==================== Tab 2: 待审批申请 ====================

class _PendingRequestsTab extends StatefulWidget {
  final VoidCallback onApproved;
  const _PendingRequestsTab({required this.onApproved});

  @override
  State<_PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<_PendingRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final c = HttpClient();
      final r = await c.getUrl(Uri.parse('$_serverUrl/api/pending_requests?adminKey=$_adminKey'));
      final resp = await r.close();
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        setState(() => _requests = (json['data'] as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取失败，请检查网络')));
    }
    setState(() => _loading = false);
  }

  Future<void> _approve(Map<String, dynamic> req) async {
    final id = req['id'];
    // 选择功能和有效期
    final features = <String>['F005','F006','F007'];
    String expireDate = '20261231';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ApproveDialog(features: features, expireDate: expireDate),
    );
    if (result == null) return;

    try {
      final c = HttpClient();
      final r = await c.postUrl(Uri.parse('$_serverUrl/api/approve_request'));
      r.headers.contentType = ContentType.json;
      r.write(jsonEncode({
        'adminKey': _adminKey,
        'requestId': id,
        'features': result['features'],
        'expireDate': result['expireDate'],
      }));
      final resp = await r.close();
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 审批通过，验证码: ${json['data']['code']}')));
        _fetch();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${json['message'] ?? '审批失败'}')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 网络错误')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? ListView(children: const [SizedBox(height: 200,
                  child: Center(child: Text('暂无待审批申请', style: TextStyle(color: Colors.grey, fontSize: 16))))])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _requests.length,
                  itemBuilder: (ctx, i) => _buildCard(_requests[i]),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_outline, size: 16, color: Color(0xFF5D4037)),
          const SizedBox(width: 6),
          Text(req['deviceHash'] ?? '', style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(req['remark'] ?? '(无备注)', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ]),
        const SizedBox(height: 4),
        Text('IP: ${req['applicantIp'] ?? '未知'}  时间: ${req['createdAt'] ?? ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(onPressed: () => _approve(req),
            child: const Text('审批通过', style: TextStyle(fontSize: 13))),
        ]),
      ]),
    ));
  }
}

// ==================== Tab 3: 配置管理 ====================

class _ConfigTab extends StatefulWidget {
  @override
  State<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<_ConfigTab> {
  final _currentPwdCtrl = TextEditingController();
  final _newAdminKeyCtrl = TextEditingController();
  final _newSecretKeyCtrl = TextEditingController();
  bool _saving = false;
  String? _msg;

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newAdminKeyCtrl.dispose();
    _newSecretKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final currentPassword = _currentPwdCtrl.text.trim();
    if (currentPassword.isEmpty) { _show('请输入当前管理员密钥'); return; }

    final newAdminKey = _newAdminKeyCtrl.text.trim();
    final newSecretKey = _newSecretKeyCtrl.text.trim();
    if (newAdminKey.isEmpty && newSecretKey.isEmpty) { _show('请至少填写一项修改内容'); return; }

    setState(() { _saving = true; _msg = null; });

    try {
      final client = HttpClient();
      final req = await client.postUrl(Uri.parse('$_serverUrl/api/update_config'));
      req.headers.contentType = ContentType.json;
      final body = <String, dynamic>{'adminKey': _adminKey, 'currentPassword': currentPassword};
      if (newAdminKey.isNotEmpty) body['newAdminKey'] = newAdminKey;
      if (newSecretKey.isNotEmpty) body['newSecretKey'] = newSecretKey;
      req.write(jsonEncode(body));
      final resp = await req.close();
      final resBody = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(resBody) as Map<String, dynamic>;

      if (json['success'] == true) {
        _show('✅ ${json['message'] ?? '配置已更新'}');
        _currentPwdCtrl.clear();
        _newAdminKeyCtrl.clear();
        _newSecretKeyCtrl.clear();
      } else {
        _show('❌ ${json['message'] ?? '更新失败'}');
      }
    } catch (e) {
      _show('❌ 网络错误: $e');
    }
    setState(() => _saving = false);
  }

  void _show(String m) { setState(() => _msg = m); }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('修改配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('修改后即时生效，无需重启服务', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),

        const Text('当前管理员密钥（用于验证身份）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(controller: _currentPwdCtrl, obscureText: true,
          decoration: const InputDecoration(hintText: '输入当前管理员密钥',
            border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
        ),

        const SizedBox(height: 16),
        const Divider(),
        const Text('新管理员密钥', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(controller: _newAdminKeyCtrl,
          decoration: const InputDecoration(hintText: '留空则不修改，至少8位',
            border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
        ),

        const SizedBox(height: 16),
        const Divider(),
        const Text('新解锁码密钥', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(controller: _newSecretKeyCtrl,
          decoration: const InputDecoration(hintText: '留空则不修改，至少8位。修改后旧码失效',
            border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
        ),

        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(8), color: Colors.orange.shade50,
          child: Text('⚠️ 修改解锁码密钥后，所有已生成的验证码将立即失效',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900))),

        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_saving ? '保存中...' : '保存配置'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white))),

        if (_msg != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_msg!, style: const TextStyle(fontSize: 13))),
      ],))),
    ]);
  }
}

/// 审批对话框
class _ApproveDialog extends StatefulWidget {
  final List<String> features;
  final String expireDate;
  const _ApproveDialog({required this.features, required this.expireDate});

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  late List<String> _selected;
  late String _expireDate;
  late TextEditingController _dateCtrl;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.features);
    _expireDate = widget.expireDate;
    _dateCtrl = TextEditingController(text: _expireDate);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('审批设置'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('解锁功能:', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._features.map((f) => CheckboxListTile(
          contentPadding: EdgeInsets.zero, dense: true,
          title: Text('${f['code']} ${f['name']}'),
          value: _selected.contains(f['code']),
          onChanged: (v) => setState(() {
            v == true ? _selected.add(f['code']!) : _selected.remove(f['code']);
          }),
        )),
        const SizedBox(height: 8),
        TextField(controller: _dateCtrl,
          decoration: const InputDecoration(labelText: '过期日期(YYYYMMDD)',
            border: OutlineInputBorder(), isDense: true),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          Navigator.pop(context, {
            'features': List.from(_selected),
            'expireDate': _dateCtrl.text.trim(),
          });
        }, child: const Text('确认审批')),
      ],
    );
  }
}
