import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/domain/repositories/spc_repository.dart';

/// Ringkasan status parameter yang dianalisis dalam [days] hari terakhir.
///
/// Yang dihitung adalah parameter, bukan jumlah analisis: kalau satu
/// parameter dianalisis tiga kali, hanya status analisis terbarunya yang
/// dipakai. Dengan begitu angka "Parameters monitored" mencerminkan kondisi
/// terkini tiap parameter, dan jumlah keempat status selalu sama dengan total.
///
/// Backend hanya menerima periode 3m/6m/1y/all, tidak ada 30 hari, jadi
/// diambil periode 3 bulan lalu disaring di sini.
class GetSpcStatusSummary {
  final SpcRepository repository;

  GetSpcStatusSummary({required this.repository});

  Future<SpcStatusSummary> call({int days = 30}) async {
    assert(days <= 90, 'Periode sumber hanya 3 bulan, maksimal 90 hari.');

    final analyses = await repository.getHistory(
      period: SpcPeriod.threeMonths,
    );

    final cutoff = DateTime.now().subtract(Duration(days: days));

    // Urutkan dari terbaru supaya kemunculan pertama tiap parameter adalah
    // analisis terakhirnya. Backend sudah mengurutkan, tapi tidak dijadikan
    // asumsi.
    final recent = analyses.where((a) => !a.analyzedAt.isBefore(cutoff)).toList()
      ..sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));

    final latestByParameter = <String, SpcStatus>{};
    for (final analysis in recent) {
      final key = analysis.parameterName.trim().toLowerCase();
      latestByParameter.putIfAbsent(key, () => analysis.status);
    }

    final counts = {for (final status in SpcStatus.values) status: 0};
    for (final status in latestByParameter.values) {
      counts[status] = counts[status]! + 1;
    }

    return SpcStatusSummary(
      capable: counts[SpcStatus.capable]!,
      marginal: counts[SpcStatus.marginal]!,
      notCapable: counts[SpcStatus.notCapable]!,
      unstable: counts[SpcStatus.unstable]!,
      days: days,
    );
  }
}