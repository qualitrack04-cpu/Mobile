import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';

class FindingModel extends Finding {
  const FindingModel({
    required super.id,
    super.sessionId,
    required super.category,
    required super.description,
    required super.clauseRef,
    required super.foundAt,
    required super.status,
    required super.department,
  });

  // JSON dari backend → FindingModel
  factory FindingModel.fromJson(Map<String, dynamic> json) {
    return FindingModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String?,
      category: FindingCategory.fromString(json['category'] as String),
      description: json['description'] as String,
      clauseRef: json['clauseRef'] as String,
      foundAt: DateTime.parse(json['foundAt'] as String),
      status: FindingStatus.fromString(json['status'] as String),
      department: json['department'] as String,
    );
  }

  // FindingModel → JSON untuk kirim ke backend
  Map<String, dynamic> toJson() {
    return {
      'category': category.toBackendString(),
      'description': description,
      'clauseRef': clauseRef,
      'department': department,
    };
  }
}