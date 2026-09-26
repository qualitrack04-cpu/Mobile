import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/services/dashboard_service.dart';
import 'package:core_services/services/api_service.dart';
import 'package:pdfx/pdfx.dart';
import 'package:auth/presentation/pages/profile_page.dart';
import 'package:core_services/core_services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:spc/spc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/presentation/bloc/audit_bloc.dart';
import 'package:audit/presentation/pages/audit_checklist_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onOpenAuditPlan;

  const DashboardPage({super.key, this.onOpenAuditPlan});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;

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
  DateTime _selectedDate = DateTime.now();

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
      _selectedDate = DateTime.now();
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
              _buildQualityTrend(screenWidth, trend),
              const SizedBox(height: 24),

              // 3. Audit Schedule
              _buildSectionTitle('AUDIT SCHEDULE'),
              const SizedBox(height: 14),
              _buildUpcomingAudits(schedule, screenWidth),
              const SizedBox(height: 24),

              // 4. Compliance Score
              _buildSectionTitle('COMPLIANCE SCORE'),
              const SizedBox(height: 12),
              _buildComplianceScore(score, screenWidth),
              const SizedBox(height: 24),

              // 5. summary card
              _buildSectionTitle('SUMMARY CARD'),
              const SizedBox(height: 12),
              _buildAuditSummary(summary, screenWidth),
              const SizedBox(height: 24),

              // 6. SPC
              _buildSectionTitle('SPC ANALYSIS'),
              const SizedBox(height: 12),
              SpcDashboardCard(refreshToken: _spcRefreshToken),
              const SizedBox(height: 24),

              // 7. Audit Report
              _buildSectionTitle('AUDIT REPORT'),
              const SizedBox(height: 12),
              _buildAuditReportList(reports, screenWidth),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditReportList(
    List<CompletedAuditReport> reports,
    double screenWidth,
  ) {
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No completed audit reports yet.',
            style: GoogleFonts.inter(color: AppColors.textDisabled),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report, screenWidth);
        },
      ),
    );
  }

  Widget _buildReportCard(CompletedAuditReport report, double screenWidth) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bagian atas (actual pdf thumbnail)
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: PdfThumbnailWidget(sessionId: report.sessionId),
                ),
              ),
              // Bagian bawah (Text + Button)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    26,
                    16,
                    16,
                  ), // top 26 agar tidak nabrak icon tengah
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        report.planTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00104A), // Navy color
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed:
                              () =>
                                  _viewPdf(report.sessionId, report.planTitle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF00104A,
                            ), // Dark navy
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'View Report',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Ikon PDF di tengah-tengah pemisah
          Positioned(
            top: 80, // Setengah di atas (100-20), setengah di bawah
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FA), // Light blue background
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ), // Biar ada border putih
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFF00104A), // Navy color
                  size: 24,
                ),
              ),
            ),
          ),
          // Tombol Download di ujung kanan atas
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap:
                  () => _downloadAndSavePdf(report.sessionId, report.planTitle),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00104A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buka PDF langsung di reader HP (tanpa simpan ke Download)
  Future<void> _viewPdf(String sessionId, String planTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _dashboardService.apiService.client.get(
        '/api/Pdf/audit-report/$sessionId',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      // Simpan ke direktori temporary (bukan Download)
      final tempDir = await getTemporaryDirectory();
      final safeTitle = planTitle
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');
      final file = File('${tempDir.path}/AuditReport_$safeTitle.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
      }
    }
  }

  /// Download PDF → simpan ke folder Download HP → tampil notifikasi
  Future<void> _downloadAndSavePdf(String sessionId, String planTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _dashboardService.apiService.client.get(
        '/api/Pdf/audit-report/$sessionId',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final safeTitle = planTitle
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');
      final baseFileName = 'AuditReport_$safeTitle';

      File file = File('${dir!.path}/$baseFileName.pdf');
      int counter = 1;
      while (await file.exists()) {
        file = File('${dir.path}/$baseFileName ($counter).pdf');
        counter++;
      }

      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context);

        // Tampil notifikasi sistem Android
        await NotificationService().showDownloadNotification(
          id: sessionId.hashCode,
          title: 'Download Complete',
          body: '${file.path.split('/').last} has been downloaded',
          filePath: file.path,
        );

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
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download PDF: $e')));
      }
    }
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

  Widget _buildQualityTrend(double screenWidth, QualityTrendResponse trend) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quality Trend',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),

              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.primaryMuted),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTrendPeriod,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    items:
                        _trendPeriods.map((period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        // Ubah pilihan dropdown
                        _selectedTrendPeriod = value;

                        // Ambil ulang Quality Trend dari backend
                        _trendFuture = _dashboardService
                            .getQualityTrend(months: _getTrendMonths())
                            .then((data) {
                              _lastTrend = data;
                              return data;
                            });
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${trend.currentScore.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),

              const SizedBox(width: 5),

              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${trend.change >= 0 ? '↗' : '↘'} '
                  '${trend.change.abs().toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trend.change >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            'vs previous month',
            style: GoogleFonts.inter(
              fontSize: 8,
              color: AppColors.textDisabled,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(height: 160, child: _buildQualityLineChart(trend)),
        ],
      ),
    );
  }

  Widget _buildQualityLineChart(QualityTrendResponse trend) {
    final months = trend.data.map((item) => item.monthName).toList();

    final spots =
        trend.data
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.score))
            .toList();

    const lineColor = Color(0xFF1689E8);
    const gridColor = Color(0xFFE5E7EB);
    const labelColor = Color(0xFF94A3B8);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: trend.data.isEmpty ? 0 : (trend.data.length - 1).toDouble(),
        minY: 0,
        maxY: 100,

        // =========================
        // GARIS HORIZONTAL
        // =========================
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: gridColor, strokeWidth: 1);
          },
        ),

        // Garis bagian atas = garis 100%
        borderData: FlBorderData(
          show: true,
          border: const Border(top: BorderSide(color: gridColor, width: 1)),
        ),

        // =========================
        // LABEL AXIS
        // =========================
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // =========================
          // PERSENTASE KIRI
          // =========================
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${value.toInt()}%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                );
              },
            ),
          ),

          // =========================
          // BULAN
          // =========================
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }

                Widget monthText = Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Text(
                    months[index],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: labelColor,
                    ),
                  ),
                );

                // Geser bulan terakhir sedikit ke kiri
                // supaya tulisan Aug tidak keluar dari area grafik
                if (index == months.length - 1) {
                  monthText = Transform.translate(
                    offset: const Offset(-10, 0),
                    child: monthText,
                  );
                }

                return monthText;
              },
            ),
          ),
        ),

        // =========================
        // LINE GRAPH
        // =========================
        lineBarsData: [
          LineChartBarData(
            spots: spots,

            isCurved: true,
            curveSmoothness: 0.35,

            color: lineColor,
            barWidth: 1.7,

            isStrokeCapRound: true,

            // =========================
            // TITIK GRAFIK
            // =========================
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: const Color(0xFF087FD0),
                  strokeWidth: 0,
                );
              },
            ),

            // =========================
            // GRADIENT AREA
            // =========================
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.25),
                  lineColor.withOpacity(0.10),
                  lineColor.withOpacity(0.00),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ],

        // =========================
        // TOOLTIP
        // =========================
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()}%',
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuditSummary(AuditSummary summary, double screenWidth) {
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;

    return GridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent:
            85, // Tinggi FIX untuk tiap kotak agar 100% tidak terpotong
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(
          'Active Audit',
          summary.activeAudit.toString(),
          const Color(0xFF1D52D8),
        ),
        _summaryCard(
          'Total CAPA',
          summary.totalCapa.toString(),
          const Color(0xFF1D52D8),
        ),
        _summaryCard(
          'CAPA Open',
          summary.capaOpen.toString(),
          const Color(0xFF2E7D32),
        ),
        _summaryCard(
          'CAPA Overdue',
          summary.capaOverdue.toString(),
          AppColors.danger,
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Garis warna di kiri
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceScore(
    ComplianceScoreResponse scoreResponse,
    double screenWidth,
  ) {
    // 1. Daftar 4 departemen wajib sesuai desain
    final List<String> standardDepts = [
      'Packaging',
      'Quality Control',
      'Warehouse',
      'Production',
    ];

    // 2. Map warna spesifik untuk tiap departemen
    final Map<String, Color> colors = {
      'Production': const Color(0xFFE75480),
      'Packaging': const Color(0xFF9570E1),
      'Warehouse': const Color(0xFF1DD8B6),
      'Quality Control': const Color(0xFF4AB4FF),
    };

    // 3. Gabungkan data API dengan departemen standar
    final List<ComplianceScore> displayScores =
        standardDepts.map((deptName) {
          // Cari apakah ada data dari API untuk departemen ini
          final apiDataList =
              scoreResponse.data.where((d) {
                // Normalisasi nama dari backend ke nama tampilan:
                // 'Produksi' atau 'Production' → Production
                // 'QC' atau 'Quality Control' → Quality Control
                if (deptName == 'Production') {
                  return d.department.toLowerCase() == 'production' ||
                      d.department.toLowerCase() == 'produksi';
                }
                if (deptName == 'Quality Control') {
                  return d.department == 'QC' ||
                      d.department.toLowerCase() == 'quality control' ||
                      d.department.toLowerCase() == 'quality manager';
                }
                return d.department.toLowerCase() == deptName.toLowerCase();
              }).toList();

          return apiDataList.isNotEmpty
              ? apiDataList.first
              : ComplianceScore(
                department: deptName,
                score: 0.0,
                totalAudit: 0,
                totalResponses: 0,
                conformResponses: 0,
              );
        }).toList();

    // 4. Ubah menjadi List yang bisa di-scroll ke samping (Horizontal)
    final cardWidth = (screenWidth * 0.4).clamp(140.0, 200.0);

    return SizedBox(
      height: 130, // Tinggi kotaknya, bisa kamu atur sesuka hati
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayScores.length,
        separatorBuilder:
            (context, index) => const SizedBox(width: 16), // Jarak antar kotak
        itemBuilder: (context, index) {
          final item = displayScores[index];

          // Normalisasi nama departemen dari backend ke nama tampilan
          String displayDept = item.department;
          if (item.department.toLowerCase() == 'produksi' ||
              item.department.toLowerCase() == 'production') {
            displayDept = 'Production';
          } else if (item.department == 'QC' ||
              item.department.toLowerCase() == 'quality control' ||
              item.department.toLowerCase() == 'quality manager') {
            displayDept = 'Quality Control';
          }

          final color = colors[displayDept] ?? AppColors.primaryLight;

          return SizedBox(
            width: cardWidth,
            child: _complianceCard(
              ComplianceScore(
                department: displayDept,
                score: item.score,
                totalAudit: item.totalAudit,
                totalResponses: item.totalResponses,
                conformResponses: item.conformResponses,
              ),
              color,
            ),
          );
        },
      ),
    );
  }

  Widget _complianceCard(ComplianceScore item, Color color) {
    // Tentukan apakah dia sudah diaudit (skor/total audit lebih dari 0)
    final bool hasAudit = item.score > 0 || item.totalAudit > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color,
          width: 1.5,
        ), // Tambahkan border di sini
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
          ] else ...[
            // TAMPILAN JIKA BELUM ADA AUDIT (SKOR = 0)
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
        ],
      ),
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
              department: _normalizeDepartment(department.department),
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

  String _normalizeDepartment(String department) {
    final value = department.toLowerCase();

    if (value == 'produksi' || value == 'production') {
      return 'Production';
    }

    if (value == 'qc' ||
        value == 'quality control' ||
        value == 'quality manager') {
      return 'Quality Control';
    }

    if (value == 'packaging') {
      return 'Packaging';
    }

    if (value == 'warehouse') {
      return 'Warehouse';
    }

    return department;
  }

  Color _departmentColor(String department) {
    switch (department) {
      case 'Production':
        return const Color(0xFFE75480);

      case 'Packaging':
        return const Color(0xFF9570E1);

      case 'Warehouse':
        return const Color(0xFF1DD8B6);

      case 'Quality Control':
        return const Color(0xFF4AB4FF);

      default:
        return AppColors.primary;
    }
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
            color: Colors.black.withOpacity(0.04),
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
    final color = _departmentColor(audit.department);

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
            color: color.withOpacity(0.10),
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
        department: item.department,
        date: item.date,
        description: '',
        isPriority: false,
        isFinished: false,
      );

      if (!_role.canRunChecklist ||
          selectedAudit.auditorName.trim() != _userName.trim()) {
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
    final color = _departmentColor(audit.department);
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
                    color: color.withOpacity(0.10),
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
    final departments = {
      'Production': const Color(0xFFE75480),
      'Packaging': const Color(0xFF9570E1),
      'Warehouse': const Color(0xFF1DD8B6),
      'Quality Control': const Color(0xFF4AB4FF),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth < 300 ? 6.5 : 8.0;

        return Row(
          children:
              departments.entries.map((entry) {
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            entry.key.toUpperCase(),
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

  Widget _buildCalendar(AuditScheduleResponse schedule, double screenWidth) {
    // 1. Nama hari (Senin - Minggu)
    final List<String> weekdays = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    // 2. Hitung jumlah hari dalam bulan dan hari pertama (Senin=1)
    final int daysInMonth = DateUtils.getDaysInMonth(
      _calendarMonth.year,
      _calendarMonth.month,
    );
    final DateTime firstDayOfMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month,
      1,
    );
    final int firstWeekday = firstDayOfMonth.weekday;

    // 3. Warna titik per departemen (harus sama dengan Compliance Score)
    final Map<String, Color> deptColors = {
      'Production': const Color(0xFFE75480),
      'Packaging': const Color(0xFF9570E1),
      'Warehouse': const Color(0xFF1DD8B6),
      'Quality Control': const Color(0xFF4AB4FF),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          // --- HEADER BULAN & NAVIGASI ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _monthName(_calendarMonth.month),
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _calendarMonth.year.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month - 1,
                        );
                        _scheduleFuture = _dashboardService
                            .getAuditSchedule(
                              month: _calendarMonth.month,
                              year: _calendarMonth.year,
                            )
                            .then((data) {
                              _lastSchedule = data;
                              return data;
                            });
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month + 1,
                        );
                        _scheduleFuture = _dashboardService
                            .getAuditSchedule(
                              month: _calendarMonth.month,
                              year: _calendarMonth.year,
                            )
                            .then((data) {
                              _lastSchedule = data;
                              return data;
                            });
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- NAMA HARI (MON, TUE, dll) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                weekdays.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),

          // --- GRID TANGGAL ---
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstWeekday - 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: screenWidth > 600 ? 1.5 : 1.1,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }

              final int day = index - firstWeekday + 2;

              // Apakah tanggal ini adalah hari ini
              final today = DateTime.now();
              final bool isToday =
                  today.year == _calendarMonth.year &&
                  today.month == _calendarMonth.month &&
                  today.day == day;

              // Apakah tanggal ini yang sedang dipilih
              final bool isSelected =
                  _selectedDate.year == _calendarMonth.year &&
                  _selectedDate.month == _calendarMonth.month &&
                  _selectedDate.day == day;

              // Cari apakah ada jadwal di tanggal ini
              final scheduleDayList =
                  schedule.data.where((s) => s.day == day).toList();
              final scheduleDay =
                  scheduleDayList.isNotEmpty ? scheduleDayList.first : null;
              final hasSchedule =
                  scheduleDay != null && scheduleDay.departments.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month,
                      day,
                    );
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        isToday && !isSelected
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : Border.all(color: Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                          color:
                              isSelected
                                  ? Colors.white
                                  : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        ),
                      ),
                      if (hasSchedule) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              scheduleDay.departments.take(3).map((dept) {
                                String normalizedDept = dept.department;
                                if (dept.department.toLowerCase() ==
                                        'produksi' ||
                                    dept.department.toLowerCase() ==
                                        'production') {
                                  normalizedDept = 'Production';
                                } else if (dept.department == 'QC' ||
                                    dept.department.toLowerCase() ==
                                        'quality control' ||
                                    dept.department.toLowerCase() ==
                                        'quality manager') {
                                  normalizedDept = 'Quality Control';
                                }
                                final color =
                                    deptColors[normalizedDept] ??
                                    AppColors.primaryLight;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // --- LEGEND ---
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children:
                  deptColors.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.key.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

class _UpcomingAuditItem {
  final String scheduleId;
  final String title;
  final String department;
  final String standard;
  final String auditorName;
  final DateTime date;

  const _UpcomingAuditItem({
    required this.scheduleId,
    required this.title,
    required this.department,
    required this.standard,
    required this.auditorName,
    required this.date,
  });
}

class PdfThumbnailWidget extends StatefulWidget {
  final String sessionId;
  const PdfThumbnailWidget({super.key, required this.sessionId});

  @override
  State<PdfThumbnailWidget> createState() => _PdfThumbnailWidgetState();
}

class _PdfThumbnailWidgetState extends State<PdfThumbnailWidget> {
  PdfDocument? _pdfDoc;
  PdfPageImage? _pageImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPdfThumbnail();
  }

  Future<void> _loadPdfThumbnail() async {
    try {
      final apiService = GetIt.I<ApiService>();
      final response = await apiService.client.get(
        '/api/Pdf/audit-report/${widget.sessionId}',
        options: Options(responseType: ResponseType.bytes),
      );

      final document = await PdfDocument.openData(response.data);
      final page = await document.getPage(1);

      // Render page at a small thumbnail resolution to save memory
      final pageImage = await page.render(
        width: page.width / 3,
        height: page.height / 3,
        format: PdfPageImageFormat.jpeg,
      );

      if (mounted) {
        setState(() {
          _pdfDoc = document;
          _pageImage = pageImage;
          _isLoading = false;
        });
      }

      await page.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfDoc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (_hasError || _pageImage == null) {
      return const Center(
        child: Icon(Icons.picture_as_pdf, color: Colors.grey, size: 40),
      );
    }
    return Container(
      color: Colors.white,
      child: Image.memory(
        _pageImage!.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        alignment: Alignment.topCenter,
      ),
    );
  }
}
