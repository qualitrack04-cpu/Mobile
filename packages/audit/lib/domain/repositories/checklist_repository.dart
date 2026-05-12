import 'package:audit/domain/entities/checklist_entity.dart';

abstract class ChecklistRepository {
  /// Mengambil daftar checklist berdasarkan ISO template dan department.
  Future<List<ChecklistEntity>> getChecklistFor({
    required String isoTemplate,
    required String department,
  });
}