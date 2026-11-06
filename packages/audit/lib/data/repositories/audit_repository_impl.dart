import 'package:audit/data/datasources/audit_remote_datasource.dart';
import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/domain/repositories/audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  final AuditRemoteDatasource datasource; // ✅ Ganti dari AuditDatasource

  AuditRepositoryImpl({required this.datasource});

  /// Backend menerima ISO-8601 UTC, misal 2026-11-15T00:00:00.000Z.
  String _formatDate(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).toIso8601String();

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
    required String auditorId,
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
            // Jadwal baru: JANGAN kirim id
            'clauseRef': isoTemplates.isNotEmpty ? isoTemplates.first : 'N/A',
            'auditorId': auditorId,
            'scheduledDate': _formatDate(date),
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
    required String auditorId,
    required String auditorName,
    required List<String> isoTemplates,
    required String department,
    required DateTime date,
    required String description,
    required bool isPriority,
  }) async {
    try {
      // scheduleId jatuh ke id plan bila plan belum punya jadwal (lihat
      // AuditModel.fromJson). Id plan tidak boleh dikirim sebagai id jadwal.
      final hasRealSchedule =
          audit.scheduleId.isNotEmpty && audit.scheduleId != audit.id;

      return await datasource.updateAudit(
        id: audit.id,
        title: title,
        isoTemplates: isoTemplates,
        year: date.year,
        description: description,
        isPriority: isPriority,
        schedules: [
          {
            if (hasRealSchedule) 'id': audit.scheduleId, // update in-place
            'clauseRef': isoTemplates.isNotEmpty ? isoTemplates.first : 'N/A',
            'auditorId': auditorId,
            'scheduledDate': _formatDate(date),
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