import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Daftar horizontal skor compliance per departemen.
class ComplianceScoreList extends StatelessWidget {
  const ComplianceScoreList({super.key, required this.scoreResponse});

  final ComplianceScoreResponse scoreResponse;

  /// Urutan kartu sesuai desain.
  static const List<String> _displayOrder = [
    'Packaging',
    'Quality Control',
    'Warehouse',
    'Production',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.4).clamp(140.0, 200.0);

    final scores = _displayOrder.map((deptName) {
      final matches = scoreResponse.data.where(
        (d) => DepartmentStyle.normalize(d.department) == deptName,
      );
      final source = matches.isEmpty ? null : matches.first;

      return ComplianceScore(
        department: deptName,
        score: source?.score ?? 0.0,
        totalAudit: source?.totalAudit ?? 0,
        totalResponses: source?.totalResponses ?? 0,
        conformResponses: source?.conformResponses ?? 0,
      );
    }).toList();

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: scores.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = scores[index];
          return SizedBox(
            width: cardWidth,
            child: _ComplianceCard(
              item: item,
              color: DepartmentStyle.colorOf(item.department),
            ),
          );
        },
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.item, required this.color});

  final ComplianceScore item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Dianggap sudah diaudit jika ada skor atau total audit.
    final hasAudit = item.score > 0 || item.totalAudit > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.5),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.department,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (hasAudit) ...[
            Text(
              '${item.score.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.score / 100,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'No Audit Yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}