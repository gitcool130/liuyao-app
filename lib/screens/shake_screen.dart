import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../algorithms/ganzhi_converter.dart';
import '../algorithms/constants.dart';
import '../algorithms/lunar_calendar.dart';
import '../providers/divination_provider.dart';
import '../widgets/coin_widget.dart';

/// 摇卦阶段
enum _Phase { idle, rotating, showing, complete }

/// 摇卦页面
/// 支持两种模式（页面内开关切换）：
///   - 手动模式：点击抛铜钱→旋转→点击停止→看结果
///   - 手摇模式：摇动手机→铜钱旋转→静止1秒→自动显示结果
class ShakeScreen extends StatefulWidget {
  const ShakeScreen({super.key});

  @override
  State<ShakeScreen> createState() => _ShakeScreenState();
}

class _ShakeScreenState extends State<ShakeScreen> {
  static const _fronts = [
    'assets/images/jq01.png', 'assets/images/kx01.png',
    'assets/images/ql01.jpg', 'assets/images/sz01.png', 'assets/images/yz01.png',
  ];
  static const _backs = ['assets/images/back01.png', 'assets/images/back02.png'];
  static const _yaoNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

  // --- 状态 ---
  _Phase _phase = _Phase.idle;
  int _currentThrow = 1;
  final List<int> _backCounts = [];
  int _currentBackCount = 0;
  late List<_Coin> _coins;
  bool _handShake = false;

  // --- 手摇模式传感器 ---
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _lastAccelMag = 9.8;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _initCoins();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _initCoins() {
    final fronts = List<String>.from(_fronts)..shuffle();
    _coins = fronts.take(3).map((f) {
      return _Coin(front: f, back: _backs[Random.secure().nextInt(_backs.length)], isHeads: true);
    }).toList();
  }

  void _toggleHandShake(bool on) {
    setState(() {
      _handShake = on;
      _shakeCount = 0;
      _lastShakeTime = null;
    });
    if (on) {
      _startSensors();
    } else {
      _accelSub?.cancel();
      _accelSub = null;
    }
  }

  // ============== 手摇传感器 ==============

  void _startSensors() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final diff = (mag - _lastAccelMag).abs();
      _lastAccelMag = mag;

      final now = DateTime.now();

