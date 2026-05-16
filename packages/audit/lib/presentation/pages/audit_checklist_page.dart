import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/services/api_service.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/pages/finding_form_page.dart';
import 'package:finding/presentation/pages/finding_edit_page.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/checklist_remote_datasource.dart';
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
  String? _sessionId;
  bool _progressLoaded = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    context.read<AuditBloc>().add(
      LoadChecklist(
        isoTemplate: widget.audit.isoTemplates.isNotEmpty
            ? widget.audit.isoTemplates.first
            : '',
        department: widget.audit.department,
      ),
    );
    _createSession();
  }

  String get _sessionKey => 'audit_session_${widget.audit.scheduleId}';

  Future<void> _createSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedSessionId = prefs.getString(_sessionKey);
      if (savedSessionId != null) {
        setState(() => _sessionId = savedSessionId);

        if (_checklists.isNotEmpty && !_progressLoaded) {
          _progressLoaded = true;
          await _loadExistingProgress(savedSessionId);
        }
        return;
      }

      final listResponse = await GetIt.instance<ApiService>().client.get(
        '/api/Checklist',
        queryParameters: {
          'standard': widget.audit.isoTemplates.isNotEmpty
              ? widget.audit.isoTemplates.first
              : '',
          'department': widget.audit.department,
        },
      );
      final checklists = listResponse.data as List<dynamic>;
      if (checklists.isEmpty) {
        if (mounted) setState(() => _isInitializing = false);
        return;
      }
      final checklistId = checklists[0]['id'] as String;

      final datasource = GetIt.instance<ChecklistRemoteDatasource>();
      final sessionId = await datasource.createAuditSession(
        scheduleId: widget.audit.scheduleId,
        checklistId: checklistId,
      );

      await prefs.setString(_sessionKey, sessionId);
      setState(() => _sessionId = sessionId);

      if (_checklists.isNotEmpty && !_progressLoaded) {
        _progressLoaded = true;
        await _loadExistingProgress(sessionId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat sesi audit: ${e.toString().replaceAll('Exception:', '')}',
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadExistingProgress(String sessionId) async {
    try {
      final datasource = GetIt.instance<ChecklistRemoteDatasource>();

      final results = await Future.wait([
        datasource.getExistingResponses(sessionId),
        datasource.getExistingFindings(sessionId),
      ]);

      final responses = results[0] as Map<String, bool>;
      final findings = results[1] as Map<String, Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        for (final checklist in _checklists) {
          if (responses.containsKey(checklist.id)) {
            checklist.isPassed = responses[checklist.id];
          }
          if (findings.containsKey(checklist.id)) {
            final f = findings[checklist.id]!;
            checklist.hasFinding = true;
            checklist.finding = Finding(
              id: f['id'] as String,
              department: f['department'] as String? ?? '',
              category: FindingCategory.fromString(
                f['category'] as String? ?? 'MajorNC',
              ),
              description: f['description'] as String? ?? '',
              clauseRef: f['clauseRef'] as String? ?? '',
              auditorName: f['auditorName'] as String?,
              foundAt:
                  DateTime.tryParse(f['foundAt'] as String? ?? '') ??
                  DateTime.now(),
              status: FindingStatus.fromString(
                f['status'] as String? ?? 'Open',
              ),
              sessionId: f['sessionId'] as String?,
            );
          }
        }
        _isInitializing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _autoSave(ChecklistEntity checklist) async {
    if (_sessionId == null || checklist.isPassed == null) return;
    final datasource = GetIt.instance<ChecklistRemoteDatasource>();
    await datasource.saveProgress(
      sessionId: _sessionId!,
      checklistItemId: checklist.id,
      isPassed: checklist.isPassed!,
    );
  }

  String get _formattedDate {
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
    final date = widget.audit.date;
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int get _completedCount =>
      _checklists.where((e) => e.isPassed != null).length;

  double get _progress =>
      _checklists.isEmpty ? 0 : _completedCount / _checklists.length;

  Future<void> _openAddFindingForm(ChecklistEntity checklist) async {
    final result = await Navigator.push<Finding>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: GetIt.instance<FindingBloc>(),
          child: FindingFormPage(
            initialDepartment: widget.audit.department,
            auditorName: widget.audit.auditorName,
            clauseRef: checklist.description,
            sessionId: _sessionId,
            checklistItemId: checklist.id,
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        checklist.hasFinding = true;
        checklist.finding = result;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        GetIt.instance<FindingBloc>().add(const LoadFindings());
      });
    }
  }

  Future<void> _openEditFindingForm(ChecklistEntity checklist) async {
    if (checklist.finding == null) return;

    final result = await Navigator.push<Finding>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: GetIt.instance<FindingBloc>(),
          child: FindingEditPage(finding: checklist.finding!),
        ),
      ),
    );

    if (result != null) {
      setState(() => checklist.finding = result);
    }
  }

  Future<void> _onSubmitChecklist() async {
    if (_sessionId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Sesi audit belum siap. Coba lagi.'),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);

    context.read<AuditBloc>().add(
      SubmitChecklistEvent(
        sessionId: _sessionId!,
        checklists: _checklists,
        audit: widget.audit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarFontSize = (screenWidth * 0.07).clamp(22.0, 32.0);

    return BlocListener<AuditBloc, AuditState>(
      listener: (context, state) {
        if (state is ChecklistLoaded) {
          setState(() => _checklists = state.checklists);

          if (_sessionId != null && !_progressLoaded) {
            _progressLoaded = true;
            _loadExistingProgress(_sessionId!);
          }
          // Jika _sessionId masih null, tunggu _createSession selesai
        } else if (state is AuditMarkedFinished) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text('Checklist berhasil disubmit!'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(12),
                duration: const Duration(seconds: 2),
              ),
            );
          Navigator.pop(context, true);
        } else if (state is AuditError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(12),
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
    final double sw = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.all(sw * 0.05),
      padding: EdgeInsets.all(sw * 0.04),
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

  // ─────────────────────────────────────────────────────────────────────────
  // CHECKLIST CONTENT — skeleton saat loading, list saat sudah siap
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildChecklistContent() {
    if (_isInitializing) {
      return Expanded(
        child: Skeletonizer(
          enabled: true,
          effect: const ShimmerEffect(
            baseColor: Color(0xFFE8EDF2),
            highlightColor: Color(0xFFF5F7FA),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 120),
            itemCount: 5,
            itemBuilder: (context, index) {
              return ChecklistCard(
                checklist: ChecklistEntity(
                  id: 'skeleton-$index',
                  title: 'Loading judul checklist item',
                  description:
                      'Deskripsi checklist sedang dimuat, harap tunggu sebentar.',
                  category: 'Loading',
                  isPassed:
                      null, // null = belum dijawab, tombol PASS/FAIL tampil normal
                  hasFinding: false,
                ),
              );
            },
          ),
        ),
      );
    }

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
            onPass: () {
              setState(() => checklist.isPassed = true);
              _autoSave(checklist);
            },
            onFail: () {
              setState(() => checklist.isPassed = false);
              _autoSave(checklist);
            },
            onAddFinding: () => _openAddFindingForm(checklist),
            onEditFinding: () => _openEditFindingForm(checklist),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT BUTTON — tidak ada spinner, cukup disable saat loading/initializing
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSubmitButton(double screenWidth) {
    return BlocBuilder<AuditBloc, AuditState>(
      builder: (context, state) {
        final isLoading = state is AuditLoading;

        final allAnswered =
            _checklists.isNotEmpty &&
            _checklists.every((c) => c.isPassed != null);
        final failWithoutFinding = _checklists.any(
          (c) => c.isPassed == false && !c.hasFinding,
        );
        final isComplete = allAnswered && !failWithoutFinding;
        final canSubmit = isComplete && !isLoading && !_isInitializing;

        void handleSubmitPress() {
          if (isLoading) return;
          if (canSubmit) {
            _onSubmitChecklist();
          } else {
            final message = failWithoutFinding
                ? 'Checklist yang FAIL harus memiliki finding.\nTambahkan finding terlebih dahulu.'
                : 'Semua checklist harus dijawab terlebih dahulu.\n$_completedCount dari ${_checklists.length} selesai.';
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Belum Bisa Submit',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                content: Text(
                  message,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.6),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Mengerti',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (isLoading || _isInitializing)
                  ? null
                  : handleSubmitPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit
                    ? AppColors.primaryLight
                    : AppColors.primaryMuted,
                disabledBackgroundColor: AppColors.primaryMuted,
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
      },
    );
  }
}
