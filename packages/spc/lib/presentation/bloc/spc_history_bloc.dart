import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spc/domain/usecases/get_analyses_history.dart';
import 'package:spc/presentation/bloc/spc_history_event.dart';
import 'package:spc/presentation/bloc/spc_history_state.dart';
import 'package:spc/presentation/bloc/spc_state.dart';

class SpcHistoryBloc extends Bloc<SpcHistoryEvent, SpcHistoryState> {
  final GetAnalysesHistory getAnalysesHistory;

  SpcHistoryBloc({required this.getAnalysesHistory})
    : super(const SpcHistoryState()) {
    on<LoadAnalysesHistory>(_onLoad);
    on<ChangeHistoryStatus>(_onChangeStatus);
    on<ChangeHistoryPeriod>(_onChangePeriod);
  }

  Future<void> _onLoad(
    LoadAnalysesHistory event,
    Emitter<SpcHistoryState> emit,
  ) async {
    emit(state.copyWith(status: SectionStatus.loading, clearError: true));
    try {
      final analyses = await getAnalysesHistory(
        period: state.period,
        status: state.statusFilter,
      );
      emit(state.copyWith(status: SectionStatus.success, analyses: analyses));
    } catch (e) {
      emit(
        state.copyWith(
          status: SectionStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onChangeStatus(
    ChangeHistoryStatus event,
    Emitter<SpcHistoryState> emit,
  ) async {
    emit(
      SpcHistoryState(
        status: state.status,
        analyses: state.analyses,
        errorMessage: state.errorMessage,
        period: state.period,
        statusFilter: event.status, // null = All status, di-set eksplisit
      ),
    );
    await _onLoad(const LoadAnalysesHistory(), emit);
  }

  Future<void> _onChangePeriod(
    ChangeHistoryPeriod event,
    Emitter<SpcHistoryState> emit,
  ) async {
    emit(state.copyWith(period: event.period));
    await _onLoad(const LoadAnalysesHistory(), emit);
  }
}
