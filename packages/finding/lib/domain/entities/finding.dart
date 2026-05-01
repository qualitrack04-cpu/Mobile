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

  const Finding({
    required this.id,
    this.sessionId,
    required this.category,
    required this.description,
    required this.clauseRef,
    required this.foundAt,
    required this.status,
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
      ];
}