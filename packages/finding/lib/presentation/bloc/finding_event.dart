import 'package:equatable/equatable.dart';
import 'package:finding/domain/entities/finding_severity.dart';

abstract class FindingEvent extends Equatable {
  const FindingEvent();

  @override
  List<Object?> get props => [];
}

// Load semua finding
class LoadFindings extends FindingEvent {
  final FindingStatus? status;
  final FindingCategory? category;

  const LoadFindings({
    this.status,
    this.category,
  });

  @override
  List<Object?> get props => [status, category];
}

// Buat finding baru (dari form)
class CreateFindingEvent extends FindingEvent {
  final FindingCategory category;
  final String description;
  final String clauseRef;

  const CreateFindingEvent({
    required this.category,
    required this.description,
    required this.clauseRef,
  });

  @override
  List<Object?> get props => [category, description, clauseRef];
}

class LoadFindingDetail extends FindingEvent {
  final String id;

  const LoadFindingDetail({required this.id});

  @override
  List<Object?> get props => [id];
}