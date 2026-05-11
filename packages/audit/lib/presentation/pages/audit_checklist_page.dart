import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/pages/finding_form_page.dart';
import 'package:finding/presentation/pages/finding_edit_page.dart';

import '../../data/datasources/checklist_datasource.dart';
import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/checklist_entity.dart';
import '../widgets/checklist_card.dart';

class AuditChecklistPage extends StatefulWidget {
  final AuditEntity audit;

  const AuditChecklistPage({
    super.key,
    required this.audit,
  });

  @override
  State<AuditChecklistPage> createState() => _AuditChecklistPageState();
}

class _AuditChecklistPageState extends State<AuditChecklistPage> {
  final ChecklistDatasource _datasource = ChecklistDatasource();
  List<ChecklistEntity> _checklists = [];

  @override
  void initState() {
    super.initState();
    _checklists = _datasource.getChecklistFor(
      isoTemplate: widget.audit.isoTemplates.isNotEmpty
          ? widget.audit.isoTemplates.first
          : '',
      department: widget.audit.department,
    );
  }

  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = widget.audit.date;
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<ChecklistEntity> get _filteredChecklists => _checklists;

  int get _completedCount =>
      _checklists.where((e) => e.isPassed != null).length;

  double get _progress =>
      _checklists.isEmpty ? 0 : _completedCount / _checklists.length;

  /// Buka form tambah finding baru, dipanggil dari Audit Checklist.
  /// Setelah submit berhasil, kembali ke halaman Audit Checklist (bukan Finding page).
  Future<void> _openAddFindingForm(ChecklistEntity checklist) async {
    final result = await Navigator.push<Finding>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<FindingBloc>(),
          child: const FindingFormPage(),
        ),
      ),
    );

    // FindingFormPage mengembalikan Finding object saat berhasil.
    if (result != null) {
      setState(() {
        checklist.hasFinding = true;
        checklist.finding = result; // simpan finding agar bisa di-edit nanti
      });
    }
  }

  /// Buka form edit finding yang sudah ada, dipanggil dari Audit Checklist.
  /// Setelah submit berhasil, kembali ke halaman Audit Checklist (bukan Finding page).
  Future<void> _openEditFindingForm(ChecklistEntity checklist) async {
    if (checklist.finding == null) return;

    final result = await Navigator.push<Finding>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<FindingBloc>(),
          child: FindingEditPage(finding: checklist.finding!),
        ),
      ),
    );

    // FindingEditPage mengembalikan Finding object (data terbaru) saat berhasil.
    if (result != null) {
      setState(() {
        checklist.finding = result; // update finding dengan data terbaru
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ AppBar font size dinamis
    final appBarFontSize = (screenWidth * 0.07).clamp(22.0, 32.0);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),

        title: Text(
          'Audit Checklist',
          style: GoogleFonts.inter(
            fontSize: appBarFontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),

      body: Column(
        children: [
          _buildInfoCard(),
          const Divider(height: 1),
          _buildChecklistContent(),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSubmitButton(screenWidth),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),

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
            widget.audit.department,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Wrap(
                spacing: 6,
                children: widget.audit.isoTemplates.map((iso) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F0FA),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      iso,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  );
                }).toList(),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'COMPLETION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),

                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: 8),

              Text(
                _formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistContent() {
    final checklists = _filteredChecklists;

    if (checklists.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No checklist available',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 120),
        itemCount: checklists.length,

        itemBuilder: (context, index) {
          final checklist = checklists[index];

          return ChecklistCard(
            checklist: checklist,

            onPass: () {
              setState(() => checklist.isPassed = true);
            },

            onFail: () {
              setState(() => checklist.isPassed = false);
            },

            onAddFinding: () => _openAddFindingForm(checklist),

            onEditFinding: () => _openEditFindingForm(checklist),
          );
        },
      ),
    );
  }

  // ✅ Terima screenWidth sebagai parameter
  Widget _buildSubmitButton(double screenWidth) {
    return Container(
      // ✅ Hapus fixed width: 280, pakai margin dinamis
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),

      child: SizedBox(
        width: double.infinity,
        height: 56,

        child: ElevatedButton(
          onPressed: () async {
            await Future.delayed(const Duration(milliseconds: 500));
            if (!context.mounted) return;
            Navigator.pop(context, true);
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          child: Text(
            'Submit Checklist',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}