      // 检测摇晃：加速度变化超过阈值
      // 在 idle 或 showing 状态下都可以触发（手摇模式下自动进入下一爻）
      if ((_phase == _Phase.idle || (_phase == _Phase.showing && _currentThrow < 6)) && diff > 3) {
        // 短时间内多次检测到摇晃才算真正开始摇
        if (_lastShakeTime != null && now.difference(_lastShakeTime!).inMilliseconds < 500) {
          _shakeCount++;
          if (_shakeCount >= 3) {
            // 如果在 showing 状态，先进入下一爻
            if (_phase == _Phase.showing) {
              _next();
            }
            // 等待一个短暂时间让状态稳定后开始旋转
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_phase == _Phase.idle) {
                _throw();
              }
            });
            _shakeCount = 0;
          }
        } else {
          _shakeCount = 1;
        }
        _lastShakeTime = now;
      }

      // 检测静止：连续低变化表示停止摇晃
      if (_phase == _Phase.rotating && diff < 1.5) {
        if (_lastShakeTime != null && now.difference(_lastShakeTime!).inMilliseconds > 800) {
          // 停止摇晃超过800ms，自动显示结果
          _stop();
        }
      } else if (_phase == _Phase.rotating && diff >= 1.5) {
        _lastShakeTime = now;
      }
    });
  }

  // ============== 阶段操作 ==============

  void _throw() {
    final rng = Random.secure();  // 使用安全随机源，避免伪随机的序列重复
    setState(() {
      for (final c in _coins) {
        c.isHeads = rng.nextBool();
        c.animating = true;
        c.stopping = false;
      }
      _phase = _Phase.rotating;
    });
  }

  void _stop() {
    setState(() {
      for (final c in _coins) {
        c.stopping = true;
      }
      _currentBackCount = _coins.where((c) => !c.isHeads).length;
      _backCounts.add(_currentBackCount);
      _shakeCount = 0;
      _lastShakeTime = null;

      // 第六爻完成后直接进入完成状态
      if (_currentThrow == 6) {
        _phase = _Phase.complete;
      } else {
        _phase = _Phase.showing;
      }
    });
  }

  void _next() {
    _shakeCount = 0;
    _lastShakeTime = null;
    if (_currentThrow < 6) {
      setState(() {
        _currentThrow++;
        for (final c in _coins) {
          c.isHeads = true;
          c.animating = false;
          c.stopping = false;
        }
        _phase = _Phase.idle;
      });
    } else {
      setState(() => _phase = _Phase.complete);
    }
  }

  void _finish() {
    _accelSub?.cancel();
    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setBackCounts(_backCounts);
    provider.calculate();
    Navigator.pushReplacementNamed(context, '/result');
  }

  // ============== 辅助 ==============

  static String _yaoType(int n) => switch (n) {
    0 => '老阴（动爻）', 1 => '少阳（静爻）', 2 => '少阴（静爻）', 3 => '老阳（动爻）', _ => '',
  };
  static String _yaoSymbol(int n) => switch (n) {
    0 => '▅▅　▅▅×', 1 => '▅▅▅▅▅', 2 => '▅▅　▅▅', 3 => '▅▅▅▅▅○', _ => '',
  };
  static bool _isDong(int n) => n == 0 || n == 3;

  // ============== UI ==============

  @override
  Widget build(BuildContext context) {
    // 判断是否是第六爻且已显示结果
    final isLastYaoDone = _currentThrow == 6 && _phase == _Phase.showing;

    return Scaffold(
      appBar: AppBar(
        title: Text('第 $_currentThrow/6 爻'),
        actions: [
          // AppBar 右侧手摇开关
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('手摇', style: TextStyle(fontSize: 13)),
              Switch(
                value: _handShake,
                onChanged: _toggleHandShake,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _CoinTray(coins: _coins, phase: _phase),
                    const SizedBox(height: 12),
                    // 按钮放在铜钱下方
                    if (!_handShake)
                      _ActionButtons(
                        phase: _phase,
                        isLastYaoDone: isLastYaoDone,
                        onThrow: _throw,
                        onStop: _stop,
                        onNext: _next,
                        onFinish: _finish,
                      ),
                    if (_handShake && _phase == _Phase.complete)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _FinishButton(onFinish: _finish),
                      ),
                    // 按时间起卦按钮
                    if (_phase != _Phase.rotating)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _showTimeDivinationSheet(context),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('按时间起卦', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_phase == _Phase.rotating && _handShake)
                      _HintBanner('停止摇动后自动揭晓'),
                    if (_phase == _Phase.rotating && !_handShake)
                      _HintBanner('旋转中，点击下方按钮停止'),
                    if (_phase == _Phase.idle && _handShake)
                      _HintBanner('请摇动手机'),
                    if (_phase == _Phase.showing)
                      _ResultCard(name: _yaoNames[_currentThrow - 1], backCount: _currentBackCount),
                  ],
                ),
              ),
            ),
            _ProgressPanel(backCounts: _backCounts),
          ],
        ),
      ),
    );
  }

  // ============== 按时间起卦 ==============

  /// 八卦→三爻背面数 (从下往上: 初→二→三)
  static const _trigramYaos = {
    0: [2, 2, 2], // 坤
    1: [1, 1, 1], // 乾
    2: [1, 1, 2], // 兑
    3: [1, 2, 1], // 离
    4: [1, 2, 2], // 震
    5: [2, 1, 1], // 巽
    6: [2, 1, 2], // 坎
    7: [2, 2, 1], // 艮
  };

  void _showTimeDivinationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _TimeDivinationSheet(onSubmit: (dt, seasonOffset, instantMinute) => _doTimeDivination(dt, seasonOffset, instantMinute)),
    );
  }

  void _doTimeDivination(DateTime dt, [bool seasonOffset = true, bool instantMinute = false]) {
    final gz = GanZhiConverter.convert(dt);
    final yearNum = diZhi.indexOf(gz.yearZhi) + 1;
    // 月数使用节气月支：寅=1,卯=2,...,丑=12
    int monthNum = diZhi.indexOf(gz.monthZhi) + 1;
    // 日数使用农历日（传统时间起卦惯例）
    final lunar = LunarCalendar.solarToLunar(dt);
    final dayNum = lunar[2];
    final hourNum = diZhi.indexOf(gz.hourZhi) + 1;

    if (instantMinute) {
      // 即时时分起卦：月+日+时辰做上卦，月+日+时辰+分支做下卦+动爻
      final hour = dt.hour;
      final minute = dt.minute;
      // 计算分支（每10分钟一个地支）
      int shiChenStartHour;
      if (hour == 0 || hour == 23) {
        shiChenStartHour = 23; // 子时
      } else {
        shiChenStartHour = hour.isOdd ? hour : hour - 1;
      }
      int minutesIntoShiChen;
      if (hour == 23) {
        minutesIntoShiChen = minute;
      } else if (hour == 0) {
        minutesIntoShiChen = 60 + minute;
      } else {
        minutesIntoShiChen = (hour - shiChenStartHour) * 60 + minute;
      }
      final minuteBranch = minutesIntoShiChen ~/ 10 + 1; // 1-12
      final upperNum = (monthNum + dayNum + hourNum) % 8;
      final lowerNum = (monthNum + dayNum + hourNum + minuteBranch) % 8;
      final movingRem = (monthNum + dayNum + hourNum + minuteBranch) % 6;
      _executeDivination(dt, upperNum, lowerNum, movingRem);
      return;
    }

    final upperNum = (yearNum + monthNum + dayNum) % 8;
    final lowerNum = (yearNum + monthNum + dayNum + hourNum) % 8;
    final movingRem = (yearNum + monthNum + dayNum + hourNum) % 6;
    _executeDivination(dt, upperNum, lowerNum, movingRem);
  }

  void _executeDivination(DateTime dt, int upperNum, int lowerNum, int movingRem) {

    final backCounts = List.filled(6, 0);
    final lower = _trigramYaos[lowerNum]!;
    final upper = _trigramYaos[upperNum]!;
    for (int i = 0; i < 3; i++) {
      backCounts[i] = lower[i];
      backCounts[i + 3] = upper[i];
    }

    final moveIndex = movingRem == 0 ? 5 : movingRem - 1;
    final original = backCounts[moveIndex];
    backCounts[moveIndex] = original == 1 ? 3 : 0;

    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setDivinationTime(dt);
    provider.setBackCounts(backCounts);
    provider.calculate();
    Navigator.pushReplacementNamed(context, '/result');
  }
}

