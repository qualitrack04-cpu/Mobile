import 'package:equatable/equatable.dart';
import 'package:finding/domain/entities/finding.dart';

abstract class FindingState extends Equatable {
  const FindingState();

  @override
  List<Object?> get props => [];
}

// State awal
class FindingInitial extends FindingState {}

// State loading
class FindingLoading extends FindingState {}

// State berhasil load list finding
class FindingLoaded extends FindingState {
  final List<Finding> findings;

  const FindingLoaded({required this.findings});

  @override
  List<Object?> get props => [findings];
}

// State berhasil create finding
class FindingCreated extends FindingState {
  final Finding finding;

  const FindingCreated({required this.finding});

  @override
  List<Object?> get props => [finding];
}

class FindingDetailLoaded extends FindingState {
  final Finding finding;

  const FindingDetailLoaded({required this.finding});

  @override
  List<Object?> get props => [finding];
}

// State error
class FindingError extends FindingState {
  final String message;

  const FindingError({required this.message});

  @override
  List<Object?> get props => [message];
}