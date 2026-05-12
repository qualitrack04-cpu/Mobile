import 'package:audit/domain/entities/checklist_entity.dart';
import 'package:audit/domain/repositories/checklist_repository.dart';

class GetChecklist {
  final ChecklistRepository repository;

  GetChecklist({required this.repository});

  Future<List<ChecklistEntity>> call({
    required String isoTemplate,
    required String department,
  }) async {
    return await repository.getChecklistFor(
      isoTemplate: isoTemplate,
      department: department,
    );
  }
}