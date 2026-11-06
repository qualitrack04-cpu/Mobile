import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/repositories/finding_repository.dart';

class UpdateFinding {
  final FindingRepository repository;

  UpdateFinding({required this.repository});

  Future<Finding> call({
    required String id,
    required String categoryId,
    required String description,
    required String clauseRef,
    required String department,
    required String reporter,
    String? reporterId,
  }) async {
    return await repository.updateFinding(
      id: id,
      categoryId: categoryId,
      description: description,
      clauseRef: clauseRef,
      department: department,
      reporter: reporter,
      reporterId: reporterId,
    );
  }
}