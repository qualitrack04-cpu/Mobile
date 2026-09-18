import 'package:equatable/equatable.dart';

abstract class NewAnalysisEvent extends Equatable {
  const NewAnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// File dipilih lewat file picker.
class FileSelected extends NewAnalysisEvent {
  final String filePath;
  final String fileName;
  final int fileSize;

  const FileSelected({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });

  @override
  List<Object?> get props => [filePath, fileName, fileSize];
}

/// File yang sudah dipilih dibatalkan.
class FileCleared extends NewAnalysisEvent {
  const FileCleared();
}

/// Tombol Analyze ditekan.
class SubmitAnalysis extends NewAnalysisEvent {
  final String parameterName;
  final double lsl;
  final double usl;
  final double? target;
  final String? unit;
  final String? description;

  const SubmitAnalysis({
    required this.parameterName,
    required this.lsl,
    required this.usl,
    this.target,
    this.unit,
    this.description,
  });

  @override
  List<Object?> get props => [parameterName, lsl, usl, target, unit, description];
}