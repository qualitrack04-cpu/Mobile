import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:core/department_style.dart';
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/Q.png',
              height: (screenWidth * 0.08).clamp(
                32.0,
                42.0,
              ), // Memperbesar logo
              fit: BoxFit.contain,
            ),
            // Menggeser teks: Offset(Kiri/Kanan, Atas/Bawah)
            // - Angka pertama (kiri/kanan): minus (-) untuk geser kiri, plus (+) untuk kanan
            // - Angka kedua (atas/bawah): minus (-) untuk geser ke atas, plus (+) untuk ke bawah
            Transform.translate(
              offset: const Offset(
                -3,
                3,
              ), // Coba atur angka '3' ini (naik/turun) sampai pas sejajar
              child: Text(
                'ualiTrack',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: (screenWidth * 0.06).clamp(24.0, 30.0),
                  height:
                      1.0, // Dibuat 1.0 agar tidak ada padding berlebih dari font
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
                _loadUserRole();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 2.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        _photoPath.isNotEmpty
                            ? NetworkImage(ApiService.fixImageUrl(_photoPath))
                            : null,
                    child:
                        _photoPath.isEmpty
                            ? Icon(
                              Icons.person,
                              size: 20,
                              color: AppColors.surface,
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ),
        ],
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
              _buildHeader(screenWidth),
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
              _buildUpcomingAudits(schedule, screenWidth),
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

  // Helper: greeting di bagian atas
  Widget _buildHeader(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Hello, ${_role.label}! 👋',
            style: GoogleFonts.inter(
              fontSize:
                  32, // Ukuran maksimal 32, tapi akan mengecil otomatis jika tidak muat
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back to your dashboard',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<_UpcomingAuditItem> _getUpcomingAudits(AuditScheduleResponse schedule) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final List<_UpcomingAuditItem> result = [];

    for (final scheduleDay in schedule.data) {
      final auditDate = DateTime(
        schedule.year,
        schedule.month,
        scheduleDay.day,
      );

      final daysLeft = auditDate.difference(today).inDays;

      // Hanya audit hari ini sampai 5 hari ke depan
      if (daysLeft >= 0 && daysLeft <= 5) {
        for (final department in scheduleDay.departments) {
          result.add(
            _UpcomingAuditItem(
              scheduleId: department.scheduleId,
              title: department.planTitle,
              department: DepartmentStyle.normalize(department.department),
              rawDepartment: department.department,
              standard: department.standard,
              auditorName: department.auditorName,
              date: auditDate,
            ),
          );
        }
      }
    }

    // Tanggal terdekat tampil paling atas
    result.sort((a, b) => a.date.compareTo(b.date));

    return result;
  }

  Widget _buildUpcomingAudits(
    AuditScheduleResponse schedule,
    double screenWidth,
  ) {
    final upcomingAudits = _getUpcomingAudits(schedule);

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
          // =========================
          // HEADER
          // =========================
          Row(
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
                    '${upcomingAudits.length} audits due in the next 5 days',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // =========================
              // VIEW ALL
              // =========================
              TextButton(
                onPressed: widget.onOpenAuditPlan,
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
          ),

          const SizedBox(height: 12),

          // =========================
          // JIKA TIDAK ADA AUDIT
          // =========================
          if (upcomingAudits.isEmpty)
            _buildNoUpcomingAudit()
          else ...[
            // =========================
            // AUDIT PALING DEKAT
            // Card paling atas
            // =========================
            _buildFeaturedAudit(upcomingAudits.first),

            // =========================
            // AUDIT BERIKUTNYA
            // =========================
            if (upcomingAudits.length > 1) ...[
              const SizedBox(height: 10),

              ...upcomingAudits
                  .skip(1)
                  .take(3)
                  .map((audit) => _buildUpcomingAuditRow(audit)),
            ],
          ],

          const SizedBox(height: 10),

          // =========================
          // LEGEND DEPARTMENT
          // =========================
          _buildAuditLegend(),
        ],
      ),
    );
  }

  Widget _buildFeaturedAudit(_UpcomingAuditItem audit) {
    final daysLeft = _daysLeft(audit.date);
    final color = DepartmentStyle.colorOf(audit.department);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openAuditChecklist(audit);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          _formatAuditDate(audit.date),
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

  String _formatAuditDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    const months = [
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

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} '
        '${months[date.month - 1]}';
  }

  int _daysLeft(DateTime auditDate) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final target = DateTime(auditDate.year, auditDate.month, auditDate.day);

    return target.difference(today).inDays;
  }

  Future<void> _openAuditChecklist(_UpcomingAuditItem item) async {
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

  Widget _buildUpcomingAuditRow(_UpcomingAuditItem audit) {
    final color = DepartmentStyle.colorOf(audit.department);
    final daysLeft = _daysLeft(audit.date);

    const months = [
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

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),

          // ================================
          // KLIK ROW → BUKA CHECKLIST
          // ================================
          onTap: () {
            _openAuditChecklist(audit);
          },

          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // =====================
                // DATE BOX
                // =====================
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
                        months[audit.date.month - 1],
                        style: GoogleFonts.inter(fontSize: 8, color: color),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // =====================
                // CONTENT
                // =====================
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
                              '${audit.department}  ·  ${daysLeft == 0 ? 'today' : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left'}',
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

                // ================================
                // PANAH
                // ================================
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

  Widget _buildAuditLegend() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth < 300 ? 6.5 : 8.0;

        return Row(
          children:
              DepartmentStyle.standard.map((name) {
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

  Widget _buildNoUpcomingAudit() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
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
            'No audits scheduled for the next 5 days',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
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

class _UpcomingAuditItem {
  final String scheduleId;
  final String title;
  final String department;
  final String rawDepartment;
  final String standard;
  final String auditorName;
  final DateTime date;

  const _UpcomingAuditItem({
    required this.scheduleId,
    required this.title,
    required this.department,
    required this.rawDepartment,
    required this.standard,
    required this.auditorName,
    required this.date,
  });
}