import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:auth/presentation/pages/profile_page.dart';
import 'package:core_services/core_services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;

  // 4 future untuk 4 API berbeda
  late Future<AuditSummary> _summaryFuture;
  late Future<ComplianceScoreResponse> _scoreFuture;
  late Future<AuditScheduleResponse> _scheduleFuture;
  late Future<List<CompletedAuditReport>> _reportsFuture;

  // Cache data terakhir supaya tidak blank saat refresh
  AuditSummary? _lastSummary;
  ComplianceScoreResponse? _lastScore;
  AuditScheduleResponse? _lastSchedule;
  List<CompletedAuditReport>? _lastReports;

  // Untuk navigasi bulan di kalender
  DateTime _calendarMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(apiService: ApiService());
    _loadUserRole();
    _refresh();
  }

  String _userRole = 'Auditor';

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString('user_role') ?? 'Auditor';
    
    if (mounted) {
      setState(() {
        if (roleStr == 'QualityManager') {
          _userRole = 'Quality Manager';
        } else if (roleStr == 'Auditor') {
          _userRole = 'Auditor';
        } else {
          _userRole = roleStr;
        }
      });
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {

      _calendarMonth = DateTime.now();
      _selectedDate = DateTime.now();

      _summaryFuture = _dashboardService.getAuditSummary().then((data) {
        _lastSummary = data;
        return data;
      });
      _scoreFuture = _dashboardService.getComplianceScores().then((data) {
        _lastScore = data;
        return data;
      });
      _scheduleFuture = _dashboardService
          .getAuditSchedule(
            month: _calendarMonth.month,
            year: _calendarMonth.year,
          )
          .then((data) {
            _lastSchedule = data;
            return data;
          });
      _reportsFuture = _dashboardService.getCompletedReports().then((data) {
        _lastReports = data;
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/QualiTrack.png',
              height: (screenWidth * 0.075).clamp(26.0, 34.0),
              fit: BoxFit.contain,
            ),
            Text(
              'Track',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: (screenWidth * 0.06).clamp(20.0, 26.0),
                height: 1.0,
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
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
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.surface,
                    ),
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
          await Future.wait([_summaryFuture, _scoreFuture, _scheduleFuture, _reportsFuture]);
        },
        child: _buildBody(screenWidth),
      ),
    );
  }

  Widget _buildBody(double screenWidth) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_summaryFuture, _scoreFuture, _scheduleFuture, _reportsFuture]),
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

        return Skeletonizer(
          enabled: isLoading,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Header Greeting
              _buildHeader(screenWidth),
              const SizedBox(height: 24),

              // 2. Kalender
              _buildSectionTitle('AUDIT SCHEDULE'),
              const SizedBox(height: 14),
              _buildCalendar(schedule, screenWidth),
              const SizedBox(height: 24),

              // 3. Audit Summary
              _buildSectionTitle('AUDIT SUMMARY'),
              const SizedBox(height: 12),
              _buildAuditSummary(summary, screenWidth),
              const SizedBox(height: 24),

              // 4. Compliance Score
              _buildSectionTitle('COMPLIANCE SCORE'),
              const SizedBox(height: 12),
              _buildComplianceScore(score, screenWidth),
              const SizedBox(height: 24),

              // 5. Audit Report
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

  Widget _buildAuditReportList(List<CompletedAuditReport> reports, double screenWidth) {
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
              // Bagian atas (dummy pdf thumbnail)
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA), // Light Gray/White
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reporting\nStructure',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'White Paper',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bagian bawah (Text + Button)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 16), // top 26 agar tidak nabrak icon tengah
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
                          onPressed: () => _viewPdf(report.sessionId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00104A), // Dark navy
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
                  border: Border.all(color: Colors.white, width: 2), // Biar ada border putih
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
              onTap: () => _downloadAndSavePdf(report.sessionId),
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
  Future<void> _viewPdf(String sessionId) async {
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
      final file = File('${tempDir.path}/audit-report-$sessionId.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: $e')),
        );
      }
    }
  }

  /// Download PDF → simpan ke folder Download HP → tampil notifikasi
  Future<void> _downloadAndSavePdf(String sessionId) async {
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

      File file = File('${dir!.path}/audit-report-$sessionId.pdf');
      int counter = 1;
      while (await file.exists()) {
        file = File('${dir.path}/audit-report-$sessionId ($counter).pdf');
        counter++;
      }

      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context);

        // Tampil notifikasi sistem Android
        await NotificationService().showDownloadNotification(
          id: sessionId.hashCode,
          title: 'Download Complete',
          body: 'audit-report-$sessionId.pdf has been downloaded',
          filePath: file.path,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
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
            'Hello, $_userRole! 👋',
            style: GoogleFonts.inter(
              fontSize: 32, // Ukuran maksimal 32, tapi akan mengecil otomatis jika tidak muat
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

  Widget _buildAuditSummary(AuditSummary summary, double screenWidth) {
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;

    return GridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 85, // Tinggi FIX untuk tiap kotak agar 100% tidak terpotong
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

  Widget _buildComplianceScore(ComplianceScoreResponse scoreResponse, double screenWidth) {
    // 1. Daftar 4 departemen wajib sesuai desain
    final List<String> standardDepts = [
      'Packaging',
      'Quality Control',
      'Warehouse',
      'Production'
    ];

    // 2. Map warna spesifik untuk tiap departemen
    final Map<String, Color> colors = {
      'Production': const Color(0xFFE75480),
      'Packaging': const Color(0xFF9570E1),
      'Warehouse': const Color(0xFF1DD8B6),
      'Quality Control': const Color(0xFF4AB4FF),
    };

    // 3. Gabungkan data API dengan departemen standar
    final List<ComplianceScore> displayScores = standardDepts.map((deptName) {
      // Cari apakah ada data dari API untuk departemen ini
      final apiDataList = scoreResponse.data.where((d) {
        // Toleransi kalau dari backend namanya "Produksi"
        if (deptName == 'Production') {
          return d.department.toLowerCase() == 'production' || 
                 d.department.toLowerCase() == 'produksi';
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
        separatorBuilder: (context, index) => const SizedBox(width: 16), // Jarak antar kotak
        itemBuilder: (context, index) {
          final item = displayScores[index];
          
          // Memastikan warnanya tidak tertukar walau API nulisnya "Produksi"
          final isProduction = item.department.toLowerCase() == 'produksi' || item.department == 'Production';
          final color = isProduction 
              ? colors['Production']! 
              : (colors[item.department] ?? AppColors.primaryLight);
          
          return SizedBox(
            width: cardWidth, // Lebar kotaknya responsif
            child: _complianceCard(
              ComplianceScore(
                department: isProduction ? 'Production' : item.department,
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
        border: Border.all(color: color, width: 1.5), // Tambahkan border di sini
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
                        // Fetch ulang jadwal untuk bulan yang baru
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
                        // Fetch ulang jadwal untuk bulan yang baru
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
            children: weekdays.map((day) {
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
              childAspectRatio: screenWidth > 600 ? 1.5 : 1.1, // Dibuat lebih kecil dari 1 supaya kotak di kalender lebih tinggi di HP
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox(); // Kotak kosong sebelum tanggal 1
              }

              final int day = index - firstWeekday + 2;
              
              // GANTI isToday menjadi isSelected
              final bool isSelected = 
                  _selectedDate.year == _calendarMonth.year &&
                  _selectedDate.month == _calendarMonth.month &&
                  _selectedDate.day == day;

              // Cari apakah ada jadwal di tanggal ini
              final scheduleDayList = schedule.data.where((s) => s.day == day).toList();
              final scheduleDay = scheduleDayList.isNotEmpty ? scheduleDayList.first : null;
              final hasSchedule = scheduleDay != null && scheduleDay.departments.isNotEmpty;

              // BUNGKUS DENGAN GestureDetector AGAR BISA DIKLIK
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Update tanggal yang dipilih saat diklik
                    _selectedDate = DateTime(_calendarMonth.year, _calendarMonth.month, day);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent, // Pakai isSelected
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? null : Border.all(color: Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, // Pakai isSelected
                          color: isSelected ? Colors.white : AppColors.textPrimary, // Pakai isSelected
                        ),
                      ),
                      if (hasSchedule) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: scheduleDay.departments.take(3).map((dept) {
                            // Cek jika namanya "Produksi", samakan dengan "Production"
                            final isProduction = dept.department.toLowerCase() == 'produksi' || dept.department == 'Production';
                            final color = isProduction
                                ? deptColors['Production']!
                                : (deptColors[dept.department] ?? AppColors.primaryLight);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
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

          // --- LEGEND WAKTU ---
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: deptColors.entries.map((entry) {
              return Row(
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Helper untuk konversi angka bulan ke nama bulan
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
