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
  final String? auditorName;
  final String? sessionId;         // ✅ TAMBAH
  final String? checklistItemId;   // ✅ TAMBAH
  final List<String> evidencePaths;

  const CreateFindingEvent({
    required this.category,
    required this.description,
    required this.clauseRef,
    required this.department,
    this.auditorName,
    this.sessionId,                // ✅ TAMBAH
    this.checklistItemId,          // ✅ TAMBAH
    this.evidencePaths = const [],
  });

  @override
  List<Object?> get props => [
        category,
        description,
        clauseRef,
        department,
        auditorName,
        sessionId,
        checklistItemId,
        evidencePaths,
      ];
}

class UpdateFindingEvent extends FindingEvent {
  final String id;
  final FindingCategory category;
  final String description;
  final String clauseRef;
  final String department;
  final List<String> evidencePaths;

  const UpdateFindingEvent({
    required this.id,
    required this.category,
    required this.description,
    required this.clauseRef,
    required this.department,
    this.evidencePaths = const [],
  });

  @override
  List<Object?> get props => [id, category, description, clauseRef, department, evidencePaths];
}

class LoadFindingDetail extends FindingEvent {
  final String id;

  const LoadFindingDetail({required this.id});

  @override
  List<Object?> get props => [id];
}