// ============== 铜钱数据 ==============

class _Coin {
  final String front;
  final String back;
  bool isHeads;
  bool animating = false;
  bool stopping = false;
  _Coin({required this.front, required this.back, this.isHeads = true});
}

// ============== 子组件 ==============

class _CoinTray extends StatelessWidget {
  final List<_Coin> coins;
  final _Phase phase;
  const _CoinTray({required this.coins, required this.phase});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in coins)
              CoinWidget(
                frontImage: c.front,
                backImage: c.back,
                finalResult: c.isHeads,
                startAnimation: c.animating,
                stopAndShowResult: c.stopping,
              ),
          ],
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  final String text;
  const _HintBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.orange.shade800)),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String name;
  final int backCount;
  const _ResultCard({required this.name, required this.backCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('$name：$backCount背',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
          const SizedBox(height: 6),
          Text(_ShakeScreenState._yaoType(backCount), style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 6),
          // 爻象符号
          Text(_ShakeScreenState._yaoSymbol(backCount),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
            maxLines: 1),
        ],
      ),
    );
  }
}

/// 操作按钮组件（放在铜钱下方）
class _ActionButtons extends StatelessWidget {
  final _Phase phase;
  final bool isLastYaoDone;
  final VoidCallback onThrow, onStop, onNext, onFinish;
  const _ActionButtons({
    required this.phase,
    required this.isLastYaoDone,
    required this.onThrow,
    required this.onStop,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    // 第六爻摇完直接显示"进行排卦"
    if (isLastYaoDone) {
      return _FinishButton(onFinish: onFinish);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: switch (phase) {
        _Phase.idle => _btn('抛铜钱', onThrow),
        _Phase.rotating => _btn('看结果', onStop, color: Colors.orange.shade700),
        _Phase.showing => _btn('下一爻', onNext),
        _Phase.complete => _FinishButton(onFinish: onFinish),
      },
    );
  }

  Widget _btn(String label, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color != null ? Colors.white : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// 进行排卦按钮
class _FinishButton extends StatelessWidget {
  final VoidCallback onFinish;
  const _FinishButton({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('进行排卦', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// 时间起卦底部面板
typedef _TimeSubmitCallback = void Function(DateTime dt, bool seasonOffset, bool instantMinute);

class _TimeDivinationSheet extends StatefulWidget {
  final _TimeSubmitCallback onSubmit;
  const _TimeDivinationSheet({required this.onSubmit});

  @override
  State<_TimeDivinationSheet> createState() => _TimeDivinationSheetState();
}

class _TimeDivinationSheetState extends State<_TimeDivinationSheet> {
  late DateTime _dateTime;
  bool _customTime = false;
  bool _seasonOffset = true;
  bool _instantMinute = false;

  @override
  void initState() {
    super.initState();
    _dateTime = DateTime.now();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _dateTime = DateTime(d.year, d.month, d.day, _dateTime.hour, _dateTime.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (t != null) setState(() => _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF5D4037)),
              const SizedBox(width: 8),
              const Text('按时间起卦', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('公式：年+月+日→上卦，年+月+日+时→下卦+动爻',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF5D4037)),
                      const SizedBox(width: 8),
                      Text(
                        '${_dateTime.year}年${_dateTime.month}月${_dateTime.day}日 '
                        '${_dateTime.hour.toString().padLeft(2, '0')}时${_dateTime.minute.toString().padLeft(2, '0')}分',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // 1. 节气月偏移
                  Row(
                    children: [
                      const Text('节气月偏移', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      Switch(
                        value: _seasonOffset,
                        activeColor: const Color(0xFF5D4037),
                        onChanged: (v) => setState(() => _seasonOffset = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // 2. 即时时分起卦
                  Row(
                    children: [
                      const Text('即时时分起卦', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      Switch(
                        value: _instantMinute,
                        activeColor: const Color(0xFF5D4037),
                        onChanged: _customTime ? null : (v) => setState(() {
                          _instantMinute = v;
                          if (v) { _customTime = false; _dateTime = DateTime.now(); }
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // 3. 指定时间
                  Row(
                    children: [
                      const Text('指定时间', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      Switch(
                        value: _customTime,
                        activeColor: const Color(0xFF5D4037),
                        onChanged: _instantMinute ? null : (v) => setState(() {
                          _customTime = v;
                          if (v) _instantMinute = false;
                        }),
                      ),
                    ],
                  ),
                  if (!_instantMinute && _customTime) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.edit_calendar, size: 16),
                            label: Text(
                              '${_dateTime.year}-${_dateTime.month.toString().padLeft(2, '0')}-${_dateTime.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(
                              '${_dateTime.hour.toString().padLeft(2, '0')}:${_dateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Card(
            color: Colors.brown.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildResultPreview(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSubmit(_dateTime, _seasonOffset, _instantMinute);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('开始排盘', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPreview() {
    final gz = GanZhiConverter.convert(_dateTime);
    final lunar = LunarCalendar.solarToLunar(_dateTime);
    final y = diZhi.indexOf(gz.yearZhi) + 1;
    final d = lunar[2];
    final h = diZhi.indexOf(gz.hourZhi) + 1;

    int m = lunar[1].abs();
    if (!_instantMinute && _seasonOffset) {
      final monthZhiNum = diZhi.indexOf(gz.monthZhi) + 1;
      int expectedMonth = (monthZhiNum + 10) % 12;
      if (expectedMonth == 0) expectedMonth = 12;
      if (m < expectedMonth) m = m + 1;
    }

    int upper, lower, movingRem, minuteBranch = 0;
    if (_instantMinute) {
      final hour = _dateTime.hour;
      final minute = _dateTime.minute;
      int sStart;
      if (hour == 0 || hour == 23) { sStart = 23; }
      else { sStart = hour.isOdd ? hour : hour - 1; }
      int minutesIn;
      if (hour == 23) { minutesIn = minute; }
      else if (hour == 0) { minutesIn = 60 + minute; }
      else { minutesIn = (hour - sStart) * 60 + minute; }
      minuteBranch = minutesIn ~/ 10 + 1;
      upper = (m + d + h) % 8;
      lower = (m + d + h + minuteBranch) % 8;
      movingRem = (m + d + h + minuteBranch) % 6;
    } else {
      upper = (y + m + d) % 8;
      lower = (y + m + d + h) % 8;
      movingRem = (y + m + d + h) % 6;
    }

    const trigramNames = ['坤', '乾', '兑', '离', '震', '巽', '坎', '艮'];
    const positionNames = ['', '初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_instantMinute
            ? '农历${lunar[1].abs()}月=$m  ${lunar[2]}日=$d  时${gz.hourZhi}=$h  分支${minuteBranch}'
            : '年支${gz.yearZhi}=$y  农历${lunar[1].abs()}月=$m  农历${lunar[2]}日=$d  时支${gz.hourZhi}=$h',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('上卦：${trigramNames[upper]}（余数$upper）', style: const TextStyle(fontSize: 13)),
        Text('下卦：${trigramNames[lower]}（余数$lower）', style: const TextStyle(fontSize: 13)),
        Text('动爻：${positionNames[movingRem == 0 ? 6 : movingRem]}（余数$movingRem）',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final List<int> backCounts;
  const _ProgressPanel({required this.backCounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('摇卦进度', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final done = i < backCounts.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? const Color(0xFF8B4513) : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                        style: TextStyle(fontSize: 11, color: done ? Colors.white : Colors.grey.shade600)),
                    ),
                  );
                }),
              ),
              if (backCounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (int i = backCounts.length - 1; i >= 0; i--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 36, child: Text(_ShakeScreenState._yaoNames[i], style: const TextStyle(fontSize: 13))),
                        Expanded(
                          child: Row(
                            children: [
                              Text(_ShakeScreenState._yaoType(backCounts[i]),
                                style: TextStyle(fontSize: 13,
                                  color: _ShakeScreenState._isDong(backCounts[i]) ? Colors.orange.shade700 : null,
                                  fontWeight: _ShakeScreenState._isDong(backCounts[i]) ? FontWeight.bold : null)),
                              const SizedBox(width: 6),
                              Text('${backCounts[i]}背',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_ShakeScreenState._yaoSymbol(backCounts[i]),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B4513)),
                              maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
