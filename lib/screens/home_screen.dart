import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../algorithms/ganzhi_converter.dart';
import '../providers/divination_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/about_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/unlock_screen.dart';
import '../screens/course_notes_screen.dart';
import '../screens/shensha_detail_screen.dart';
import '../screens/browser_screen.dart';
import '../screens/ganzhi_paipan_screen.dart';
import '../screens/image_import_screen.dart';
import '../services/feature_lock_service.dart';
import '../services/update_manager.dart';
import '../utils/platform_support.dart';
import '../version.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _divTime;
  late GanZhiResult _ganZhi;
  String _question = '';
  String _querentName = '';
  String _querentGender = '男';
  List<String> _unlockedFeatures = [];
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _divTime = DateTime.now();
    _loadUnlocked();
    _updateGanZhi();
    _checkPendingInstall();
    _checkUpdate();
    _checkAutoUnlock();
  }

  void _updateGanZhi() {
    _ganZhi = GanZhiConverter.convert(_divTime);
  }

  void _selectTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _divTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_divTime),
      );
      if (timePicked != null) {
        setState(() {
          _divTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
          _updateGanZhi();
        });
      }
    }
  }

  void _loadUnlocked() async {
    final unlocked = await FeatureLockService.getUnlockedFeatures();
    if (mounted) setState(() => _unlockedFeatures = unlocked);
  }

  /// 检查是否有待安装的安装包（上次退出时未安装）
  void _checkPendingInstall() async {
    // 更新包是 Android apk，桌面端不适用
    if (isDesktop) return;
    final hasPending = await UpdateManager.hasPendingInstall();
    if (!mounted || !hasPending) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.system_update, color: Colors.orange),
          SizedBox(width: 8),
          Text('更新待安装'),
        ]),
        content: const Text('检测到有已下载的更新包，是否立即安装？'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); UpdateManager.cleanUp(); },
            child: const Text('忽略'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await UpdateManager.install();
              if (err != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('安装失败：$err')),
                );
              }
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  /// 检查更新
  void _checkUpdate() async {
    // 桌面端不做 apk 更新检查
    if (isDesktop) return;
    // 延迟1秒让UI先加载完成，同时让用户感知到确实在联网检查
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final info = await UpdateManager.checkUpdate(kAppBuildNumber);
    if (!mounted || info == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.system_update, color: Colors.blue),
          SizedBox(width: 8),
          Text('发现新版本'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('v${info.version} (构建${info.buildNumber})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(info.description, style: TextStyle(color: Colors.grey.shade700)),
            if (info.changelog.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text('更新内容:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(info.changelog, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
            if (info.apkSize > 0) ...[
              const SizedBox(height: 6),
              Text('APK大小: ${(info.apkSize / 1048576).toStringAsFixed(1)}MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('稍后')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startUpdate(info);
            },
            child: const Text('下载更新'),
          ),
        ],
      ),
    );
  }

  /// 自动检查解锁申请状态（审批通过后自动解锁）
  void _checkAutoUnlock() async {
    if (_unlockedFeatures.contains('F005')) return;
    final deviceId = await FeatureLockService.getDeviceId();
    if (deviceId.isEmpty) return;

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
          setState(() => _unlockedFeatures = lockedFeatures.map((f) => f.code).toList());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ 解锁申请已通过，功能已自动解锁！')),
            );
          }
        }
      }
    }
  }

  /// 下载更新（底部进度条显示）
  void _startUpdate(UpdateInfo info) async {
    setState(() => _downloading = true);
    UpdateManager.onProgress = (p) {
      if (mounted) setState(() => _downloadProgress = p);
    };

    final ok = await UpdateManager.startDownload(info);
    if (!mounted) return;
    setState(() { _downloading = false; _downloadProgress = 0; });

    if (ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('下载完成'),
          ]),
          content: const Text('更新包已下载并校验通过，是否立即安装？\n\n选择"稍后"可稍后在首页提示安装。'),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); },
              child: const Text('稍后'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final err = await UpdateManager.install();
                if (err != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('安装失败：$err')),
                  );
                } else {
                  UpdateManager.cleanUp();
                }
              },
              child: const Text('立即安装'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载失败，下次启动自动续传')),
      );
    }
  }

  void _navigateToManualInput() {
    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setDivinationTime(_divTime);
    provider.setQuestion(_question);
    provider.setQuerentName(_querentName);
    provider.setQuerentGender(_querentGender);
    provider.setStartMethod('manual');
    Navigator.pushNamed(context, '/manual');
  }

  void _navigateToShake() {
    if (isDesktop) {
      _unsupported('在线起卦（摇一摇）');
      return;
    }
    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setDivinationTime(_divTime);
    provider.setQuestion(_question);
    provider.setQuerentName(_querentName);
    provider.setQuerentGender(_querentGender);
    provider.setStartMethod('shake');
    Navigator.pushNamed(context, '/shake');
  }

  /// 桌面端不支持的功能统一提示
  void _unsupported(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(feature),
        content: Text(desktopUnsupportedHint(feature)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
        ],
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/history');
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('yyyy年MM月dd日 HH:mm').format(_divTime);

    return Scaffold(
      bottomNavigationBar: _downloading
          ? SizedBox(
              height: 4,
              child: LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
            )
          : null,
      appBar: AppBar(
        title: const Text('六爻助手'),
        actions: [
          // 设置
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '设置',
          ),
          // 说明菜单
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            tooltip: '使用说明',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 起卦时间卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '起卦时间',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('修改时间', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    // 农历：干支年 + 农历月日 + 时辰
                    Text(
                      '农历：${_ganZhi.yearGz}年 ${_ganZhi.lunarDate} ${_ganZhi.hourGz}时',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    if (_ganZhi.jieQiInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '节气：${_ganZhi.jieQiInfo}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '干支：${_ganZhi.yearGz}年 ${_ganZhi.monthGz}月 ${_ganZhi.dayGz}日 ${_ganZhi.hourGz}时',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 起卦人卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 18),
                    const SizedBox(width: 6),
                    const Text('起卦人', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '姓名',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) => _querentName = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: DropdownButtonFormField<String>(
                        value: _querentGender,
                        isDense: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '男', child: Text('男', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: '女', child: Text('女', style: TextStyle(fontSize: 14))),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _querentGender = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 问题输入卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.question_answer, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '所问问题',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '请输入您要问的事项...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) => _question = value,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 起卦方式按钮
            const Text(
              '选择起卦方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 手动输入按钮
            ElevatedButton.icon(
              onPressed: _navigateToManualInput,
              icon: const Icon(Icons.edit_note),
              label: Text('手动排盘', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            // 在线起卦按钮
            ElevatedButton.icon(
              onPressed: _navigateToShake,
              icon: const Icon(Icons.casino),
              label: Text('在线起卦', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            // 干支排盘按钮：直接按「月建 + 日辰」起局，不依赖公历
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GanZhiPaiPanScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.event_note),
              label: Text('干支排盘', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // 拍照导入按钮（略带反差的配色）
            ElevatedButton.icon(
              onPressed: () {
                if (isDesktop) {
                  _unsupported('拍照导入排盘');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImageImportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: Text('拍照导入排盘', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),

            const SizedBox(height: 24),

            // 历史记录入口
            OutlinedButton.icon(
              onPressed: _navigateToHistory,
              icon: const Icon(Icons.history),
              label: const Text('历史记录'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 32),

            // === 易青岚学员专享 ===
            _buildVipSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVipSection() {
    final hasUnlocked = _unlockedFeatures.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.stars, size: 20, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text(
              '易青岚学员专享',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UnlockScreen()),
                );
                _loadUnlocked();
              },
              icon: Icon(Icons.lock_open, size: 14, color: Colors.amber.shade700),
              label: Text(
                hasUnlocked ? '已解锁' : '去解锁',
                style: TextStyle(fontSize: 12, color: hasUnlocked ? Colors.green : Colors.amber.shade700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 神煞详解
        _buildVipItem(
          icon: Icons.auto_awesome,
          title: '神煞详解',
          desc: '神煞含义详解与吉凶分析',
          unlocked: _unlockedFeatures.contains('F005'),
          color: Colors.purple,
          onTap: _unlockedFeatures.contains('F005')
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShenshaDetailScreen()))
              : null,
        ),

        const SizedBox(height: 8),

        // 高级课笔记
        _buildVipItem(
          icon: Icons.menu_book,
          title: '易青岚高级课笔记',
          desc: '40课时六爻进阶课程全文',
          unlocked: _unlockedFeatures.contains('F006'),
          color: Colors.brown,
          onTap: _unlockedFeatures.contains('F006')
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseNotesScreen()))
              : null,
        ),

        const SizedBox(height: 8),

        // 易青岚论坛
        _buildVipItem(
          icon: Icons.forum,
          title: '易青岚论坛',
          desc: '访问易青岚六爻学习社区',
          unlocked: _unlockedFeatures.contains('F007'),
          color: Colors.blue,
          onTap: _unlockedFeatures.contains('F007')
              ? () {
                  if (isDesktop) {
                    _unsupported('易青岚论坛（内置浏览器）');
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowserScreen()));
                }
              : null,
        ),

        if (!hasUnlocked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '输入验证码解锁学员专享功能',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
      ],
    );
  }

  Widget _buildVipItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool unlocked,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      color: unlocked ? null : Colors.grey.shade100,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          color: unlocked ? color : Colors.grey,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: unlocked ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          desc,
          style: TextStyle(fontSize: 12, color: unlocked ? Colors.grey.shade600 : Colors.grey.shade400),
        ),
        trailing: unlocked
            ? const Icon(Icons.chevron_right, color: Color(0xFF5D4037))
            : const Icon(Icons.lock, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }
}