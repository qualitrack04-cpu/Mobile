import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Empat kartu ringkasan audit dan CAPA di dashboard.
class AuditSummaryGrid extends StatelessWidget {
  const AuditSummaryGrid({super.key, required this.summary});

  final AuditSummary summary;

  static const double _gap = 12;

  // Warna khusus kartu CAPA Open (kuning/oranye).
  static const Color _amber = Color(0xFFD98A00);
  static const Color _amberLight = Color(0xFFFFF1DC);

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _SummaryCard(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Active Audit',
        value: summary.activeAudit,
        color: AppColors.action,
        iconBackground: AppColors.action.withValues(alpha: 0.12),
      ),
      _SummaryCard(
        icon: Icons.layers_outlined,
        title: 'Total CAPA',
        value: summary.totalCapa,
        color: AppColors.action,
        iconBackground: AppColors.action.withValues(alpha: 0.12),
      ),
      _SummaryCard(
        icon: Icons.pending_outlined,
        title: 'CAPA Open',
        value: summary.capaOpen,
        color: _amber,
        iconBackground: _amberLight,
      ),
      _SummaryCard(
        icon: Icons.cancel_outlined,
        title: 'CAPA Overdue',
        value: summary.capaOverdue,
        color: AppColors.danger,
        iconBackground: AppColors.dangerLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 2x2 di HP, satu baris empat kartu di layar lebar.
        final columns = constraints.maxWidth > 600 ? 4 : 2;

        return Column(
          children: [
            for (var i = 0; i < cards.length; i += columns) ...[
              if (i > 0) const SizedBox(height: _gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < columns; j++) ...[
                      if (j > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: i + j < cards.length
                            ? cards[i + j]
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Satu kartu: ikon berwarna, label, dan angka besar di bawah label.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.iconBackground,
  });

  final IconData icon;
  final String title;
  final int value;
  final Color color;
  final Color iconBackground;

  static const double _iconBox = 25;
  static const double _iconGap = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: _iconBox,
                height: _iconBox,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(1000),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: _iconGap),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Angka sejajar dengan awal label, bukan dengan ikon.
          Padding(
            padding: const EdgeInsets.only(left: _iconBox + _iconGap),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$value',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}