import 'package:equatable/equatable.dart';
import 'package:spc/domain/entities/spc_analysis.dart';

abstract class SpcHistoryEvent extends Equatable {
  const SpcHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Muat daftar dengan filter saat ini. Filter yang tidak disebut tetap dipakai.
class LoadAnalysesHistory extends SpcHistoryEvent {
  const LoadAnalysesHistory();
}

/// Ganti filter status. Null berarti semua status.
class ChangeHistoryStatus extends SpcHistoryEvent {
  final SpcStatus? status;

  const ChangeHistoryStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// Ganti filter periode.
class ChangeHistoryPeriod extends SpcHistoryEvent {
  final SpcPeriod period;

  const ChangeHistoryPeriod(this.period);

  @override
  List<Object?> get props => [period];
}
