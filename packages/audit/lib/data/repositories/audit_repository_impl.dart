import 'package:audit/data/datasources/audit_remote_datasource.dart';
import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/domain/repositories/audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  final AuditRemoteDatasource datasource; // ✅ Ganti dari AuditDatasource

  AuditRepositoryImpl({required this.datasource});

  @override
  Future<List<AuditEntity>> getAudits() async {
    try {
      return await datasource.getAudits();
    } catch (e) {
      rethrow; // pesan sudah bersih dari datasource, teruskan apa adanya
    }
  }

  @override
  Future<AuditEntity> createAudit({
    required String title,
    required String auditorName,
    required List<String> isoTemplates,
    required String department,
    required DateTime date,
    required String description,
    required bool isPriority,
    List<Map<String, dynamic>>? schedules, // ✅ Tambahan parameter
  }) async {
    try {
      return await datasource.createAudit(
        title: title,
        isoTemplates: isoTemplates,
        year: date.year,
        description: description,
        isPriority: isPriority,
        schedules: schedules ?? [
          {
            'clauseRef': isoTemplates.isNotEmpty ? isoTemplates.first : 'N/A',
            'auditorName': auditorName,
            'scheduledDate':
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'department': department,
          },
        ],
      );
    } catch (e) {
      rethrow; // pesan sudah bersih dari datasource, teruskan apa adanya
    }
  }

  @override
  Future<AuditEntity> updateAudit({
    required AuditEntity audit,
    required String title,
    required String auditorName,
    required List<String> isoTemplates,
    required String department,
    required DateTime date,
    required String description,
    required bool isPriority,
  }) async {
    try {
      return await datasource.updateAudit(
        id: audit.id,
        title: title,
        isoTemplates: isoTemplates,
        year: date.year,
        description: description,
        isPriority: isPriority,
        schedules: [
          {
            'clauseRef': isoTemplates.isNotEmpty ? isoTemplates.first : 'N/A',
            'auditorName': auditorName,
            'scheduledDate':
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'department': department,
          },
        ],
      );
    } catch (e) {
      rethrow; // pesan sudah bersih dari datasource, teruskan apa adanya
    }
  }

  @override
  Future<AuditEntity> markAuditFinished({
    required AuditEntity audit,
    required bool isFinished,
  }) async {
    // ⚠️ Backend belum punya endpoint mark-finished di AuditPlan.
    // Untuk sementara, return updated entity secara lokal.
    // TODO: Hubungkan ke AuditSession endpoint ketika sudah tersedia.
    return audit.copyWith(isFinished: isFinished);
  }

  @override
  Future<void> deleteAudit(AuditEntity audit) async {
    try {
      await datasource.deleteAudit(audit.id);
    } catch (e) {
      rethrow; // pesan sudah bersih dari datasource, teruskan apa adanya
    }
  }
}
