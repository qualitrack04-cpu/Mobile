import 'package:equatable/equatable.dart';
import 'finding_severity.dart';

class Finding extends Equatable {
  final String id;
  final String? sessionId;
  final FindingCategory category;
  final String description;
  final String clauseRef;
  final DateTime foundAt;
  final FindingStatus status;
  final String department;
  final String? auditorName;

  const Finding({
    required this.id,
    this.sessionId,
    required this.category,
    required this.description,
    required this.clauseRef,
    required this.foundAt,
    required this.status,
    required this.department,
    this.auditorName,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        category,
        description,
        clauseRef,
        foundAt,
        status,
        auditorName,
      ];
}