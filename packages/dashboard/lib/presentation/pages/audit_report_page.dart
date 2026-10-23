import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../widgets/audit_report_row.dart';

/// Halaman daftar seluruh laporan audit yang sudah selesai.
///
/// Data dari GET /api/AuditReport (lewat [DashboardService]). Pencarian dan
/// filter departemen dilakukan di sisi mobile. Tampilan tiap baris memakai
/// [AuditReportRow] yang sama dengan kartu "Latest Report" di dashboard.
class AuditReportPage extends StatefulWidget {
  const AuditReportPage({super.key});

  @override
  State<AuditReportPage> createState() => _AuditReportPageState();
}

class _AuditReportPageState extends State<AuditReportPage> {
  static const List<String> _filters = [
    'All',
    'Production',
    'Packaging',
    'Warehouse',
    'Quality Control',
  ];

  final DashboardService _service = GetIt.I<DashboardService>();
  final ReportPdfService _pdfService = GetIt.I<ReportPdfService>();
  final _searchController = TextEditingController();

  List<CompletedAuditReport> _reports = [];
  bool _isLoading = true;
  String? _error;

  String _selectedFilter = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- data

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getCompletedReports();
      if (!mounted) return;
      setState(() {
        _reports = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load audit reports.';
        _isLoading = false;
      });
    }
  }

  List<CompletedAuditReport> get _visibleReports {
    return _reports.where((report) {
      final dept = DepartmentStyle.normalize(report.department);

      if (_selectedFilter != 'All' && dept != _selectedFilter) return false;

      if (_query.isNotEmpty) {
        final haystack = '$dept ${report.planTitle}'.toLowerCase();
        if (!haystack.contains(_query)) return false;
      }
      return true;
    }).toList();
  }

  // ----------------------------------------------------------------- pdf

  /// Tampilkan loading selama [action] berjalan. Kalau gagal, tampilkan
  /// snackbar dan kembalikan null.
  Future<T?> _runWithLoading<T>(
    Future<T> Function() action, {
    required String errorPrefix,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      return await action();
    } catch (e) {
      _showSnack(
        '$errorPrefix: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      return null;
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Buka PDF di pembaca PDF perangkat (tanpa simpan ke Download).
  Future<void> _viewPdf(CompletedAuditReport report) async {
    final file = await _runWithLoading(
      () => _pdfService.saveForViewing(
        sessionId: report.sessionId,
        title: report.planTitle,
      ),
      errorPrefix: 'Failed to open PDF',
    );
    if (file != null) await _pdfService.open(file);
  }

  /// Unduh PDF ke folder Download, lalu tampilkan snackbar sukses.
  Future<void> _downloadPdf(CompletedAuditReport report) async {
    final done = await _runWithLoading<bool>(() async {
      await _pdfService.download(
        sessionId: report.sessionId,
        title: report.planTitle,
      );
      return true;
    }, errorPrefix: 'Failed to download PDF');

    if (done == true) {
      _showSnack('Audit report successfully saved to Downloads folder');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  // ------------------------------------------------------------------ ui

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Audit Report',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 14),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search report',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textDisabled,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 22,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  onPressed: _searchController.clear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _filters[index];
          final selected = label == _selectedFilter;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppColors.action : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.action : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildMessage(
        icon: Icons.cloud_off_outlined,
        message: _error!,
        onRetry: _load,
      );
    }

    if (_isLoading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: 6,
          itemBuilder: (context, index) => _RowCard(
            child: AuditReportRow(
              report: CompletedAuditReport(
                sessionId: '',
                department: 'Production',
                planTitle: 'Loading audit plan title',
              ),
              onView: () {},
              onDownload: () {},
            ),
          ),
        ),
      );
    }

    final reports = _visibleReports;

    if (reports.isEmpty) {
      return _buildMessage(
        icon: Icons.description_outlined,
        message: _reports.isEmpty
            ? 'No completed audit reports yet.'
            : 'No report matches your search.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _RowCard(
            child: AuditReportRow(
              report: report,
              onView: () => _viewPdf(report),
              onDownload: () => _downloadPdf(report),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textDisabled),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Try again',
                  style: GoogleFonts.inter(
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
}

/// Pembungkus kartu putih untuk satu [AuditReportRow].
///
/// Di dashboard, row-nya dipisah garis di dalam satu kartu. Di halaman ini
/// tiap row jadi kartu sendiri, sesuai desain.
class _RowCard extends StatelessWidget {
  const _RowCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}