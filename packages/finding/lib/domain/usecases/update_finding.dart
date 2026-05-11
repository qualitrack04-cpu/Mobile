import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/domain/repositories/finding_repository.dart';

class UpdateFinding {
  final FindingRepository repository;

  UpdateFinding({required this.repository});

  Future<Finding> call({
    required String id,
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
  }) async {
    return await repository.updateFinding(
      id: id,
      category: category,
      description: description,
      clauseRef: clauseRef,
      department: department,
    );
  }
}
