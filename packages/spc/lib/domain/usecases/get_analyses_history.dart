import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/domain/repositories/spc_repository.dart';

/// Mengambil daftar analisis untuk halaman Analyses History,
/// dengan filter periode dan status.
class GetAnalysesHistory {
  final SpcRepository repository;

  GetAnalysesHistory({required this.repository});

  Future<List<SpcAnalysisSummary>> call({
    required SpcPeriod period,
    SpcStatus? status,
    String? productName,
  }) {
    return repository.getHistory(
      period: period,
      status: status,
      productName: productName,
    );
  }
}
