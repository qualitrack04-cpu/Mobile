import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kartu skor compliance: total keseluruhan dan skor tiap departemen.
class ComplianceScoreCard extends StatelessWidget {
  const ComplianceScoreCard({super.key, required this.scoreResponse});

  final ComplianceScoreResponse scoreResponse;

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

  static const double _tileGap = 12;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = scoreResponse.month ?? now.month;
    final year = scoreResponse.year ?? now.year;
    final monthLabel = '${_months[month - 1]} $year';
    final change = scoreResponse.change ?? 3;

    final tiles = DepartmentStyle.standard.map(_buildTile).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${scoreResponse.overallScore.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TrendChip(change: change),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                monthLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < tiles.length; i += 2) ...[
            if (i > 0) const SizedBox(height: _tileGap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: _tileGap),
                  Expanded(
                    child:
                        i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(String deptName) {
    final matches = scoreResponse.data.where(
      (d) => DepartmentStyle.normalize(d.department) == deptName,
    );
    final source = matches.isEmpty ? null : matches.first;

    return _DepartmentTile(
      name: deptName,
      score: source?.score ?? 0,
      // Dianggap sudah diaudit jika ada skor atau total audit.
      hasAudit: source != null && (source.score > 0 || source.totalAudit > 0),
      color: DepartmentStyle.colorOf(deptName),
    );
  }
}

/// Panah dan persentase perubahan skor total.
class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    final color = isUp ? AppColors.success : AppColors.danger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${change.abs().toStringAsFixed(0)}%',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Kotak skor satu departemen: titik warna, nama, persentase, progress bar.
class _DepartmentTile extends StatelessWidget {
  const _DepartmentTile({
    required this.name,
    required this.score,
    required this.hasAudit,
    required this.color,
  });

  final String name;
  final double score;
  final bool hasAudit;
  final Color color;

  static const Color _background = Color(0xFFF7F9FC);
  static const Color _track = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hasAudit ? '${score.toStringAsFixed(1)}%' : 'No Audit Yet',
              style: GoogleFonts.inter(
                fontSize: hasAudit ? 20 : 16,
                fontWeight: hasAudit ? FontWeight.w700 : FontWeight.w600,
                color: hasAudit ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasAudit ? (score / 100).clamp(0.0, 1.0) : 0,
              minHeight: 5,
              backgroundColor: _track,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
