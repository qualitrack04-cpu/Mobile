import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/domain/repositories/spc_repository.dart';

/// Mengambil riwayat analisis lalu mengelompokkannya per bulan untuk chart.
///
/// Backend belum punya endpoint agregat, jadi pengelompokan dilakukan di sini.
/// Kalau nanti tersedia GET /api/Spc/trends, cukup ganti isi [call] — bloc dan
/// UI tidak perlu diubah sama sekali.
class GetSpcTrends {
  final SpcRepository repository;

  GetSpcTrends({required this.repository});

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  Future<List<SpcAnalysisTrend>> call(SpcPeriod period) async {
    final analyses = await repository.getHistory(period: period);

    // Siapkan ember kosong untuk tiap bulan dalam periode, supaya bulan yang
    // tidak punya analisis tetap muncul sebagai bar kosong.
    final now = DateTime.now();
    final buckets = <String, Map<SpcStatus, int>>{};
    final order = <String>[];

    for (int i = period.months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final key = _keyOf(month);
      order.add(key);
      buckets[key] = {for (final status in SpcStatus.values) status: 0};
    }

    for (final analysis in analyses) {
      final key = _keyOf(analysis.analyzedAt);
      final bucket = buckets[key];
      // Data di luar rentang diabaikan, misal karena selisih zona waktu.
      if (bucket == null) continue;
      bucket[analysis.status] = (bucket[analysis.status] ?? 0) + 1;
    }

    return order.map((key) {
      final bucket = buckets[key]!;
      final month = int.parse(key.split('-')[1]);

      return SpcAnalysisTrend(
        monthLabel: _monthLabels[month - 1],
        capable: (bucket[SpcStatus.capable] ?? 0).toDouble(),
        marginal: (bucket[SpcStatus.marginal] ?? 0).toDouble(),
        notCapable: (bucket[SpcStatus.notCapable] ?? 0).toDouble(),
        unstable: (bucket[SpcStatus.unstable] ?? 0).toDouble(),
      );
    }).toList();
  }

  String _keyOf(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
