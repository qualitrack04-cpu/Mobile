import 'package:equatable/equatable.dart';
import 'package:finding/domain/entities/finding.dart';

abstract class FindingState extends Equatable {
  const FindingState();

  @override
  List<Object?> get props => [];
}

class FindingInitial extends FindingState {}

class FindingLoading extends FindingState {}

class FindingLoaded extends FindingState {
  final List<Finding> findings;

  const FindingLoaded({required this.findings});

  @override
  List<Object?> get props => [findings];
}

class FindingCreated extends FindingState {
  final Finding finding;

  const FindingCreated({required this.finding});

  @override
  List<Object?> get props => [finding];
}

// ✅ BARU: state setelah berhasil update finding
class FindingUpdated extends FindingState {
  final Finding finding;

  const FindingUpdated({required this.finding});

  @override
  List<Object?> get props => [finding];
}

class FindingDetailLoaded extends FindingState {
  final Finding finding;

  const FindingDetailLoaded({required this.finding});

  @override
  List<Object?> get props => [finding];
}

class FindingError extends FindingState {
  final String message;

  const FindingError({required this.message});

  @override
  List<Object?> get props => [message];
}
