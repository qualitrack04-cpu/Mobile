import 'package:audit/domain/entities/checklist_entity.dart';
import 'package:audit/domain/repositories/checklist_repository.dart';

class GetChecklist {
  final ChecklistRepository repository;

  GetChecklist({required this.repository});

  List<ChecklistEntity> call({
    required String isoTemplate,
    required String department,
  }) {
    return repository.getChecklistFor(
      isoTemplate: isoTemplate,
      department: department,
    );
  }
}