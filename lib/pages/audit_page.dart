import 'package:flutter/material.dart';
import 'package:mobile/widgets/bottom_nav.dart';

class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEEF2F7),
      body: Center(
        child: Text(
          'Audits\nComing Soon',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2B55),
          ),
        ),
      ),
    );
  }
}