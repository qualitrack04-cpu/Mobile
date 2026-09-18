import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spc/domain/usecases/analyze_spc.dart';
import 'package:spc/presentation/bloc/new_analysis_event.dart';
import 'package:spc/presentation/bloc/new_analysis_state.dart';

class NewAnalysisBloc extends Bloc<NewAnalysisEvent, NewAnalysisState> {
  final AnalyzeSpc analyzeSpc;

  NewAnalysisBloc({required this.analyzeSpc})
      : super(const NewAnalysisState()) {
    on<FileSelected>(_onFileSelected);
    on<FileCleared>(_onFileCleared);
    on<SubmitAnalysis>(_onSubmit);
  }

  void _onFileSelected(FileSelected event, Emitter<NewAnalysisState> emit) {
    emit(
      state.copyWith(
        filePath: event.filePath,
        fileName: event.fileName,
        fileSize: event.fileSize,
        // Error sebelumnya dibersihkan, karena file baru berarti
        // percobaan baru.
        status: SubmitStatus.idle,
        clearError: true,
      ),
    );
  }

  void _onFileCleared(FileCleared event, Emitter<NewAnalysisState> emit) {
    emit(state.copyWith(clearFile: true, clearError: true));
  }

  Future<void> _onSubmit(
    SubmitAnalysis event,
    Emitter<NewAnalysisState> emit,
  ) async {
    final path = state.filePath;
    final name = state.fileName;

    if (path == null || name == null) {
      emit(
        state.copyWith(
          status: SubmitStatus.failure,
          errorMessage: 'Pilih file Excel terlebih dahulu.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: SubmitStatus.submitting, clearError: true));

    try {
      final result = await analyzeSpc(
        filePath: path,
        fileName: name,
        parameterName: event.parameterName,
        lsl: event.lsl,
        usl: event.usl,
        target: event.target,
        unit: event.unit,
        description: event.description,
      );
      emit(state.copyWith(status: SubmitStatus.success, result: result));
    } catch (e) {
      emit(
        state.copyWith(
          status: SubmitStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}