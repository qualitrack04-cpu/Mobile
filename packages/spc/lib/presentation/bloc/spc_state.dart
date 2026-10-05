import 'package:equatable/equatable.dart';
import 'package:spc/domain/entities/spc_analysis.dart';

/// Status pemuatan satu bagian halaman.
enum SectionStatus { initial, loading, success, failure }

/// State halaman SPC.
///
/// Dibuat sebagai satu class dengan status per bagian, bukan satu class per
/// state. Alasannya halaman ini punya dua bagian yang dimuat terpisah: chart
/// tren dan daftar Recent Analyses. Dengan pola satu-class-per-state, memuat
/// ulang chart akan menghapus daftar dari layar, dan sebaliknya.
class SpcState extends Equatable {
  final SpcPeriod period;

  final SectionStatus trendStatus;
  final List<SpcAnalysisTrend> trends;
  final String? trendError;

  final SectionStatus recentStatus;
  final List<SpcAnalysisSummary> recentAnalyses;
  final String? recentError;

  const SpcState({
    this.period = SpcPeriod.threeMonths,
    this.trendStatus = SectionStatus.initial,
    this.trends = const [],
    this.trendError,
    this.recentStatus = SectionStatus.initial,
    this.recentAnalyses = const [],
    this.recentError,
  });

  bool get isTrendLoading =>
      trendStatus == SectionStatus.initial ||
      trendStatus == SectionStatus.loading;

  bool get isRecentLoading =>
      recentStatus == SectionStatus.initial ||
      recentStatus == SectionStatus.loading;

  /// Pesan error dikosongkan lewat flag terpisah karena null pada parameter
  /// copyWith berarti "tidak diubah", bukan "kosongkan".
  SpcState copyWith({
    SpcPeriod? period,
    SectionStatus? trendStatus,
    List<SpcAnalysisTrend>? trends,
    String? trendError,
    bool clearTrendError = false,
    SectionStatus? recentStatus,
    List<SpcAnalysisSummary>? recentAnalyses,
    String? recentError,
    bool clearRecentError = false,
  }) {
    return SpcState(
      period: period ?? this.period,
      trendStatus: trendStatus ?? this.trendStatus,
      trends: trends ?? this.trends,
      trendError: clearTrendError ? null : (trendError ?? this.trendError),
      recentStatus: recentStatus ?? this.recentStatus,
      recentAnalyses: recentAnalyses ?? this.recentAnalyses,
      recentError: clearRecentError ? null : (recentError ?? this.recentError),
    );
  }

  @override
  List<Object?> get props => [
        period,
        trendStatus,
        trends,
        trendError,
        recentStatus,
        recentAnalyses,
        recentError,
      ];
}
