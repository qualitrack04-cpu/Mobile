import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';

abstract class FindingRepository {
  Future<List<Finding>> getFindings({FindingStatus? status});

  Future<Finding> getFindingDetail(String id);

  Future<Finding> createFinding({
    required String title,
    required String categoryId,
    required String description,
    String? clauseRef,
    required String department,
    required String reporter,
    String? reporterId,
    String? sessionId,
    String? checklistItemId,
  });

  Future<Finding> updateFinding({
    required String id,
    required String title,
    required String categoryId,
    required String description,
    String? clauseRef,
    required String department,
    required String reporter,
    String? reporterId,
  });

  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  });

  Future<void> deleteFinding(String id);

  Future<void> uploadEvidence(String findingId, String filePath);
}