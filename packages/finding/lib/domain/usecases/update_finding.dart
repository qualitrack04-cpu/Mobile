import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/repositories/finding_repository.dart';

class UpdateFinding {
  final FindingRepository repository;

  UpdateFinding({required this.repository});

  Future<Finding> call({
    required String id,
    required String title,
    required String categoryId,
    required String description,
    String? clauseRef,
    required String department,
    required String reporter,
    String? reporterId,
  }) async {
    return await repository.updateFinding(
      id: id,
      title: title,
      categoryId: categoryId,
      description: description,
      clauseRef: clauseRef,
      department: department,
      reporter: reporter,
      reporterId: reporterId,
    );
  }
}