import 'package:flutter/material.dart';
import 'package:audit/presentation/pages/audit_list_page.dart';
import 'package:audit/presentation/widgets/custom_bottom_navbar.dart';

import 'dashboard_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // ✅ IndexedStack: semua page tetap hidup saat pindah tab
  // tidak perlu rebuild & reload data setiap kali balik ke tab
  final List<Widget> _pages = [
    const DashboardPage(),
    const AuditListPage(),
    const Center(child: Text('Finding Page')),
    const Center(child: Text('CAPA Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ IndexedStack menggantikan _pages[_currentIndex]
      // Page tidak di-dispose saat pindah tab
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}