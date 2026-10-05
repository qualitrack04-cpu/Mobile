import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spc/domain/usecases/get_recent_analyses.dart';
import 'package:spc/domain/usecases/get_spc_trends.dart';
import 'package:spc/presentation/bloc/spc_event.dart';
import 'package:spc/presentation/bloc/spc_state.dart';

class SpcBloc extends Bloc<SpcEvent, SpcState> {
  final GetSpcTrends getSpcTrends;
  final GetRecentAnalyses getRecentAnalyses;

  SpcBloc({
    required this.getSpcTrends,
    required this.getRecentAnalyses,
  }) : super(const SpcState()) {
    on<LoadSpcTrends>(_onLoadTrends);
    on<LoadRecentAnalyses>(_onLoadRecent);
  }

  Future<void> _onLoadTrends(
    LoadSpcTrends event,
    Emitter<SpcState> emit,
  ) async {
    emit(
      state.copyWith(
        period: event.period,
        trendStatus: SectionStatus.loading,
        clearTrendError: true,
      ),
    );
    try {
      final trends = await getSpcTrends(event.period);
      emit(
        state.copyWith(
          trendStatus: SectionStatus.success,
          trends: trends,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          trendStatus: SectionStatus.failure,
          trendError: _message(e),
        ),
      );
    }
  }

  Future<void> _onLoadRecent(
    LoadRecentAnalyses event,
    Emitter<SpcState> emit,
  ) async {
    emit(
      state.copyWith(
        recentStatus: SectionStatus.loading,
        clearRecentError: true,
      ),
    );
    try {
      final analyses = await getRecentAnalyses();
      emit(
        state.copyWith(
          recentStatus: SectionStatus.success,
          recentAnalyses: analyses,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          recentStatus: SectionStatus.failure,
          recentError: _message(e),
        ),
      );
    }
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');
}
