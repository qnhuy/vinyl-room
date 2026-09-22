import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/config.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'screens/app_routes.dart';
import 'services/session.dart';

/// Điểm khởi đầu của ứng dụng Vinyl Room (Frontend Root).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Tải cấu hình môi trường (.env)
  await AppConfig.init();

  // 2. Tải thông tin phiên làm việc và Theme từ bộ nhớ thiết bị
  await Session.load();
  await AuthProvider.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PlayerProvider>.value(
          value: PlayerProvider.instance,
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: AuthProvider.instance,
        ),
        ChangeNotifierProvider<MusicProvider>(
          create: (_) => MusicProvider(),
        ),
      ],
      child: const MusicApp(),
    ),
  );
}

/// Widget gốc của ứng dụng quản lý Theme và điều hướng chung theo URL.
class MusicApp extends StatefulWidget {
  const MusicApp({super.key});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  @override
  void initState() {
    super.initState();
    // Lắng nghe sự thay đổi phiên làm việc hoặc giao diện sáng/tối
    Session.onChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    Session.onChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'Vinyl Room',
          debugShowCheckedModeBanner: false,
          themeMode: auth.themeMode,
          // Giao diện Sáng (Light Theme)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD49345),
              brightness: Brightness.light,
              primary: const Color(0xFFD49345),
              surface: const Color(0xFFFDFBF7),
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F4EE),
            cardTheme: CardThemeData(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
          ),
          // Giao diện Tối (Dark Theme)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE8A35A),
              brightness: Brightness.dark,
              primary: const Color(0xFFE8A35A),
              surface: const Color(0xFF181512),
              surfaceContainerHighest: const Color(0xFF26211C),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F0E0D),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: const Color(0xFF181512),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF151210),
              indicatorColor: const Color(0xFFE8A35A).withValues(alpha: 0.2),
            ),
          ),
          // Điều hướng các màn hình tương ứng với URL
          initialRoute: AppRoutes.shell,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
