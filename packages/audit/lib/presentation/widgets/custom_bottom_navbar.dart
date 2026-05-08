import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int index)? onTap;

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,

      backgroundColor: Colors.white,

      selectedItemColor: const Color(0xFF0C4A84),
      unselectedItemColor: Colors.grey,

      selectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),

      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),

      onTap: onTap,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check_outlined),
          activeIcon: Icon(Icons.fact_check),
          label: 'Audits',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Finding',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt_outlined),
          activeIcon: Icon(Icons.task_alt),
          label: 'CAPA',
        ),
      ],
    );
  }
}