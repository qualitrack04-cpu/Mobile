import 'package:audit/data/datasources/checklist_datasource.dart';
import 'package:audit/domain/entities/checklist_entity.dart';
import 'package:audit/domain/repositories/checklist_repository.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistDatasource datasource;

  ChecklistRepositoryImpl({required this.datasource});

  @override
  List<ChecklistEntity> getChecklistFor({
    required String isoTemplate,
    required String department,
  }) {
    try {
      return datasource.getChecklistFor(
        isoTemplate: isoTemplate,
        department: department,
      );
    } catch (e) {
      throw Exception('Gagal mengambil data checklist: $e');
    }
  }
}