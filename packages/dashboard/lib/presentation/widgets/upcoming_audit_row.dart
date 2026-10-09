import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/upcoming_audit_item.dart';

/// Baris audit pada daftar "Upcoming audits".
class UpcomingAuditRow extends StatelessWidget {
  const UpcomingAuditRow({super.key, required this.audit, required this.onTap});

  final UpcomingAuditItem audit;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    final color = DepartmentStyle.colorOf(audit.department);
    final daysLeft = audit.daysLeft;
    final daysLabel = daysLeft == 0
        ? 'today'
        : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left';

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Kotak tanggal.
                Container(
                  width: 38,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${audit.date.day}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _months[audit.date.month - 1],
                        style: GoogleFonts.inter(fontSize: 8, color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${audit.department}  ·  $daysLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.blueGrey.shade400,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
      ],
    );
  }
}