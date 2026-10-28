import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final themeService = ThemeService();
  final notificationService = NotificationService();
  
  await authService.init();
  await themeService.init();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onStateChanged);
    _themeService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onStateChanged);
    _themeService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Todo List Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeService.themeMode,
      home: _authService.isAuthenticated
          ? MainNavigation(
              onLogout: () {
                setState(() {});
              },
            )
          : LoginScreen(
              onLoginSuccess: () {
                setState(() {});
              },
            ),
    );
  }
}
