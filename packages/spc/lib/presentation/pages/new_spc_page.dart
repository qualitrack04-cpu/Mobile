import 'dart:math' as math;

import 'package:core/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/spc_analysis.dart';
import '../bloc/new_analysis_bloc.dart';
import '../bloc/new_analysis_event.dart';
import '../bloc/new_analysis_state.dart';
import '../widgets/spc_parameter_form.dart';
import '../widgets/upload_file_card.dart';
import 'analysis_result_page.dart';

// =====================================================================
// SEMENTARA: backend belum ter-deploy, jadi tombol Analyze langsung
// menampilkan halaman hasil dengan data buatan.
//
// Ubah jadi false begitu API sudah bisa diakses. Tidak ada kode lain
// yang perlu disentuh — jalur bloc, usecase, dan datasource tetap utuh.
// =====================================================================
const bool kUseMockAnalysisResult = false;

/// Form membuat analisis SPC baru.
///
/// Seluruh perhitungan dilakukan backend lewat POST /api/Spc/analyze.
/// Halaman ini hanya mengumpulkan input dan mengirim file Excel.
///
/// Mengembalikan [SpcAnalysisResult] lewat Navigator.pop saat berhasil,
/// supaya halaman pemanggil bisa memuat ulang daftarnya.
class NewSpcAnalysisPage extends StatefulWidget {
  const NewSpcAnalysisPage({super.key});

  @override
  State<NewSpcAnalysisPage> createState() => _NewSpcAnalysisPageState();
}

class _NewSpcAnalysisPageState extends State<NewSpcAnalysisPage> {
  late final NewAnalysisBloc _bloc;

  final _formKey = GlobalKey<FormState>();
  final _parameterNameController = TextEditingController();
  final _targetController = TextEditingController();
  final _lslController = TextEditingController();
  final _uslController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<NewAnalysisBloc>();
    _targetController.addListener(_syncSpecLimits);
  }

  @override
  void dispose() {
    _parameterNameController.dispose();
    _targetController.removeListener(_syncSpecLimits);
    _targetController.dispose();
    _lslController.dispose();
    _uslController.dispose();
    _descriptionController.dispose();
    _bloc.close();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
    );

    final file = result?.files.singleOrNull;
    if (file == null) return;

    // Di platform tertentu path bisa null (misal file dari cloud storage).
    if (file.path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File tidak bisa dibaca. Coba salin dulu ke ponsel.'),
        ),
      );
      return;
    }

    _bloc.add(
      FileSelected(
        filePath: file.path!,
        fileName: file.name,
        fileSize: file.size,
      ),
    );
  }

  void _submit() {
    // Validasi form dulu, baru cek file, supaya pesan error di field
    // tetap muncul meski file belum dipilih.
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    if (kUseMockAnalysisResult) {
      _showMockResult();
      return;
    }

    _bloc.add(
      SubmitAnalysis(
        parameterName: _parameterNameController.text.trim(),
        lsl: double.parse(_lslController.text.trim()),
        usl: double.parse(_uslController.text.trim()),
        target: _targetController.text.trim().isEmpty
            ? null
            : double.tryParse(_targetController.text.trim()),
        unit: _selectedUnit,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }

  /// Membuat hasil analisis buatan dari isian form, memakai rumus yang
  /// sama dengan SpcController supaya angkanya konsisten.
  void _showMockResult() {
    final lsl = double.parse(_lslController.text.trim());
    final usl = double.parse(_uslController.text.trim());
    final target = double.tryParse(_targetController.text.trim());

    final center = target ?? (lsl + usl) / 2;
    final spread = (usl - lsl) / 10;

    // Nilai semu yang menyebar di sekitar center. Seed dibuat tetap supaya
    // hasilnya tidak berubah-ubah tiap kali dicoba.
    final random = math.Random(7);
    final data = List<double>.generate(
      10,
      (_) => double.parse(
        (center + (random.nextDouble() - 0.5) * spread * 3).toStringAsFixed(4),
      ),
    );

    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data
            .map((x) => math.pow(x - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        (data.length - 1);
    final stdDev = math.sqrt(variance);

    final ucl = mean + 3 * stdDev;
    final lcl = mean - 3 * stdDev;
    final cp = (usl - lsl) / (6 * stdDev);
    final cpk = math.min((usl - mean) / (3 * stdDev), (mean - lsl) / (3 * stdDev));

    final isUnstable = data.any((x) => x > ucl || x < lcl);
    final status = isUnstable
        ? SpcStatus.unstable
        : cpk < 1.00
            ? SpcStatus.notCapable
            : cpk < 1.33
                ? SpcStatus.marginal
                : SpcStatus.capable;

    final result = SpcAnalysisResult(
      id: 'mock',
      parameterName: _parameterNameController.text.trim(),
      description: null,
      mean: double.parse(mean.toStringAsFixed(4)),
      standardDeviation: double.parse(stdDev.toStringAsFixed(4)),
      ucl: double.parse(ucl.toStringAsFixed(4)),
      lcl: double.parse(lcl.toStringAsFixed(4)),
      lsl: lsl,
      usl: usl,
      cp: double.parse(cp.toStringAsFixed(4)),
      cpk: double.parse(cpk.toStringAsFixed(4)),
      status: status,
      isStable: !isUnstable,
      dataCount: data.length,
      analyzedAt: DateTime.now(),
      data: data,
      target: target,
      unit: _selectedUnit,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AnalysisResultPage(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NewAnalysisBloc>.value(
      value: _bloc,
      child: BlocConsumer<NewAnalysisBloc, NewAnalysisState>(
        listenWhen: (a, b) => a.status != b.status,
        listener: (context, state) {
          if (state.status == SubmitStatus.success) {
            Navigator.pop(context, state.result);
            return;
          }
          if (state.status == SubmitStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state.isSubmitting;

          return PopScope(
            // Cegah halaman ditutup di tengah upload.
            canPop: !isSubmitting,
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                elevation: 0,
                centerTitle: false,
                iconTheme: const IconThemeData(color: AppColors.primary),
                title: Text(
                  'New SPC Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              body: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    UploadFileCard(
                      fileName: state.fileName,
                      fileSize: state.fileSize,
                      enabled: !isSubmitting,
                      onChooseFile: _pickFile,
                      onClearFile: () => _bloc.add(const FileCleared()),
                    ),
                    const SizedBox(height: 16),
                    SpcParameterForm(
                      parameterNameController: _parameterNameController,
                      targetController: _targetController,
                      lslController: _lslController,
                      uslController: _uslController,
                      selectedUnit: _selectedUnit,
                      enabled: !isSubmitting,
                      onUnitChanged: (value) {
                        setState(() => _selectedUnit = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(isSubmitting),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton(bool isSubmitting) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insights_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Analyze',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
    /// Toleransi spesifikasi: USL = target + 0.5, LSL = target - 0.5.
  static const double _tolerance = 0.5;

  void _syncSpecLimits() {
    final target = double.tryParse(_targetController.text.trim());
    if (target == null) {
      _lslController.clear();
      _uslController.clear();
      return;
    }
    _lslController.text = _format(target - _tolerance);
    _uslController.text = _format(target + _tolerance);
  }

  /// Dibulatkan 4 digit lalu nol di belakang dibuang, supaya 10.1 - 0.5
  /// tampil 9.6, bukan 9.599999999999.
  String _format(double value) {
    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}