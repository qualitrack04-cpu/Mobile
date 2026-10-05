import 'package:equatable/equatable.dart';
import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/presentation/bloc/spc_state.dart';

/// State halaman Analyses History.
///
/// Filter ikut disimpan di sini supaya dropdown dan data yang tampil tidak
/// mungkin menggambarkan filter yang berbeda.
class SpcHistoryState extends Equatable {
  final SectionStatus status;
  final List<SpcAnalysisSummary> analyses;
  final String? errorMessage;

  final SpcPeriod period;
  final SpcStatus? statusFilter;

  const SpcHistoryState({
    this.status = SectionStatus.initial,
    this.analyses = const [],
    this.errorMessage,
    this.period = SpcPeriod.allTime,
    this.statusFilter,
  });

  bool get isLoading =>
      status == SectionStatus.initial || status == SectionStatus.loading;

  SpcHistoryState copyWith({
    SectionStatus? status,
    List<SpcAnalysisSummary>? analyses,
    String? errorMessage,
    bool clearError = false,
    SpcPeriod? period,
    SpcStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return SpcHistoryState(
      status: status ?? this.status,
      analyses: analyses ?? this.analyses,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      period: period ?? this.period,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }

  @override
  List<Object?> get props => [
        status,
        analyses,
        errorMessage,
        period,
        statusFilter,
      ];
}
