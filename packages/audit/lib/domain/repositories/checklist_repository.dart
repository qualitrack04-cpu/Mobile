import 'package:audit/domain/entities/checklist_entity.dart';

abstract class ChecklistRepository {
  /// Mengambil daftar checklist berdasarkan ISO template dan department.
  Future<List<ChecklistEntity>> getChecklistFor({
    required String isoTemplate,
    required String department,
  });

  /// Membuat sesi audit baru, mengembalikan sessionId.
  Future<String> createAuditSession({
    required String scheduleId,
    required String checklistId,
  });

  /// Menyimpan semua jawaban PASS/FAIL ke backend dan menyelesaikan sesi.
  Future<void> submitChecklistResponses({
    required String sessionId,
    required List<ChecklistEntity> checklists,
  });
}