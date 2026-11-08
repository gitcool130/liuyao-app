import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'providers/divination_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'models/app_settings.dart';
import 'algorithms/shouxing_calendar.dart';
import 'screens/home_screen.dart';
import 'screens/manual_input_screen.dart';
import 'screens/ganzhi_paipan_screen.dart';
import 'screens/result_screen.dart';
import 'screens/shake_screen.dart';
import 'screens/history_screen.dart';
import 'screens/import_screen.dart';
import 'utils/auto_save.dart';
import 'database/db_platform.dart';

/// 全局导航键，用于从任意位置导航（如分享intent处理）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _sharingLock = false;

void main() async {
  // 确保Flutter绑定初始化（用于加载assets）
  WidgetsFlutterBinding.ensureInitialized();
  // 桌面端数据库改走 sqflite_common_ffi（sqflite 本身只支持 Android/iOS）
  initDatabaseFactory();
  // 初始化节气表
  await ShouXingCalendar.init();
  // 预加载设置（确保进入设置页时已有值）
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  // 监听分享intent（app已在运行时收到新分享也处理）
  const shareChannel = MethodChannel('com.bobo.liuyao_app/share');
  shareChannel.setMethodCallHandler((call) async {
    if (call.method == 'getSharedFileContent' && !_sharingLock) {
      _sharingLock = true;
      final content = call.arguments as String?;
      if (content != null && content.isNotEmpty) {
        // 用对话框让用户确认是否跳转，避免丢失当前编辑状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showShareDialog(content);
        });
      } else {
        _sharingLock = false;
      }
    }
  });

  /// 冷启动时检查分享intent
  _checkColdStartShare(shareChannel);

  runApp(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settingsProvider,
      child: LiuYaoApp(),
    ),
  );
}

/// 显示分享确认对话框
void _showShareDialog(String content) {
  final context = navigatorKey.currentContext;
  if (context == null) { _sharingLock = false; return; }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Text('收到排盘分享'),
      content: const Text('是否打开并导入排盘？\n\n当前页面的解卦笔记将自动保存。'),
      actions: [
        TextButton(
          onPressed: () { Navigator.pop(ctx); _sharingLock = false; },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            await AutoSave.flushAll();
            if (ctx.mounted) Navigator.pop(ctx);
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => ImportScreen(sharedContent: content)),
            );
            _sharingLock = false;
          },
          child: const Text('打开'),
        ),
      ],
    ),
  );
}

/// 冷启动时检查是否有分享intent
void _checkColdStartShare(MethodChannel channel) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final content = await channel.invokeMethod<String>('getSharedFileContent');
      if (content != null && content.isNotEmpty && !_sharingLock) {
        _sharingLock = true;
        _showShareDialog(content);
      }
    } catch (_) {}
  });
}

class LiuYaoApp extends StatelessWidget {
  const LiuYaoApp({super.key});

  /// 根据配色风格和亮度生成 ThemeData
  static ThemeData _buildTheme(String style, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    Color seed;
    Color appBar;
    Color scaffold;
    Color buttonBg;
    Color cardColor;
    switch (style) {
      case 'cool':
        seed = const Color(0xFF5B7FA5);   // 雅致钢蓝
        appBar = const Color(0xFF5B7FA5);
        scaffold = isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8);
        buttonBg = const Color(0xFF5B7FA5);
        cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        break;
      case 'warm':
        seed = const Color(0xFFBC7060);   // 柔暖陶土色
        appBar = const Color(0xFFBC7060);
        scaffold = isDark ? const Color(0xFF1A1212) : const Color(0xFFFDF2F2);
        buttonBg = const Color(0xFFBC7060);
        cardColor = isDark ? const Color(0xFF2A1A1A) : Colors.white;
        break;
      case 'neutral':
        seed = const Color(0xFF8B8070);   // 暖灰褐色
        appBar = const Color(0xFF8B8070);
        scaffold = isDark ? const Color(0xFF181612) : const Color(0xFFF8F6F2);
        buttonBg = const Color(0xFF8B8070);
        cardColor = isDark ? const Color(0xFF28241E) : Colors.white;
        break;
      default: // 'brown' or 'system'
        seed = const Color(0xFF5D4037);
        appBar = const Color(0xFF8B4513);
        scaffold = isDark ? const Color(0xFF1A1410) : const Color(0xFFF5F0E8);
        buttonBg = const Color(0xFF8B4513);
        cardColor = isDark ? const Color(0xFF2A2018) : Colors.white;
        break;
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(backgroundColor: appBar, foregroundColor: Colors.white, centerTitle: true),
      cardTheme: CardThemeData(
        color: cardColor, elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 监听设置变化以实时更新主题
    final sp = context.watch<SettingsProvider>();
    final style = sp.settings.themeStyle;
    final themeMode = style == 'system' ? ThemeMode.system : ThemeMode.light;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DivinationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: '六爻助手',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
          Locale('zh'),
          Locale('en', 'US'),
        ],
        // 根据屏幕宽度自动计算字体比例
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final screenHeight = mediaQuery.size.height;
          final isLandscape = screenWidth > screenHeight;

          // YaoTable 所需的理想宽度（最宽情况：有量化+有动爻）
          // 列宽：神28 + 伏36 + 六亲36 + 支50 + 世应24 + 本卦80 + 变卦130 = 384
          // 加上 Card padding (4*2) = 8，总计约 392
          // 竖屏无量化：28+36+36+36+24+80+130 = 350，+8 = 358
          // 使用 365 作为基准，确保不超出边框
          const yaoTableIdealWidth = 365.0;

          // 横屏且有足够宽度时，使用系统字体设置
          if (isLandscape && screenWidth > yaoTableIdealWidth + 100) {
            // 横屏宽度足够，使用系统字体
            return child!;
          }

          // 竖屏或横屏宽度不够时，计算缩放比例
          const margin = 8.0;
          double textScaleFactor = (screenWidth - margin) / yaoTableIdealWidth;

          // 限制范围：最小0.65，最大1.1（允许稍大于原始大小）
          textScaleFactor = textScaleFactor.clamp(0.65, 1.1);

          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: child!,
          );
        },
        themeMode: themeMode,
        theme: _buildTheme(style, Brightness.light),
        darkTheme: _buildTheme(style, Brightness.dark),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/manual': (context) => const ManualInputScreen(),
          '/ganzhi': (context) => const GanZhiPaiPanScreen(),
          '/shake': (context) => const ShakeScreen(),
          '/result': (context) => const ResultScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}