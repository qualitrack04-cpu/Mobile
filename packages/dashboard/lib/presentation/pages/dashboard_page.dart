import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'QualiTrack',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            _SummaryCard(
              count: '24',
              title: 'Audit',
              icon: Icons.assignment_outlined,
            ),

            _SummaryCard(
              count: '12',
              title: 'Finding',
              icon: Icons.search,
            ),

            _SummaryCard(
              count: '4',
              title: 'Capa\nDone',
              icon: Icons.checklist_rtl,
            ),

            _SummaryCard(
              count: '0',
              title: 'Capa\nOverdue',
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Ekstrak jadi widget tersendiri, bukan private method
class _SummaryCard extends StatelessWidget {
  final String count;
  final String title;
  final IconData icon;

  const _SummaryCard({
    required this.count,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 90,

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 80,

            decoration: const BoxDecoration(
              color: AppColors.primaryLight,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),

            alignment: Alignment.center,

            child: Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Icon(
                    icon,
                    size: 35,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}