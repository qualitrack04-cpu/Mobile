import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/domain/repositories/finding_repository.dart';

class CreateFinding {
  final FindingRepository repository;

  CreateFinding({required this.repository});

  Future<Finding> call({
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
    String? auditorName,
  }) async {
    return await repository.createFinding(
      category: category,
      description: description,
      clauseRef: clauseRef,
      department: department,
      auditorName: auditorName,
    );
  }
}