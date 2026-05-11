import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:auth/presentation/pages/login_page.dart';
import 'injector.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // ✅ initialize injector
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
      home: const LoginPage(),
    );
  }
}