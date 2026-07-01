import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'providers/divination_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'algorithms/shouxing_calendar.dart';
import 'screens/home_screen.dart';
import 'screens/manual_input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/shake_screen.dart';
import 'screens/history_screen.dart';
import 'screens/import_screen.dart';

/// 全局导航键，用于从任意位置导航（如分享intent处理）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _sharingLock = false;

void main() async {
  // 确保Flutter绑定初始化（用于加载assets）
  WidgetsFlutterBinding.ensureInitialized();
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
          final context = navigatorKey.currentContext;
          if (context != null) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => AlertDialog(
                title: const Text('收到排盘分享'),
                content: const Text('是否打开导入页面？当前排盘或编辑状态将保持，导入后可继续操作。'),
                actions: [
                  TextButton(
                    onPressed: () { Navigator.pop(ctx); _sharingLock = false; },
                    child: const Text('忽略'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
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
          } else {
            _sharingLock = false;
          }
        });
      } else {
        _sharingLock = false;
      }
    }
  });

  runApp(LiuYaoApp(settingsProvider: settingsProvider));
}

class LiuYaoApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  const LiuYaoApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DivinationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: '六爻助手',
        debugShowCheckedModeBanner: false,
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D4037), // 棕色系
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F0E8), // 宣纸色背景
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF8B4513),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/manual': (context) => const ManualInputScreen(),
          '/shake': (context) => const ShakeScreen(),
          '/result': (context) => const ResultScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}