import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/spc_analysis.dart';
import '../../domain/usecases/get_spc_status_summary.dart';
import '../pages/spc_page.dart';
import 'spc_card.dart';

/// Kartu ringkasan SPC untuk halaman dashboard.
///
/// Memuat datanya sendiri supaya dashboard cukup menaruh satu widget, tanpa
/// perlu tahu soal repository atau bloc SPC.
///
/// Ganti [refreshToken] (misalnya naikkan angkanya) untuk memuat ulang data,
/// misalnya saat dashboard di-pull-to-refresh.
class SpcDashboardCard extends StatefulWidget {
  const SpcDashboardCard({super.key, this.days = 30, this.refreshToken = 0});

  final int days;
  final int refreshToken;

  @override
  State<SpcDashboardCard> createState() => _SpcDashboardCardState();
}

class _SpcDashboardCardState extends State<SpcDashboardCard> {
  late Future<SpcStatusSummary> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SpcDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.days != widget.days) {
      setState(_load);
    }
  }

  void _load() {
    _future = GetIt.I<GetSpcStatusSummary>()(days: widget.days);
  }

  Future<void> _openSpcPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SpcPage()),
    );
    // Analisis baru bisa dibuat di halaman SPC, jadi ringkasan dimuat ulang.
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: FutureBuilder<SpcStatusSummary>(
        future: _future,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (snapshot.hasData)
                _buildContent(snapshot.data!)
              else if (snapshot.hasError)
                _buildError(snapshot.error!)
              else
                const SizedBox(
                  height: 120,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'SPC Analysis',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Last ${widget.days} days',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(SpcStatusSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${summary.total}',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Parameters monitored',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StatusBar(summary: summary),
        const SizedBox(height: 14),
        _StatusGrid(summary: summary),
      ],
    );
  }

  Widget _buildError(Object error) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            TextButton(
              onPressed: () => setState(_load),
              child: Text(
                'Coba lagi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.action,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _openSpcPage,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          foregroundColor: AppColors.action,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View SPC Analysis',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.action,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 15, color: AppColors.action),
          ],
        ),
      ),
    );
  }
}

/// Bar horizontal bertumpuk, panjang tiap segmen sebanding jumlahnya.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.summary});

  final SpcStatusSummary summary;

  static const double _height = 14;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    if (summary.total == 0) {
      return Container(
        height: _height,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final segments = SpcStatus.values
        .where((status) => summary.countOf(status) > 0)
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(
                // flex harus int dan minimal 1, jadi jumlahnya dipakai
                // langsung. Segmen sekecil apa pun tetap terlihat.
                flex: summary.countOf(segments[i]),
                child: Container(color: segments[i].color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Keterangan 2x2: kolom kiri Capable/Not Capable, kanan Marginal/Unstable,
/// dipisah garis tegak, mengikuti susunan desain.
class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.summary});

  final SpcStatusSummary summary;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                _row(SpcStatus.capable),
                const SizedBox(height: 10),
                _row(SpcStatus.notCapable),
              ],
            ),
          ),
          const VerticalDivider(
            width: 24,
            thickness: 1,
            color: AppColors.borderLight,
          ),
          Expanded(
            child: Column(
              children: [
                _row(SpcStatus.marginal),
                const SizedBox(height: 10),
                _row(SpcStatus.unstable),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(SpcStatus status) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${summary.countOf(status)}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}