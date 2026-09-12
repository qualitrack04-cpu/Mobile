import 'package:core/app_colors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Status hasil analisis SPC, dipetakan dari field status yang dikirim API.
enum SpcStatus { capable, marginal, notCapable, unstable }

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
  final String title;
  final DateTime analyzedAt;
  final SpcStatus status;

  const SpcAnalysisSummary({
    required this.id,
    required this.title,
    required this.analyzedAt,
    required this.status,
  });

  @override
  List<Object?> get props => [id, title, analyzedAt, status];
}