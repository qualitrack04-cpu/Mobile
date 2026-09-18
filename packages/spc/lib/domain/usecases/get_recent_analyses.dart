import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/domain/repositories/spc_repository.dart';

/// Mengambil beberapa analisis terbaru untuk daftar "Recent Analyses".
///
/// Backend sudah mengurutkan dari yang terbaru (OrderByDescending AnalyzedAt),
/// jadi di sini cukup dipotong sejumlah [limit].
class GetRecentAnalyses {
  final SpcRepository repository;

  GetRecentAnalyses({required this.repository});

  /// Periode dibuat lebar supaya daftar tidak kosong hanya karena tidak ada
  /// analisis dalam 3 bulan terakhir.
  static const SpcPeriod _lookback = SpcPeriod.oneYear;

  Future<List<SpcAnalysisSummary>> call({int limit = 3}) async {
    final analyses = await repository.getHistory(period: _lookback);
    if (analyses.length <= limit) return analyses;
    return analyses.sublist(0, limit);
  }
}
