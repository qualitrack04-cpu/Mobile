import 'package:flutter/material.dart';
import 'package:audit/presentation/pages/audit_list_page.dart';
import 'package:core/core.dart';
import 'package:capa/presentation/pages/capa_list_page.dart';
import 'package:finding/presentation/pages/finding_list_page.dart';
import 'dashboard_page.dart';
import 'package:get_it/get_it.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_event.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Halaman lain tetap const dan dibuat sekali.
  final List<Widget> _otherPages = const [
    AuditListPage(),
    FindingListPage(),
    CapaListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dibungkus ValueListenableBuilder: setiap config tanggal/zona waktu
      // berubah (AppClock.revision naik), halaman selain Dashboard dibuat
      // ulang lewat key baru sehingga formatnya ikut berubah.
      body: ValueListenableBuilder<int>(
        valueListenable: AppClock.revision,
        builder: (context, rev, _) {
          return IndexedStack(
            index: _currentIndex,
            children: [
              DashboardPage(
                isActive: _currentIndex == 0,
                onOpenAuditPlan: () => setState(() => _currentIndex = 1),
              ),
              for (final page in _otherPages)
                KeyedSubtree(
                  key: ValueKey('${page.runtimeType}-$rev'),
                  child: page,
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) GetIt.I<FindingBloc>().add(const LoadFindings());
          if (index == 3) GetIt.I<CapaBloc>().add(const LoadCapas());
        },
      ),
    );
  }
}