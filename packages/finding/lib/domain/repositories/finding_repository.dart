import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';

abstract class FindingRepository {
  // Get semua finding (bisa filter by status/category)
  Future<List<Finding>> getFindings({
    FindingStatus? status,
    FindingCategory? category,
  });

  // Get detail 1 finding by id
  Future<Finding> getFindingDetail(String id);

  // Buat finding baru
  Future<Finding> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
  });

  // Update status finding
  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  });

  // Hapus finding
  Future<void> deleteFinding(String id);
}