import 'package:core_services/core_services.dart';

/// Model untuk satu data trend quality score per bulan
class QualityTrend {
  final int period;           // nomor bulan (1–12)
  final String periodLabel;   // misal: "Jan 2026"
  final int totalSessions;
  final double complianceScore;
  final double qualityScore;  // nilai yang kita tampilkan di profil (0–100)

  QualityTrend({
    required this.period,
    required this.periodLabel,
    required this.totalSessions,
    required this.complianceScore,
    required this.qualityScore,
  });

  factory QualityTrend.fromJson(Map<String, dynamic> json) {
    return QualityTrend(
      period: json['period'] as int? ?? 0,
      periodLabel: json['periodLabel'] as String? ?? '',
      totalSessions: json['totalSessions'] as int? ?? 0,
      complianceScore: (json['complianceScore'] as num?)?.toDouble() ?? 0.0,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class QualityScoreService {
  final ApiService apiService;

  QualityScoreService({required this.apiService});

  /// Ambil semua trend quality score untuk tahun tertentu.
  /// [year] defaultnya tahun sekarang jika null.
  Future<List<QualityTrend>> getTrends({int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      final res = await apiService.client.get(
        '/api/QualityScore/trend',
        queryParameters: {'year': targetYear},
      );
      final list = res.data as List? ?? [];
      return list
          .map((e) => QualityTrend.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getTrends: $e');
      return [];
    }
  }

  /// Ambil satu angka quality score terbaru (bulan terakhir yang ada data).
  /// Return null jika tidak ada data sama sekali.
  Future<double?> getLatestQualityScore({int? year}) async {
    final trends = await getTrends(year: year);
    if (trends.isEmpty) return null;
    return trends.last.qualityScore;
  }
}
