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
}