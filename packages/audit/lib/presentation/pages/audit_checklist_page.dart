import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:dotted_border/dotted_border.dart';
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
import '../widgets/audit_summary_dialog.dart';
import '../widgets/checklist_card.dart';
import 'audit_report_preview_page.dart';

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
  String _existingSummary = '';

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

        // CEK APAKAH STATUSNYA PREVIEW
        final state = prefs.getString('${_sessionKey}_state');
        if (state == 'PREVIEW') {
          // Cek apakah user sengaja kembali dari preview (skip redirect)
          final skipRedirect = prefs.getBool('${_sessionKey}_skip_redirect') ?? false;
          if (skipRedirect) {
            // Hapus flag skip, tapi TETAP simpan PREVIEW state
            // agar jika user keluar dan buka lagi dari audit list → masuk ke preview
            await prefs.remove('${_sessionKey}_skip_redirect');
            // Lanjutkan ke checklist tanpa redirect
          } else {
            // Jika aplikasi sempat tertutup setelah Save tapi sebelum PDF,
            // langsung buka halaman Preview tanpa me-load checklist lagi
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: GetIt.instance<AuditBloc>(),
                    child: AuditReportPreviewPage(
                      audit: widget.audit,
                      sessionId: savedSessionId,
                    ),
                  ),
                ),
              );
            }
            return;
          }
        }

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
              'Failed to create audit session: ${e.toString().replaceAll('Exception:', '')}',
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
        datasource.getAuditSummary(sessionId), // Ambil audit summary
      ]);

      final responses = results[0] as Map<String, Map<String, dynamic>>;
      final findings = results[1] as Map<String, Map<String, dynamic>>;
      final summaryStr = results[2] as String?;

      if (!mounted) return;
      setState(() {
        if (summaryStr != null) {
          _existingSummary = summaryStr;
        }

        for (final checklist in _checklists) {
          if (responses.containsKey(checklist.id)) {
            checklist.isPassed = responses[checklist.id]!['isPassed'] as bool;
            checklist.responseId = responses[checklist.id]!['responseId'] as String?;

            if (checklist.responseId != null) {
              datasource.getAuditEvidence(checklist.responseId!).then((url) {
                if (url != null && mounted) {
                  setState(() {
                    checklist.evidencePath = url;
                    checklist.hasEvidence = true;
                  });
                }
              });
            }
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
              reporter: f['reporter'] as String? ?? '',
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
    
    // 1. Save progress ke server
    await datasource.saveProgress(
      sessionId: _sessionId!,
      checklistItemId: checklist.id,
      isPassed: checklist.isPassed!,
    );

    // 2. Tarik ulang data untuk mendapatkan responseId terbaru
    final responses = await datasource.getExistingResponses(_sessionId!);
    if (responses.containsKey(checklist.id) && mounted) {
      setState(() {
        checklist.responseId = responses[checklist.id]!['responseId'] as String?;
      });
    }
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
          child: FindingEditPage(
            finding: checklist.finding!,
            lockFields: true,
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => checklist.finding = result);
    }
  }

  Future<void> _pickEvidence(ChecklistEntity checklist, bool fromCamera) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        if (!mounted) return;
        await _showImagePreviewDialog(checklist, image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showImagePreviewDialog(ChecklistEntity checklist, String imagePath) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Text(
                  'Upload Evidence',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Image Preview with Trash Icon
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Tutup preview jika mau hapus
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEAEA), // Merah muda
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFD32F2F), // Merah tua
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (checklist.responseId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menunggu respon server, coba tekan upload sekali lagi.'),
                          ),
                        );
                        return;
                      }

                      // Tutup preview & Tampilkan Loading
                      Navigator.pop(dialogContext); 
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
                      );

                      // Proses Upload API
                      final datasource = GetIt.instance<ChecklistRemoteDatasource>();
                      final uploadedUrl = await datasource.uploadAuditEvidence(checklist.responseId!, imagePath);

                      // Tutup Loading
                      if (mounted) Navigator.pop(context);

                      if (uploadedUrl != null) {
                        setState(() {
                          checklist.evidencePath = uploadedUrl; // Simpan URL server, bukan lokal
                          checklist.hasEvidence = true;
                        });
                        _showSuccessPopup();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal upload. Pastikan format foto didukung.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                    label: Text(
                      'Upload',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004481), // Warna biru tua seperti di gambar
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black12,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        });
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            elevation: 8,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Evidence Uploaded',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditEvidenceDialog(ChecklistEntity checklist) async {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      barrierDismissible: false,
      builder: (ctx) {
        return _EditEvidenceDialog(
          checklist: checklist,
          onUpload: (newPath) {
            setState(() {
              checklist.evidencePath = newPath;
              checklist.hasEvidence = true;
            });
            _showSuccessPopup();
          },
          onRemove: () {
            // Panggil API untuk menghapus foto secara permanen dari server
            if (checklist.responseId != null) {
              final datasource = GetIt.instance<ChecklistRemoteDatasource>();
              datasource.deleteAuditEvidence(checklist.responseId!);
            }
            setState(() {
              checklist.evidencePath = null;
              checklist.hasEvidence = false;
            });
          },
        );
      },
    );
  }

    Future<void> _onSubmitChecklist() async {
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audit session not ready. Please try again.')),
      );
      return;
    }

    // --- MULAI PERUBAHAN DI SINI ---
    // Munculkan Bottom Sheet Audit Summary
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // PENTING: Agar pop-up bisa terdorong naik saat keyboard HP muncul
      backgroundColor: Colors.transparent, // Transparan agar sudut melengkung pop-up terlihat
      builder: (ctx) {
        return AuditSummaryDialog(
          initialSummary: _existingSummary,
          onSave: (summaryText) async {
            // Tampilkan loading sebentar (opsional tapi disarankan)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Menyimpan hasil audit...')),
            );

            try {
              // 1. Simpan Audit Summary ke Backend
              _existingSummary = summaryText; // Simpan secara lokal
              final apiService = GetIt.instance<ApiService>();
              final dataSource = ChecklistRemoteDatasource(apiService: apiService);
              await dataSource.submitAuditSummary(
                sessionId: _sessionId!,
                content: summaryText,
              );

              // 2. Lanjutkan proses submit checklist seperti biasa
              final prefs = await SharedPreferences.getInstance();
              
              // JANGAN hapus session key di sini, karena belum digenerate PDF-nya
              // await prefs.remove(_sessionKey);

              // Tandai state lokal bahwa aplikasi sudah masuk tahap PREVIEW
              await prefs.setString('${_sessionKey}_state', 'PREVIEW');

              if (mounted) {
                // Submit hasil jawaban ke backend tanpa mengubah status audit menjadi finish
                final datasource = GetIt.instance<ChecklistRemoteDatasource>();
                await datasource.submitChecklistResponses(
                  sessionId: _sessionId!, 
                  checklists: _checklists,
                );
                
                // Menutup pop-up (dialog) terlebih dahulu
                Navigator.pop(context);

                // Tunggu satu frame agar pop selesai sebelum push
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: GetIt.instance<AuditBloc>(),
                          child: AuditReportPreviewPage(
                            audit: widget.audit,
                            sessionId: _sessionId!,
                          ),
                        ),
                      ),
                    );
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menyimpan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
    // --- AKHIR PERUBAHAN ---
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
            widget.audit.department == 'Produksi' ? 'Production' : widget.audit.department,
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
                  title: 'Loading title checklist item',
                  description:
                      'Loading checklist description, please wait.',
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
            onUploadEvidence: (fromCamera) => _pickEvidence(checklist, fromCamera),
            onEditEvidence: () => _showEditEvidenceDialog(checklist),
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
                ? 'Checklist that FAIL must have a finding.\nAdd finding first.'
                : 'All checklists must be answered first.\n$_completedCount of ${_checklists.length} completed.';
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
                      'Cannot Submit Yet',
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
                      'Understand',
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

class _EditEvidenceDialog extends StatefulWidget {
  final ChecklistEntity checklist;
  final Function(String) onUpload;
  final VoidCallback onRemove;

  const _EditEvidenceDialog({
    Key? key,
    required this.checklist,
    required this.onUpload,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<_EditEvidenceDialog> createState() => _EditEvidenceDialogState();
}

class _EditEvidenceDialogState extends State<_EditEvidenceDialog> {
  String? localImagePath;
  bool isNewImage = false;

  @override
  void initState() {
    super.initState();
    localImagePath = widget.checklist.evidencePath;
  }

  Future<void> _pickNewImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        localImagePath = image.path;
        isNewImage = true;
      });
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Pilih Sumber Gambar',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Kamera', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickNewImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Galeri', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickNewImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRemove() {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Remove Evidence?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            content: Text(
              'Are you sure you want to permanently remove this evidence?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textDisabled, fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog konfirmasi
                  widget.onRemove(); // Hapus di parent secara permanen
                  setState(() {
                    localImagePath = null;
                    isNewImage = false;
                  });
                },
                child: Text('Remove', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Text(
                'Edit Evidence',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // UI State 1: Existing Evidence
                            // UI State 1: Existing Evidence
              if (localImagePath != null && !isNewImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: localImagePath!.startsWith('http')
                      ? Image.network(
                          localImagePath!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                const SizedBox(height: 8),
                                const Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey)),
                                // KITA TAMBAHKAN TEKS URL-NYA DI SINI UNTUK DEBUGGING
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    localImagePath ?? 'URL Kosong',
                                    style: const TextStyle(color: Colors.red, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.file(
                          File(localImagePath!),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _confirmRemove,
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    label: Text(
                      'Remove Evidence',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ] 
              // UI State 2: Select New Image (Empty)
              else if (localImagePath == null) ...[
                GestureDetector(
                  onTap: _showImageSourceBottomSheet,
                  child: DottedBorder(
                    options: const RoundedRectDottedBorderOptions(
                      radius: Radius.circular(8),
                      color: Color(0xFFC4D2DE),
                      strokeWidth: 1.5,
                      dashPattern: [6.0, 4.0],
                      padding: EdgeInsets.zero,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F9), // Warna latar biru sangat muda
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2EAF1), // Biru pudar untuk icon box
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: Color(0xFF004481),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select Image',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF004481),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
              // UI State 3: Preview New Image for Upload
              else if (localImagePath != null && isNewImage) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(localImagePath!),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            localImagePath = null;
                            isNewImage = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEAEA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Tutup dialog edit terlebih dahulu
                      widget.onUpload(localImagePath!); // Baru panggil aksi upload di parent
                    },
                    icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                    label: Text(
                      'Upload',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004481),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
