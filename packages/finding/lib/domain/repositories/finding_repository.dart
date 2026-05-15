import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';

abstract class FindingRepository {
  Future<List<Finding>> getFindings({
    FindingStatus? status,
    FindingCategory? category,
  });

  Future<Finding> getFindingDetail(String id);

  Future<Finding> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
    String? auditorName,
    String? sessionId,          // ✅ TAMBAH
    String? checklistItemId,    // ✅ TAMBAH
  });

  Future<Finding> updateFinding({
    required String id,
    required FindingCategory category,
    required String description,
    required String clauseRef,
    required String department,
  });

  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  });

  Future<void> deleteFinding(String id);

  Future<void> uploadEvidence(String findingId, String filePath);
}