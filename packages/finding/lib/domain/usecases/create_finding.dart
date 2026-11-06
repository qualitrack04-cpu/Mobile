import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/repositories/finding_repository.dart';

class CreateFinding {
  final FindingRepository repository;

  CreateFinding({required this.repository});

  Future<Finding> call({
    required String categoryId,
    required String description,
    required String clauseRef,
    required String department,
    required String reporter,
    String? reporterId,
    String? sessionId,
    String? checklistItemId,
  }) async {
    return await repository.createFinding(
      categoryId: categoryId,
      description: description,
      clauseRef: clauseRef,
      department: department,
      reporter: reporter,
      reporterId: reporterId,
      sessionId: sessionId,
      checklistItemId: checklistItemId,
    );
  }
}