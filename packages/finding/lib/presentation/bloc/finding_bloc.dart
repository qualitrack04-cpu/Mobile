import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finding/domain/usecases/create_finding.dart';
import 'package:finding/domain/repositories/finding_repository.dart';
import 'finding_event.dart';
import 'finding_state.dart';

class FindingBloc extends Bloc<FindingEvent, FindingState> {
  final FindingRepository repository;
  final CreateFinding createFinding;

  FindingBloc({required this.repository, required this.createFinding})
    : super(FindingInitial()) {
    on<LoadFindings>(_onLoadFindings);
    on<CreateFindingEvent>(_onCreateFinding);
    on<LoadFindingDetail>(_onLoadFindingDetail);
  }

  Future<void> _onLoadFindings(
    LoadFindings event,
    Emitter<FindingState> emit,
  ) async {
    emit(FindingLoading());
    try {
      final findings = await repository.getFindings(
        status: event.status,
        category: event.category,
      );
      emit(FindingLoaded(findings: findings));
    } catch (e) {
      emit(FindingError(message: e.toString()));
    }
  }

  Future<void> _onLoadFindingDetail(
    LoadFindingDetail event,
    Emitter<FindingState> emit,
  ) async {
    emit(FindingLoading());
    try {
      final finding = await repository.getFindingDetail(event.id);
      emit(FindingDetailLoaded(finding: finding));
    } catch (e) {
      emit(FindingError(message: e.toString()));
    }
  }

  Future<void> _onCreateFinding(
    CreateFindingEvent event,
    Emitter<FindingState> emit,
  ) async {
    emit(FindingLoading());
    try {
      final finding = await createFinding(
        category: event.category,
        description: event.description,
        clauseRef: event.clauseRef,
      );
      emit(FindingCreated(finding: finding));

      final findings = await repository.getFindings();
      emit(FindingLoaded(findings: findings));
    } catch (e) {
      emit(FindingError(message: e.toString()));
    }
  }
}
