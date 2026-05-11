import 'package:finding/data/datasources/finding_mock_datasource.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/domain/repositories/finding_repository.dart';

class FindingRepositoryImpl implements FindingRepository {
  final FindingMockDatasource datasource;

  FindingRepositoryImpl({required this.datasource});

  @override
  Future<List<Finding>> getFindings({
    FindingStatus? status,
    FindingCategory? category,
  }) async {
    try {
      return await datasource.getFindings(status: status, category: category);
    } catch (e) {
      throw Exception('Gagal mengambil data finding: $e');
    }
  }

  @override
  Future<Finding> getFindingDetail(String id) async {
    try {
      return await datasource.getFindingDetail(id);
    } catch (e) {
      throw Exception('Gagal mengambil detail finding: $e');
    }
  }

  @override
  Future<Finding> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
  }) async {
    try {
      return await datasource.createFinding(
        category: category,
        description: description,
        clauseRef: clauseRef,
      );
    } catch (e) {
      throw Exception('Gagal membuat finding: $e');
    }
  }

  // ✅ BARU
  @override
  Future<Finding> updateFinding({
    required String id,
    required FindingCategory category,
    required String description,
    required String clauseRef,
  }) async {
    try {
      return await datasource.updateFinding(
        id: id,
        category: category,
        description: description,
        clauseRef: clauseRef,
      );
    } catch (e) {
      throw Exception('Gagal mengupdate finding: $e');
    }
  }

  @override
  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  }) async {
    try {
      await datasource.updateFindingStatus(id: id, status: status);
    } catch (e) {
      throw Exception('Gagal update status finding: $e');
    }
  }

  @override
  Future<void> deleteFinding(String id) async {
    try {
      await datasource.deleteFinding(id);
    } catch (e) {
      throw Exception('Gagal menghapus finding: $e');
    }
  }
}
