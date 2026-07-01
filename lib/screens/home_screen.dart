import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../algorithms/ganzhi_converter.dart';
import '../providers/divination_provider.dart';
import '../screens/about_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/image_import_screen.dart';
import '../screens/import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _divTime;
  late GanZhiResult _ganZhi;
  bool _shareHandled = false;
  String _question = '';
  String _querentName = '';
  String _querentGender = '男';

  @override
  void initState() {
    super.initState();
    _divTime = DateTime.now();
    _updateGanZhi();
    _checkShareIntent();
  }

  static const _channel = MethodChannel('com.bobo.liuyao_app/share');

  void _checkShareIntent() async {
    try {
      final content = await _channel.invokeMethod<String>('getSharedFileContent');
      if (content != null && content.isNotEmpty) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_shareHandled) {
              _shareHandled = true;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImportScreen(sharedContent: content)),
              );
            }
          });
        }
      }
    } catch (_) {
      // 没有分享Intent，忽略
    }
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
    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setDivinationTime(_divTime);
    provider.setQuestion(_question);
    provider.setQuerentName(_querentName);
    provider.setQuerentGender(_querentGender);
    provider.setStartMethod('shake');
    Navigator.pushNamed(context, '/shake');
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/history');
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('yyyy年MM月dd日 HH:mm').format(_divTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('六爻助手'),
        actions: [
          // 颜色设置
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '颜色设置',
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.edit),
                        label: const Text('修改时间'),
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
              label: const Text('手动输入背面数'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            // 在线摇卦按钮
            ElevatedButton.icon(
              onPressed: _navigateToShake,
              icon: const Icon(Icons.casino),
              label: const Text('在线摇卦'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            // 拍照导入按钮
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImageImportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('拍照导入排盘'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
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
          ],
        ),
      ),
    );
  }
}