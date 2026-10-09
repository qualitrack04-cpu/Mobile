import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/presentation/bloc/audit_bloc.dart';
import 'package:audit/presentation/pages/audit_checklist_page.dart';
import 'package:auth/presentation/pages/profile_page.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spc/spc.dart';

import '../../domain/entities/upcoming_audit_item.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../widgets/audit_report_list.dart';
import '../widgets/audit_summary_grid.dart';
import '../widgets/compliance_score_list.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quality_trend_card.dart';
import '../widgets/upcoming_audits_card.dart';

/// Halaman utama dashboard. Hanya merakit widget dan menangani navigasi;
/// data dan state ada di [DashboardViewModel].
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onOpenAuditPlan});

  final VoidCallback? onOpenAuditPlan;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardViewModel _viewModel;
  final ReportPdfService _pdfService = GetIt.I<ReportPdfService>();

  bool _isShowingAuditAccessNotice = false;
  bool _isOpeningAuditChecklist = false;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(service: GetIt.I<DashboardService>());
    _viewModel.loadUser();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
    if (!mounted) return;
    _viewModel.loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: DashboardAppBar(
            photoPath: _viewModel.photoPath,
            onProfileTap: _openProfile,
          ),
          body: RefreshIndicator(
            onRefresh: _viewModel.load,
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Skeletonizer(
      enabled: _viewModel.isLoading,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          DashboardHeader(userName: _viewModel.userName),
          const SizedBox(height: 24),
          QualityTrendCard(
            trend: _viewModel.trend,
            periods: DashboardViewModel.trendPeriods,
            selectedPeriod: _viewModel.trendPeriod,
            onPeriodChanged: _viewModel.changeTrendPeriod,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('AUDIT SCHEDULE'),
          const SizedBox(height: 14),
          UpcomingAuditsCard(
            audits: UpcomingAuditItem.fromSchedule(_viewModel.schedule),
            onAuditTap: _openAuditChecklist,
            onViewAll: widget.onOpenAuditPlan,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('COMPLIANCE SCORE'),
          const SizedBox(height: 12),
          ComplianceScoreList(scoreResponse: _viewModel.score),
          const SizedBox(height: 24),
          _buildSectionTitle('SUMMARY CARD'),
          const SizedBox(height: 12),
          AuditSummaryGrid(summary: _viewModel.summary),
          const SizedBox(height: 24),
          _buildSectionTitle('SPC ANALYSIS'),
          const SizedBox(height: 12),
          SpcDashboardCard(refreshToken: _viewModel.spcRefreshToken),
          const SizedBox(height: 24),
          _buildSectionTitle('AUDIT REPORT'),
          const SizedBox(height: 12),
          AuditReportList(
            reports: _viewModel.reports,
            onView: (r) => _viewPdf(r.sessionId, r.planTitle),
            onDownload: (r) => _downloadAndSavePdf(r.sessionId, r.planTitle),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  // ---------------------------------------------------------------- audit

  Future<void> _openAuditChecklist(UpcomingAuditItem item) async {
    if (_isOpeningAuditChecklist) return;

    _isOpeningAuditChecklist = true;
    try {
      final selectedAudit = AuditEntity(
        id: item.scheduleId,
        scheduleId: item.scheduleId,
        title: item.title,
        auditorName: item.auditorName,
        isoTemplates: item.standard.isEmpty ? [] : [item.standard],
        department: item.rawDepartment,
        date: item.date,
        description: '',
        isPriority: false,
        isFinished: false,
      );

      final role = _viewModel.role;
      final isAssignedAuditor =
          selectedAudit.auditorName.trim() == _viewModel.userName.trim();
      final hasAccess =
          role == UserRole.qualityManager ||
          (role.canRunChecklist && isAssignedAuditor);

      if (!hasAccess) {
        _showAuditAccessNotice('You do not have access to this audit');
        return;
      }

      if (!mounted) return;
      final auditBloc = GetIt.instance<AuditBloc>();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: auditBloc,
            child: AuditChecklistPage(audit: selectedAudit),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open audit: $e')));
    } finally {
      _isOpeningAuditChecklist = false;
    }
  }

  void _showAuditAccessNotice(String message) {
    if (_isShowingAuditAccessNotice || !mounted) return;

    _isShowingAuditAccessNotice = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)))
        .closed
        .whenComplete(() => _isShowingAuditAccessNotice = false);
  }

  // ------------------------------------------------------------------ PDF

  /// Buka PDF di pembaca PDF perangkat (tanpa simpan ke Download).
  Future<void> _viewPdf(String sessionId, String planTitle) async {
    _showLoadingDialog();
    try {
      final file = await _pdfService.saveForViewing(
        sessionId: sessionId,
        title: planTitle,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await _pdfService.open(file);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Failed to open PDF', e);
    }
  }

  /// Unduh PDF ke folder Download, lalu tampilkan snackbar sukses.
  Future<void> _downloadAndSavePdf(String sessionId, String planTitle) async {
    _showLoadingDialog();
    try {
      await _pdfService.download(sessionId: sessionId, title: planTitle);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Audit report successfully saved to Downloads folder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Failed to download PDF', e);
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showErrorSnackBar(String prefix, Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$prefix: $message')));
  }
}