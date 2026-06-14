import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Langsung tampilkan app → Splash Screen muncul duluan
  // Semua proses init (di.init, notif, permission, cek login) 
  // berjalan di dalam SplashScreen sambil splash ditampilkan
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QualiTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}