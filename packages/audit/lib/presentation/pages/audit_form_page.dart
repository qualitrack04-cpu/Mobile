import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../domain/entities/audit_entity.dart';
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
  final _auditorController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _departments = ['Production', 'Warehouse'];

  static const String _iso9001 = 'ISO 9001:2015';
  static const String _iso14001 = 'ISO 14001:2015';

  String? _selectedDepartment;
  DateTime? _selectedDate;
  bool _isPriority = false;
  String? _selectedIso;

  bool get _isEdit => widget.audit != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final audit = widget.audit!;
      _titleController.text = audit.title;
      _auditorController.text = audit.auditorName;
      _descriptionController.text = audit.description;
      _selectedDepartment = audit.department;
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
    _auditorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty &&
      _auditorController.text.trim().isNotEmpty &&
      _selectedDepartment != null &&
      _selectedDate != null;

  // ✅ PERUBAHAN UTAMA: dispatch event ke BLoC, tidak lagi pop entity manual
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
        auditorName: _auditorController.text.trim(),
        isoTemplates: [_selectedIso].whereType<String>().toList(),
        department: _selectedDepartment!,
        date: _selectedDate!,
        description: _descriptionController.text.trim(),
        isPriority: _isPriority,
      ));
    } else {
      bloc.add(CreateAuditEvent(
        title: _titleController.text.trim(),
        auditorName: _auditorController.text.trim(),
        isoTemplates: [_selectedIso].whereType<String>().toList(),
        department: _selectedDepartment!,
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

    // ✅ BlocListener: tutup page setelah create/update berhasil
    return BlocListener<AuditBloc, AuditState>(
      listener: (context, state) {
        if (state is AuditCreated || state is AuditUpdated) {
          Navigator.pop(context);
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

        floatingActionButton: ValueListenableBuilder(
          valueListenable: _titleController,
          builder: (context, _, __) {
            return BlocBuilder<AuditBloc, AuditState>(
              builder: (context, state) {
                final isLoading = state is AuditLoading;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
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
          padding: const EdgeInsets.all(18),
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
                    _buildTextField(
                      label: 'AUDITOR NAME',
                      controller: _auditorController,
                      hint: 'Input auditor name',
                    ),
                    _buildIsoSection(),
                    _buildDepartmentDropdown(),
                    _buildDatePicker(),
                    _buildDescriptionField(),
                    _buildPrioritySwitch(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
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
            onChanged: (value) => setState(() => _selectedIso = value),
            title: Text(_iso9001, style: GoogleFonts.inter(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primaryLight,
          ),
          RadioListTile<String>(
            value: _iso14001,
            groupValue: _selectedIso,
            onChanged: (value) => setState(() => _selectedIso = value),
            title: Text(_iso14001, style: GoogleFonts.inter(fontSize: 12)),
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
              items: _departments.map((dept) {
                return DropdownMenuItem<String>(
                  value: dept,
                  child: Text(dept, style: GoogleFonts.inter(fontSize: 15, color: Colors.black87)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDepartment = value),
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
        if (picked != null) setState(() => _selectedDate = picked);
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
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _isPriority = value),
          ),
        ],
      ),
    );
  }
}