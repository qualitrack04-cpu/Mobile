import 'package:equatable/equatable.dart';
import 'package:finding/domain/entities/finding_severity.dart';

abstract class FindingEvent extends Equatable {
  const FindingEvent();

  @override
  List<Object?> get props => [];
}

class LoadFindings extends FindingEvent {
  final FindingStatus? status;
  final FindingCategory? category;

  const LoadFindings({this.status, this.category});

  @override
  List<Object?> get props => [status, category];
}

class CreateFindingEvent extends FindingEvent {
  final FindingCategory category;
  final String description;
  final String clauseRef;
  final String department;

  const CreateFindingEvent({
    required this.category,
    required this.description,
    required this.clauseRef,
    required this.department,
  });

  @override
  List<Object?> get props => [category, description, clauseRef, department];
}

// ✅ BARU: event untuk edit finding
class UpdateFindingEvent extends FindingEvent {
  final String id;
  final FindingCategory category;
  final String description;
  final String clauseRef;
  final String department;

  const UpdateFindingEvent({
    required this.id,
    required this.category,
    required this.description,
    required this.clauseRef,
    required this.department,
  });

  @override
  List<Object?> get props => [id, category, description, clauseRef];
}

class LoadFindingDetail extends FindingEvent {
  final String id;

  const LoadFindingDetail({required this.id});

  @override
  List<Object?> get props => [id];
}
