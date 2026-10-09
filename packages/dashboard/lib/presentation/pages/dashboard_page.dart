import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:auth/presentation/pages/profile_page.dart';
import 'package:core_services/core_services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spc/spc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/presentation/bloc/audit_bloc.dart';
import 'package:audit/presentation/pages/audit_checklist_page.dart';
import '../widgets/audit_summary_grid.dart';
import '../widgets/compliance_score_list.dart';
import '../widgets/audit_report_list.dart';
import '../widgets/quality_trend_card.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_header.dart';
import '../../domain/entities/upcoming_audit_item.dart';
import '../widgets/upcoming_audits_card.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onOpenAuditPlan;

  const DashboardPage({super.key, this.onOpenAuditPlan});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;
  final ReportPdfService _pdfService = GetIt.I<ReportPdfService>();

  String _selectedTrendPeriod = '3 Month';

  final List<String> _trendPeriods = ['3 Month', '6 Month', '1 Year'];

  // 4 future untuk 4 API berbeda
  late Future<AuditSummary> _summaryFuture;
  late Future<ComplianceScoreResponse> _scoreFuture;
  late Future<AuditScheduleResponse> _scheduleFuture;
  late Future<List<CompletedAuditReport>> _reportsFuture;
  late Future<QualityTrendResponse> _trendFuture;

  // Cache data terakhir supaya tidak blank saat refresh
  AuditSummary? _lastSummary;
  ComplianceScoreResponse? _lastScore;
  AuditScheduleResponse? _lastSchedule;
  List<CompletedAuditReport>? _lastReports;
  QualityTrendResponse? _lastTrend;

  // Untuk navigasi bulan di kalender
  DateTime _calendarMonth = DateTime.now();

  // Dinaikkan setiap refresh supaya kartu SPC ikut memuat ulang datanya.
  int _spcRefreshToken = 0;
  bool _isShowingAuditAccessNotice = false;
  bool _isOpeningAuditChecklist = false;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(apiService: ApiService());
    _loadUserRole();
    _refresh();
  }

  UserRole _role = UserRole.unknown;
  String _userName = '';
  String _photoPath = '';

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final photoPath = prefs.getString('user_photo') ?? '';
    final userName = prefs.getString('user_name') ?? '';
    final role = UserRole.fromApi(prefs.getString('user_role'));

    if (mounted) {
      setState(() {
        _role = role;
        _userName = userName;
        _photoPath = photoPath;
      });
    }
  }

  int _getTrendMonths() {
    switch (_selectedTrendPeriod) {
      case '6 Month':
        return 6;

      case '1 Year':
        return 12;

      case '3 Month':
      default:
        return 3;
    }
  }

  void _refresh() {
    if (!mounted) return;

    setState(() {
      _calendarMonth = DateTime.now();
      _spcRefreshToken++;

      // =============================
      // AUDIT SUMMARY
      // =============================
      _summaryFuture = _dashboardService.getAuditSummary().then((data) {
        _lastSummary = data;
        return data;
      });

      // =============================
      // COMPLIANCE SCORE
      // =============================
      _scoreFuture = _dashboardService.getComplianceScores().then((data) {
        _lastScore = data;
        return data;
      });

      // =============================
      // AUDIT SCHEDULE
      // =============================
      _scheduleFuture = _dashboardService
          .getAuditSchedule(
            month: _calendarMonth.month,
            year: _calendarMonth.year,
          )
          .then((data) {
            _lastSchedule = data;
            return data;
          });

      // =============================
      // COMPLETED REPORT
      // =============================
      _reportsFuture = _dashboardService.getCompletedReports().then((data) {
        _lastReports = data;
        return data;
      });

      // =============================
      // QUALITY TREND
      // TAHAP 6
      // =============================
      _trendFuture = _dashboardService
          .getQualityTrend(months: _getTrendMonths())
          .then((data) {
            _lastTrend = data;
            return data;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(
        photoPath: _photoPath,
        onProfileTap: _openProfile,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          await Future.wait([
            _summaryFuture,
            _scoreFuture,
            _scheduleFuture,
            _reportsFuture,
            _trendFuture,
          ]);
        },
        child: _buildBody(screenWidth),
      ),
    );
  }

  Widget _buildBody(double screenWidth) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _summaryFuture,
        _scoreFuture,
        _scheduleFuture,
        _reportsFuture,
        _trendFuture,
      ]),
      builder: (context, snapshot) {
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            _lastSummary == null;

        final summary =
            _lastSummary ??
            AuditSummary(
              activeAudit: 0,
              totalCapa: 0,
              capaOpen: 0,
              capaOverdue: 0,
            );
        final score =
            _lastScore ?? ComplianceScoreResponse(overallScore: 0, data: []);
        final schedule =
            _lastSchedule ??
            AuditScheduleResponse(
              month: _calendarMonth.month,
              year: _calendarMonth.year,
              data: [],
            );
        final reports = _lastReports ?? [];
        final trend =
            _lastTrend ??
            QualityTrendResponse(
              currentScore: 0,
              previousScore: 0,
              change: 0,
              data: [],
            );

        return Skeletonizer(
          enabled: isLoading,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Header Greeting
              DashboardHeader(userName: _userName),
              const SizedBox(height: 24),

              // 2. Quality Trend
              QualityTrendCard(
                trend: trend,
                periods: _trendPeriods,
                selectedPeriod: _selectedTrendPeriod,
                onPeriodChanged: _onTrendPeriodChanged,
              ),
              const SizedBox(height: 24),

              // 3. Audit Schedule
              _buildSectionTitle('AUDIT SCHEDULE'),
              const SizedBox(height: 14),
              UpcomingAuditsCard(
                audits: UpcomingAuditItem.fromSchedule(schedule),
                onAuditTap: _openAuditChecklist,
                onViewAll: widget.onOpenAuditPlan,
              ),
              const SizedBox(height: 24),

              // 4. Compliance Score
              _buildSectionTitle('COMPLIANCE SCORE'),
              const SizedBox(height: 12),
              ComplianceScoreList(scoreResponse: score),
              const SizedBox(height: 24),

              // 5. summary card
              _buildSectionTitle('SUMMARY CARD'),
              const SizedBox(height: 12),
              AuditSummaryGrid(summary: summary),
              const SizedBox(height: 24),

              // 6. SPC
              _buildSectionTitle('SPC ANALYSIS'),
              const SizedBox(height: 12),
              SpcDashboardCard(refreshToken: _spcRefreshToken),
              const SizedBox(height: 24),

              // 7. Audit Report
              _buildSectionTitle('AUDIT REPORT'),
              const SizedBox(height: 12),
              AuditReportList(
                reports: reports,
                onView: (r) => _viewPdf(r.sessionId, r.planTitle),
                onDownload:
                    (r) => _downloadAndSavePdf(r.sessionId, r.planTitle),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
    if (!mounted) return;
    _loadUserRole();
  }
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

  // Helper: judul section seperti "SCHEDULE", "AUDIT SUMMARY"
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

      final bool isAssignedAuditor =
          selectedAudit.auditorName.trim() == _userName.trim();
      final bool hasAccess =
          _role == UserRole.qualityManager ||
          (_role.canRunChecklist && isAssignedAuditor);

      if (!hasAccess) {
        _showAuditAccessNotice('You do not have access to this audit');

        return;
      }

      if (!mounted) return;
      final auditBloc = GetIt.instance<AuditBloc>();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => BlocProvider.value(
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

  void _onTrendPeriodChanged(String period) {
    setState(() {
      _selectedTrendPeriod = period;
      _trendFuture = _dashboardService
          .getQualityTrend(months: _getTrendMonths())
          .then((data) {
            _lastTrend = data;
            return data;
          });
    });
  }
}