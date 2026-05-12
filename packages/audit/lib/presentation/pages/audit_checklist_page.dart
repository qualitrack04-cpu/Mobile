import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/pages/finding_form_page.dart';
import 'package:finding/presentation/pages/finding_edit_page.dart';

import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/checklist_entity.dart';
import '../bloc/audit_bloc.dart';
import '../bloc/audit_event.dart';
import '../bloc/audit_state.dart';
import '../widgets/checklist_card.dart';

class AuditChecklistPage extends StatelessWidget {
  final AuditEntity audit;

  const AuditChecklistPage({super.key, required this.audit});

  @override
  Widget build(BuildContext context) {
    // Jika BlocProvider sudah dipasang di parent (AuditListPage), pakai BlocProvider.value
    // Jika dipakai standalone, buat bloc baru
    return _AuditChecklistView(audit: audit);
  }
}

class _AuditChecklistView extends StatefulWidget {
  final AuditEntity audit;

  const _AuditChecklistView({required this.audit});

  @override
  State<_AuditChecklistView> createState() => _AuditChecklistViewState();
}

class _AuditChecklistViewState extends State<_AuditChecklistView> {
  List<ChecklistEntity> _checklists = [];

  @override
  void initState() {
    super.initState();
    // ✅ PERUBAHAN: dispatch LoadChecklist event ke BLoC
    context.read<AuditBloc>().add(
          LoadChecklist(
            isoTemplate: widget.audit.isoTemplates.isNotEmpty
                ? widget.audit.isoTemplates.first
                : '',
            department: widget.audit.department,
          ),
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

  int get _completedCount => _checklists.where((e) => e.isPassed != null).length;

  double get _progress =>
      _checklists.isEmpty ? 0 : _completedCount / _checklists.length;

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

    if (result != null) {
      setState(() {
        checklist.hasFinding = true;
        checklist.finding = result;
      });
    }
  }

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

    if (result != null) {
      setState(() => checklist.finding = result);
    }
  }

  // ✅ PERUBAHAN: dispatch MarkAuditFinishedEvent ke BLoC saat submit
  void _onSubmitChecklist() {
    context.read<AuditBloc>().add(
          MarkAuditFinishedEvent(
            audit: widget.audit,
            isFinished: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarFontSize = (screenWidth * 0.07).clamp(22.0, 32.0);

    // ✅ BlocListener: tutup halaman setelah berhasil mark finished
    return BlocListener<AuditBloc, AuditState>(
      listener: (context, state) {
        if (state is ChecklistLoaded) {
          setState(() => _checklists = state.checklists);
        }
        if (state is AuditMarkedFinished) {
          Navigator.pop(context, true);
        }
        if (state is AuditError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
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
      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                _formattedDate,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistContent() {
    if (_checklists.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No checklist available',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 120),
        itemCount: _checklists.length,
        itemBuilder: (context, index) {
          final checklist = _checklists[index];
          return ChecklistCard(
            checklist: checklist,
            onPass: () => setState(() => checklist.isPassed = true),
            onFail: () => setState(() => checklist.isPassed = false),
            onAddFinding: () => _openAddFindingForm(checklist),
            onEditFinding: () => _openEditFindingForm(checklist),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton(double screenWidth) {
    return BlocBuilder<AuditBloc, AuditState>(
      builder: (context, state) {
        final isLoading = state is AuditLoading;

        // ✅ FIX: tombol hanya aktif kalau progress 100% dan tidak sedang loading
        final isComplete = _progress >= 1.0 && _checklists.isNotEmpty;
        final canSubmit = isComplete && !isLoading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Tampilkan hint kalau belum 100%
            if (!isComplete && _checklists.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8, left: screenWidth * 0.06, right: screenWidth * 0.06),
                child: Text(
                  'Selesaikan semua checklist terlebih dahulu (${_completedCount}/${_checklists.length})',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // ✅ null = disabled kalau belum 100% atau sedang loading
                  onPressed: canSubmit ? _onSubmitChecklist : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    // ✅ Warna tombol saat disabled berbeda supaya user tahu
                    disabledBackgroundColor: AppColors.primaryMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Submit Checklist',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}