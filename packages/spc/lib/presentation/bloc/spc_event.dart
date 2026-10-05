import 'package:equatable/equatable.dart';
import 'package:spc/domain/entities/spc_analysis.dart';

abstract class SpcEvent extends Equatable {
  const SpcEvent();

  @override
  List<Object?> get props => [];
}

/// Muat data chart untuk periode tertentu.
/// Dipakai saat halaman dibuka, periode diganti, dan saat "coba lagi".
class LoadSpcTrends extends SpcEvent {
  final SpcPeriod period;

  const LoadSpcTrends({required this.period});

  @override
  List<Object?> get props => [period];
}

/// Muat daftar analisis terbaru.
class LoadRecentAnalyses extends SpcEvent {
  const LoadRecentAnalyses();
}
