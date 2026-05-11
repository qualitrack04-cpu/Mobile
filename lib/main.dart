import 'package:flutter/material.dart';
<<<<<<< feat/finding
import 'package:mobile/app.dart';
import 'package:mobile/injector.dart' as di;
=======
import 'package:auth/presentation/pages/login_page.dart';
import 'package:core/core.dart';
>>>>>>> develop

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
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
<<<<<<< feat/finding
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D2B55),
        ),
        useMaterial3: true,
      ),
      home: App(),
=======
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
      ),
      home: const LoginPage(),
>>>>>>> develop
    );
  }
}