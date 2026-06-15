import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/global_navigator.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Langsung tampilkan app → Splash Screen muncul duluan
  // Semua proses init (di.init, notif, permission, cek login, server status) 
  // berjalan di dalam SplashScreen sambil splash ditampilkan
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      title: 'QualiTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
