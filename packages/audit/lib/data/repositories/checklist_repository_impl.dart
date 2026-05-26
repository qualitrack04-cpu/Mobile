import 'package:audit/data/datasources/checklist_remote_datasource.dart'; // ✅ Ganti
import 'package:audit/domain/entities/checklist_entity.dart';
import 'package:audit/domain/repositories/checklist_repository.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistRemoteDatasource datasource; // ✅ Ganti

  ChecklistRepositoryImpl({required this.datasource});

  @override
  Future<List<ChecklistEntity>> getChecklistFor({
    required String isoTemplate,
    required String department,
  }) async {
    try {
      return await datasource.getChecklistFor(
        isoTemplate: isoTemplate,
        department: department,
      );
    } catch (e) {
      throw Exception('Gagal mengambil data checklist: $e');
    }
  }

  @override
  Future<String> createAuditSession({
    required String scheduleId,
    required String checklistId,
  }) async {
    try {
      return await datasource.createAuditSession(
        scheduleId: scheduleId,
        checklistId: checklistId,
      );
    } catch (e) {
      throw Exception('Gagal membuat sesi audit: $e');
    }
  }

  @override
  Future<void> submitChecklistResponses({
    required String sessionId,
    required List<ChecklistEntity> checklists,
  }) async {
    try {
      await datasource.submitChecklistResponses(
        sessionId: sessionId,
        checklists: checklists,
      );
    } catch (e) {
      throw Exception('Gagal menyimpan hasil checklist: $e');
    }
  }
}