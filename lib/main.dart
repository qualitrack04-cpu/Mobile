import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core/presentation/pages/maintenance_page.dart';
import 'package:auth/presentation/pages/login_page.dart';
import 'package:dashboard/presentation/pages/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_services/core_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'injector.dart' as di;
import 'startup_checker.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // ✅ initialize injector
  
  // Initialize notification service
  await NotificationService().init();

  // Request notification permissions
  await Permission.notification.request();
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final isLoggedIn = token != null && token.isNotEmpty;

  final isServerAvailable = await StartupChecker.isServerAvailable();

  runApp(MyApp(isLoggedIn: isLoggedIn, isServerAvailable: isServerAvailable));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isServerAvailable;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.isServerAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'QualiTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
      ),

      routes: {
        '/login': (_) => const LoginPage(),
        '/dashboard': (_) => const DashboardScreen(),
        '/maintenance': (_) => const MaintenancePage(),
      },

      home:
          !isServerAvailable
              ? const MaintenancePage()
              : isLoggedIn
                ? const DashboardScreen()
                : const LoginPage(),
    );
  }
}
