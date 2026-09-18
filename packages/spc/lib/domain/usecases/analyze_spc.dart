import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/domain/repositories/spc_repository.dart';

/// Mengunggah file Excel dan menjalankan analisis SPC di server.
///
/// Seluruh perhitungan (mean, UCL/LCL, Cp, Cpk, penentuan status) dilakukan
/// backend. Mobile hanya mengirim input dan menampilkan hasilnya.
class AnalyzeSpc {
  final SpcRepository repository;

  AnalyzeSpc({required this.repository});

  Future<SpcAnalysisResult> call({
    required String filePath,
    required String fileName,
    required String parameterName,
    required double lsl,
    required double usl,
    double? target,
    String? unit,
    String? description,
  }) {
    return repository.analyze(
      filePath: filePath,
      fileName: fileName,
      parameterName: parameterName,
      lsl: lsl,
      usl: usl,
      target: target,
      unit: unit,
      description: description,
    );
  }
}