import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/auditor_entity.dart';
import '../bloc/audit_bloc.dart';
import '../bloc/audit_event.dart';
import '../bloc/audit_state.dart';

class AuditFormPage extends StatefulWidget {
  final AuditEntity? audit;

  const AuditFormPage({super.key, this.audit});

  @override
  State<AuditFormPage> createState() => _AuditFormPageState();
}

class _AuditFormPageState extends State<AuditFormPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ScrollController untuk auto-scroll ke field aktif
  final _scrollController = ScrollController();

  // Notifier untuk trigger rebuild FAB saat field non-text berubah (ISO, dept, date, auditor)
  final _formNotifier = ValueNotifier<int>(0);

  // State lokal daftar auditor dari backend
  List<AuditorEntity> _auditors = [];
  bool _isLoadingAuditors = true;

  // label (tampilan) → value (dikirim ke backend)
  final Map<String, String> _departments = {
    'Production': 'Produksi',
    'Warehouse': 'Warehouse',
  };

  static const String _iso9001 = 'ISO9001';
  static const String _iso14001 = 'ISO14001';

  String? _selectedDepartment;
  DateTime? _selectedDate;
  bool _isPriority = false;
  String? _selectedIso;
  String? _selectedAuditorId;
  String? _selectedAuditorName;

  bool get _isEdit => widget.audit != null;

  String get _departmentValue =>
      _departments[_selectedDepartment] ?? _selectedDepartment ?? '';

  @override
  void initState() {
    super.initState();

    // Muat daftar auditor saat form dibuka
    context.read<AuditBloc>().add(const LoadAuditors());

    if (_isEdit) {
      final audit = widget.audit!;
      _titleController.text = audit.title;
      // Pre-select auditor berdasarkan nama dari data audit yang diedit
      _selectedAuditorName = audit.auditorName;
      _descriptionController.text = audit.description;
      _selectedDepartment = _departments.entries
          .where((e) => e.value == audit.department)
          .map((e) => e.key)
          .firstOrNull;
      _selectedDate = audit.date;
      _isPriority = audit.isPriority;
      _selectedIso = audit.isoTemplates.firstWhere(
        (t) => t == _iso9001 || t == _iso14001,
        orElse: () => '',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    _formNotifier.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty &&
      _selectedAuditorId != null &&
      _selectedDepartment != null &&
      _selectedDate != null &&
      _selectedIso != null;

  void _onSubmit() {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final bloc = context.read<AuditBloc>();

    if (_isEdit) {
      bloc.add(UpdateAuditEvent(
        audit: widget.audit!,
        title: _titleController.text.trim(),
        auditorName: _selectedAuditorName ?? '',
        isoTemplates: [_selectedIso].whereType<String>().toList(),
        department: _departmentValue,
        date: _selectedDate!,
        description: _descriptionController.text.trim(),
        isPriority: _isPriority,
      ));
    } else {
      bloc.add(CreateAuditEvent(
        title: _titleController.text.trim(),
        auditorName: _selectedAuditorName ?? '',
        isoTemplates: [_selectedIso].whereType<String>().toList(),
        department: _departmentValue,
        date: _selectedDate!,
        description: _descriptionController.text.trim(),
        isPriority: _isPriority,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarFontSize = (screenWidth * 0.07).clamp(22.0, 32.0);

    // FIX 1: Hitung padding bawah = tinggi FAB + jarak aman
    const double fabHeight = 58;
    const double fabBottomMargin = 16; // jarak FAB dari bawah layar
    const double extraPadding = 64; // Tambah padding ekstra agar tidak mepet FAB saat mentok bawah
    const double bottomPadding = fabHeight + fabBottomMargin + extraPadding;

    return BlocListener<AuditBloc, AuditState>(
      listener: (context, state) {
        if (state is AuditCreated) {
          Navigator.pop(context);
        }
        if (state is AuditUpdated) {
          Navigator.pop(context);
        }
        // Update daftar auditor di dropdown
        if (state is AuditorsLoaded) {
          setState(() {
            _isLoadingAuditors = false;
            _auditors = state.auditors;
            // Mode edit: coba cocokkan auditor berdasarkan nama
            if (_isEdit && _selectedAuditorId == null) {
              final match = _auditors.where(
                (a) => a.fullName == _selectedAuditorName,
              ).firstOrNull;
              if (match != null) {
                _selectedAuditorId = match.id;
                _formNotifier.value++;
              }
            }
          });
        }
        if (state is AuditError) {
          setState(() => _isLoadingAuditors = false);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
              ),
            );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        // FIX 2: true agar scaffold otomatis resize saat keyboard muncul
        resizeToAvoidBottomInset: true,

        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          title: Text(
            _isEdit ? 'Edit Plan' : 'Create Plan',
            style: GoogleFonts.inter(
              fontSize: appBarFontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

        floatingActionButton: ListenableBuilder(
          listenable: Listenable.merge([
            _titleController,
            _formNotifier,
          ]),
          builder: (context, _) {
            return BlocBuilder<AuditBloc, AuditState>(
              builder: (context, state) {
                final isLoading = state is AuditLoading;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (_isFormValid)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: fabHeight,
                    child: ElevatedButton.icon(
                      onPressed: (_isFormValid && !isLoading) ? _onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primaryMuted,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add_task_rounded, color: Colors.white),
                      label: Text(
                        _isEdit ? 'Edit Plan' : 'Create Plan',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        body: SingleChildScrollView(
          controller: _scrollController, // FIX 2: pasang controller
          // FIX 1: padding bawah cukup agar konten tidak tertutup FAB
          padding: const EdgeInsets.fromLTRB(18, 18, 18, bottomPadding),
          // FIX 2: keyboard otomatis scroll ke field yang sedang aktif
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'TITLE',
                      controller: _titleController,
                      hint: 'Input audit title',
                    ),
                    _buildAuditorDropdown(),
                    _buildIsoSection(),
                    _buildDepartmentDropdown(),
                    _buildDatePicker(),
                    _buildDescriptionField(),
                    _buildPrioritySwitch(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditorDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUDITOR NAME',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingAuditors)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Memuat daftar auditor...'),
                ],
              ),
            )
          else if (_auditors.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daftar auditor belum tersedia',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _isLoadingAuditors = true);
                      context.read<AuditBloc>().add(const LoadAuditors());
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Muat Ulang',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAuditorId,
                isExpanded: true,
                hint: Text(
                  'Pilih auditor',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textDisabled,
                  ),
                ),
                items: _auditors.where((a) => a.role == 'Auditor').map((auditor) {
                  return DropdownMenuItem<String>(
                    value: auditor.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          auditor.fullName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          auditor.role,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final selected = _auditors.firstWhere((a) => a.id == id);
                  setState(() {
                    _selectedAuditorId = id;
                    _selectedAuditorName = selected.fullName;
                    _formNotifier.value++;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: GoogleFonts.inter(fontSize: 12),
            // FIX 2: keyboard muncul → Flutter otomatis scroll ke field ini
            textInputAction: TextInputAction.next,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppColors.textDisabled),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ISO TEMPLATE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          RadioListTile<String>(
            value: _iso9001,
            groupValue: _selectedIso,
            onChanged: (value) => setState(() {
              _selectedIso = value;
              _formNotifier.value++;
            }),
            title: Text('ISO 9001', style: GoogleFonts.inter(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primaryLight,
          ),
          RadioListTile<String>(
            value: _iso14001,
            groupValue: _selectedIso,
            onChanged: (value) => setState(() {
              _selectedIso = value;
              _formNotifier.value++;
            }),
            title: Text('ISO 14001', style: GoogleFonts.inter(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEPARTMENT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              hint: Text(
                'Select department',
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textDisabled),
              ),
              items: _departments.keys.map((label) {
                return DropdownMenuItem<String>(
                  value: label,
                  child: Text(label, style: GoogleFonts.inter(fontSize: 15, color: Colors.black87)),
                );
              }).toList(),
              onChanged: (label) => setState(() {
                _selectedDepartment = label;
                _formNotifier.value++;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.primaryLight),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _formNotifier.value++;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DATE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedDate == null
                      ? 'Select date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _selectedDate == null ? AppColors.textDisabled : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPTION',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 12),
            textInputAction: TextInputAction.done,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            decoration: InputDecoration(
              hintText: 'Detail the non-conformance observed during the audit...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textDisabled),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PRIORITY',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          Switch(
            value: _isPriority,
            activeThumbColor: AppColors.primary,
            onChanged: (value) => setState(() => _isPriority = value),
          ),
        ],
      ),
    );
  }
}