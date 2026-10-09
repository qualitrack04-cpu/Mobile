import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/upcoming_audit_item.dart';
import 'upcoming_audit_row.dart';

/// Kartu daftar audit yang jatuh tempo dalam waktu dekat.
class UpcomingAuditsCard extends StatelessWidget {
  const UpcomingAuditsCard({
    super.key,
    required this.audits,
    required this.onAuditTap,
    this.onViewAll,
  });

  final List<UpcomingAuditItem> audits;
  final ValueChanged<UpcomingAuditItem> onAuditTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (audits.isEmpty)
            const _NoUpcomingAudit()
          else ...[
            _FeaturedAudit(
              audit: audits.first,
              onTap: () => onAuditTap(audits.first),
            ),
            if (audits.length > 1) ...[
              const SizedBox(height: 10),
              for (final audit in audits.skip(1).take(3))
                UpcomingAuditRow(audit: audit, onTap: () => onAuditTap(audit)),
            ],
          ],
          const SizedBox(height: 10),
          const _DepartmentLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming audits',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${audits.length} audits due in the next '
              '${UpcomingAuditItem.windowDays} days',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View all',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2764F4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Audit paling dekat, ditampilkan sebagai kotak besar berwarna departemen.
class _FeaturedAudit extends StatelessWidget {
  const _FeaturedAudit({required this.audit, required this.onTap});

  final UpcomingAuditItem audit;
  final VoidCallback onTap;

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _dateLabel {
    final date = audit.date;
    return '${_weekdays[date.weekday - 1]}, ${date.day} '
        '${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = audit.daysLeft;
    final color = DepartmentStyle.colorOf(audit.department);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _dateLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (daysLeft == 0)
                      Text(
                        'today',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      )
                    else ...[
                      Text(
                        '$daysLeft',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        daysLeft == 1 ? 'day left' : 'days left',
                        style: GoogleFonts.inter(fontSize: 7, color: color),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tampilan saat tidak ada audit dalam rentang waktu.
class _NoUpcomingAudit extends StatelessWidget {
  const _NoUpcomingAudit();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 30,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming audits',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'No audits scheduled for the next '
            '${UpcomingAuditItem.windowDays} days',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend warna keempat departemen standar.
class _DepartmentLegend extends StatelessWidget {
  const _DepartmentLegend();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth < 300 ? 6.5 : 8.0;

        return Row(
          children: DepartmentStyle.standard.map((name) {
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: DepartmentStyle.colorOf(name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}