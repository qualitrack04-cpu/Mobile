import 'package:core/app_colors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Periode yang bisa dipilih pada chart tren.
///
/// [apiValue] mengikuti query parameter `period` di GET /api/Spc/history.
enum SpcPeriod {
  threeMonths('3 Month', '3m', 3),
  sixMonths('6 Month', '6m', 6),
  oneYear('1 Year', '1y', 12),
  allTime('All Time', 'all', 0);

  const SpcPeriod(this.label, this.apiValue, this.months);

  final String label;
  final String apiValue;
  final int months;

  /// Periode yang bisa dipakai chart tren.
  ///
  /// allTime dikecualikan karena chart mengelompokkan data ke sejumlah ember
  /// bulan, dan rentang tanpa batas tidak punya jumlah bulan yang pasti.
  static List<SpcPeriod> get chartOptions =>
      values.where((period) => period != allTime).toList();
}

/// Status hasil analisis SPC, dipetakan dari field status yang dikirim API.
enum SpcStatus { capable, marginal, notCapable, unstable }

extension SpcStatusApi on SpcStatus {
  /// Nilai persis yang dipakai backend (lihat SpcController.Analyze).
  String get apiValue {
    switch (this) {
      case SpcStatus.capable:
        return 'Process Capable';
      case SpcStatus.marginal:
        return 'Marginal';
      case SpcStatus.notCapable:
        return 'Not Capable';
      case SpcStatus.unstable:
        return 'Process Unstable';
    }
  }

  /// Kebalikan dari [apiValue]. Status tak dikenal dianggap [unstable]
  /// supaya anomali terlihat, bukan diam-diam dihitung sebagai capable.
  static SpcStatus fromApi(String? value) {
    switch (value) {
      case 'Process Capable':
      case 'Capable':
        return SpcStatus.capable;
      case 'Marginal':
        return SpcStatus.marginal;
      case 'Not Capable':
        return SpcStatus.notCapable;
      case 'Process Unstable':
      default:
        return SpcStatus.unstable;
    }
  }
}

extension SpcStatusView on SpcStatus {
  String get label {
    switch (this) {
      case SpcStatus.capable:
        return 'Capable';
      case SpcStatus.marginal:
        return 'Marginal';
      case SpcStatus.notCapable:
        return 'Not Capable';
      case SpcStatus.unstable:
        return 'Process Unstable';
    }
  }

  Color get color {
    switch (this) {
      case SpcStatus.capable:
        return AppColors.spcCapable;
      case SpcStatus.marginal:
        return AppColors.spcMarginal;
      case SpcStatus.notCapable:
        return AppColors.spcNotCapable;
      case SpcStatus.unstable:
        return AppColors.spcUnstable;
    }
  }

  /// Versi pendek untuk chip, supaya baris tidak terlalu panjang.
  String get shortLabel =>
      this == SpcStatus.unstable ? 'Unstable' : label;

  /// Status yang perlu ditindaklanjuti, ditandai ikon peringatan pada chip.
  bool get needsAttention => this == SpcStatus.unstable;
}

/// Rekap jumlah analisis per bulan, dipecah berdasarkan status.
class SpcAnalysisTrend extends Equatable {
  final String monthLabel;
  final double capable;
  final double marginal;
  final double notCapable;
  final double unstable;

  const SpcAnalysisTrend({
    required this.monthLabel,
    required this.capable,
    required this.marginal,
    required this.notCapable,
    required this.unstable,
  });

  double get total => capable + marginal + notCapable + unstable;

  @override
  List<Object?> get props => [
        monthLabel,
        capable,
        marginal,
        notCapable,
        unstable,
      ];
}

/// Ringkasan satu analisis SPC untuk ditampilkan di daftar.
class SpcAnalysisSummary extends Equatable {
  final String id;
  final String parameterName;
  final DateTime analyzedAt;
  final SpcStatus status;

  const SpcAnalysisSummary({
    required this.id,
    required this.parameterName,
    required this.analyzedAt,
    required this.status,
  });

  @override
  List<Object?> get props => [id, parameterName, analyzedAt, status];
}

/// Hasil lengkap satu analisis SPC (SpcResultDto dari backend).
///
/// Dipakai response POST /api/Spc/analyze dan GET /api/Spc/{id}.
/// Berbeda dengan [SpcAnalysisSummary] yang hanya untuk daftar.
class SpcAnalysisResult extends Equatable {
  final String id;
  final String parameterName;
  final String? description;

  final double mean;
  final double standardDeviation;
  final double ucl;
  final double lcl;
  final double lsl;
  final double usl;
  final double cp;
  final double cpk;

  final SpcStatus status;
  final bool isStable;
  final int dataCount;
  final DateTime analyzedAt;

  /// Nilai mentah dari Excel. Kosong kalau diambil lewat GET /api/Spc/{id},
  /// karena backend tidak menyimpan data mentah di database.
  final List<double> data;

  /// Dikirim saat analisis dibuat dan tersimpan di database, tapi belum
  /// dikembalikan backend di SpcResultDto — jadi untuk sekarang selalu null.
  final double? target;
  final String? unit;

  const SpcAnalysisResult({
    required this.id,
    required this.parameterName,
    this.description,
    required this.mean,
    required this.standardDeviation,
    required this.ucl,
    required this.lcl,
    required this.lsl,
    required this.usl,
    required this.cp,
    required this.cpk,
    required this.status,
    required this.isStable,
    required this.dataCount,
    required this.analyzedAt,
    this.data = const [],
    this.target,
    this.unit,
  });

  @override
  List<Object?> get props => [
        id,
        parameterName,
        description,
        mean,
        standardDeviation,
        ucl,
        lcl,
        lsl,
        usl,
        cp,
        cpk,
        status,
        isStable,
        dataCount,
        analyzedAt,
        data,
        target,
        unit,
      ];
}