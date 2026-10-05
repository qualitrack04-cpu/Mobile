import 'package:flutter/material.dart';
import 'package:audit/presentation/pages/audit_list_page.dart';
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      DashboardPage(
        onOpenAuditPlan: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const AuditListPage(),
      const FindingListPage(),
      const CapaListPage(),
    ];
  }

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