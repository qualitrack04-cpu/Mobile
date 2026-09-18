import 'package:spc/domain/entities/spc_analysis.dart';

/// Response dari POST /api/Spc/analyze dan GET /api/Spc/{id} (SpcResultDto).
class SpcResultModel extends SpcAnalysisResult {
  const SpcResultModel({
    required super.id,
    required super.parameterName,
    super.description,
    required super.mean,
    required super.standardDeviation,
    required super.ucl,
    required super.lcl,
    required super.lsl,
    required super.usl,
    required super.cp,
    required super.cpk,
    required super.status,
    required super.isStable,
    required super.dataCount,
    required super.analyzedAt,
    super.data,
    super.target,
    super.unit,
  });

  factory SpcResultModel.fromJson(Map<String, dynamic> json) {
    return SpcResultModel(
      id: json['id']?.toString() ?? '',
      // Endpoint ini memakai `parameterName`, berbeda dengan /history
      // yang masih memakai `productName`. Bukan salah ketik.
      parameterName: json['parameterName']?.toString() ?? '-',
      description: json['description']?.toString(),
      mean: _toDouble(json['mean']),
      standardDeviation: _toDouble(json['standardDeviation']),
      ucl: _toDouble(json['ucl']),
      lcl: _toDouble(json['lcl']),
      lsl: _toDouble(json['lsl']),
      usl: _toDouble(json['usl']),
      cp: _toDouble(json['cp']),
      cpk: _toDouble(json['cpk']),
      status: SpcStatusApi.fromApi(json['status'] as String?),
      isStable: json['isStable'] as bool? ?? true,
      dataCount: (json['dataCount'] as num?)?.toInt() ?? 0,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String).toLocal(),
      // Kosong kalau dibaca lewat GET /{id} — backend tidak menyimpan
      // data mentah di database.
      data: (json['data'] as List<dynamic>? ?? [])
          .map(_toDouble)
          .toList(),
      // Backend menyimpan target dan unit tapi belum mengembalikannya,
      // jadi untuk sekarang selalu null.
      target: json['target'] == null ? null : _toDouble(json['target']),
      unit: json['unit']?.toString(),
    );
  }

  static double _toDouble(dynamic value) =>
      (value as num?)?.toDouble() ?? 0;
}