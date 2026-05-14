import 'package:finding/data/datasources/finding_mock_datasource.dart';
import 'package:finding/data/datasources/finding_remote_datasource.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/domain/repositories/finding_repository.dart';

class FindingRepositoryImpl implements FindingRepository {
  final FindingMockDatasource? mockDatasource;
  final FindingRemoteDatasource? remoteDatasource;

  FindingRepositoryImpl({
    this.mockDatasource,
    this.remoteDatasource,
  });

  bool get _useRemote => remoteDatasource != null;

  @override
  Future<List<Finding>> getFindings({
    FindingStatus? status,
    FindingCategory? category,
  }) async {
    try {
      if (_useRemote) {
        return await remoteDatasource!.getFindings(
          status: status,
          category: category,
        );
      }
      return await mockDatasource!.getFindings(
        status: status,
        category: category,
      );
    } catch (e) {
      throw Exception('Gagal mengambil data finding: $e');
    }
  }

  @override
  Future<Finding> getFindingDetail(String id) async {
    try {
      if (_useRemote) {
        return await remoteDatasource!.getFindingDetail(id);
      }
      return await mockDatasource!.getFindingDetail(id);
    } catch (e) {
      throw Exception('Gagal mengambil detail finding: $e');
    }
  }

  @override
  Future<Finding> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
  }) async {
    try {
      if (_useRemote) {
        return await remoteDatasource!.createFinding(
          category: category,
          description: description,
          clauseRef: clauseRef,
          department: department,
        );
      }
      return await mockDatasource!.createFinding(
        category: category,
        description: description,
        clauseRef: clauseRef,
        department: department,
      );
    } catch (e) {
      throw Exception('Gagal membuat finding: $e');
    }
  }

  @override
  Future<Finding> updateFinding({
    required String id,
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
  }) async {
    try {
      if (_useRemote) {
        return await remoteDatasource!.updateFinding(
          id: id,
          category: category,
          description: description,
          clauseRef: clauseRef,
          department: department,
        );
      }
      return await mockDatasource!.updateFinding(
        id: id,
        category: category,
        description: description,
        clauseRef: clauseRef,
        department: department,
      );
    } catch (e) {
      throw Exception('Gagal update finding: $e');
    }
  }

  @override
  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  }) async {
    try {
      if (_useRemote) {
        await remoteDatasource!.updateFindingStatus(
          id: id,
          status: status,
        );
        return;
      }
      await mockDatasource!.updateFindingStatus(
        id: id,
        status: status,
      );
    } catch (e) {
      throw Exception('Gagal update status finding: $e');
    }
  }

  @override
  Future<void> deleteFinding(String id) async {
    try {
      if (_useRemote) {
        await remoteDatasource!.deleteFinding(id);
        return;
      }
      await mockDatasource!.deleteFinding(id);
    } catch (e) {
      throw Exception('Gagal menghapus finding: $e');
    }
  }
}