import 'package:equatable/equatable.dart';
import 'package:finding/domain/entities/finding_severity.dart';

abstract class FindingEvent extends Equatable {
  const FindingEvent();

  @override
  List<Object?> get props => [];
}

class LoadFindings extends FindingEvent {
  final FindingStatus? status;

  const LoadFindings({this.status});

  @override
  List<Object?> get props => [status];
}

class CreateFindingEvent extends FindingEvent {
  final String title;
  final String categoryId;
  final String description;
  final String? clauseRef;
  final String department;
  final String reporter;
  final String? reporterId;
  final String? sessionId;
  final String? checklistItemId;
  final List<String> evidencePaths;

  const CreateFindingEvent({
    required this.title,
    required this.categoryId,
    required this.description,
    this.clauseRef,
    required this.department,
    required this.reporter,
    this.reporterId,
    this.sessionId,
    this.checklistItemId,
    this.evidencePaths = const [],
  });

  @override
  List<Object?> get props => [
        title,
        categoryId,
        description,
        clauseRef,
        department,
        reporter,
        reporterId,
        sessionId,
        checklistItemId,
        evidencePaths,
      ];
}

class UpdateFindingEvent extends FindingEvent {
  final String id;
  final String title;
  final String categoryId;
  final String description;
  final String? clauseRef;
  final String department;
  final String reporter;
  final String? reporterId;
  final List<String> evidencePaths;

  const UpdateFindingEvent({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.description,
    this.clauseRef,
    required this.department,
    required this.reporter,
    this.reporterId,
    this.evidencePaths = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        categoryId,
        description,
        clauseRef,
        department,
        reporter,
        reporterId,
        evidencePaths,
      ];
}

class LoadFindingDetail extends FindingEvent {
  final String id;

  const LoadFindingDetail({required this.id});

  @override
  List<Object?> get props => [id];
}