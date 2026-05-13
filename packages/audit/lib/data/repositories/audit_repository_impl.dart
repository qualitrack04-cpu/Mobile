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
      throw Exception('Gagal mengambil data audit: $e');
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
        schedules:
            schedules ??
            [
              // Minimal 1 schedule — ambil dari form
              // Ini adalah contoh default, idealnya dari input user
              {
                'clauseRef': isoTemplates.isNotEmpty
                    ? isoTemplates.first
                    : 'N/A',
                'auditorId': null, // belum ada fitur auditor
                'auditorName': auditorName, // ← ini yang kurang
                'scheduledDate':
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-01',
                'department': department,
              },
            ],
      );
    } catch (e) {
      throw Exception('Gagal membuat audit: $e');
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
            'auditorId': null, // belum ada fitur auditor
            'auditorName': auditorName, // ← ini yang kurang
            'scheduledDate':
                '${date.year}-${date.month.toString().padLeft(2, '0')}-01',
            'department': department,
          },
        ],
      );
    } catch (e) {
      throw Exception('Gagal mengupdate audit: $e');
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
      throw Exception('Gagal menghapus audit: $e');
    }
  }
}
