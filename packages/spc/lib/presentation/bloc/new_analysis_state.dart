import 'package:equatable/equatable.dart';
import 'package:spc/domain/entities/spc_analysis.dart';

enum SubmitStatus { idle, submitting, success, failure }

class NewAnalysisState extends Equatable {
  final String? filePath;
  final String? fileName;
  final int? fileSize;

  final SubmitStatus status;
  final String? errorMessage;

  /// Hasil analisis, terisi hanya saat [status] bernilai success.
  final SpcAnalysisResult? result;

  const NewAnalysisState({
    this.filePath,
    this.fileName,
    this.fileSize,
    this.status = SubmitStatus.idle,
    this.errorMessage,
    this.result,
  });

  bool get hasFile => filePath != null;
  bool get isSubmitting => status == SubmitStatus.submitting;

  NewAnalysisState copyWith({
    String? filePath,
    String? fileName,
    int? fileSize,
    bool clearFile = false,
    SubmitStatus? status,
    String? errorMessage,
    bool clearError = false,
    SpcAnalysisResult? result,
  }) {
    return NewAnalysisState(
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
      fileSize: clearFile ? null : (fileSize ?? this.fileSize),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props =>
      [filePath, fileName, fileSize, status, errorMessage, result];
}