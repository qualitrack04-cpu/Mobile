import 'package:spc/domain/entities/spc_analysis.dart';

/// Satu item dari GET /api/Spc/history (SpcHistoryDto).
///
/// Turunan dari entity supaya repository bisa mengembalikannya langsung
/// tanpa konversi tambahan.
class SpcHistoryModel extends SpcAnalysisSummary {
  final double? cp;
  final double? cpk;
  final bool isStable;
  final String? description;

  const SpcHistoryModel({
    required super.id,
    required super.parameterName,
    required super.analyzedAt,
    required super.status,
    this.cp,
    this.cpk,
    this.isStable = true,
    this.description,
  });

  factory SpcHistoryModel.fromJson(Map<String, dynamic> json) {
    return SpcHistoryModel(
      id: json['id']?.toString() ?? '',
      parameterName: json['productName']?.toString() ?? '-',
      // Backend mengirim UTC. Diubah ke waktu lokal supaya pengelompokan
      // bulan dan tampilan jam sesuai zona waktu pengguna.
      analyzedAt: DateTime.parse(json['analyzedAt'] as String).toLocal(),
      status: SpcStatusApi.fromApi(json['status'] as String?),
      cp: (json['cp'] as num?)?.toDouble(),
      cpk: (json['cpk'] as num?)?.toDouble(),
      isStable: json['isStable'] as bool? ?? true,
      description: json['description']?.toString(),
    );
  }
}
