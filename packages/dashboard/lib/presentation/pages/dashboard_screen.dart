import 'package:flutter/material.dart';
// import 'package:audit/presentation/pages/audit_list_page.dart'; // comment dulu - ada bug
import 'package:core/core.dart';
import 'package:capa/presentation/pages/capa_list_page.dart';
import 'package:finding/presentation/pages/finding_list_page.dart';
import 'dashboard_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const Scaffold(body: Center(child: Text('Audits Coming Soon'))), // placeholder
    const FindingListPage(),
    const CapaListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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