import 'package:audit/domain/entities/audit_entity.dart';

abstract class AuditRepository {
  /// Mengambil semua daftar audit.
  Future<List<AuditEntity>> getAudits();

  /// Membuat audit baru, mengembalikan entity yang sudah dibuat.
  Future<AuditEntity> createAudit({
    required String title,
    required String auditorName,
    required List<String> isoTemplates,
    required String department,
    required DateTime date,
    required String description,
    required bool isPriority,
  });

  /// Mengupdate data audit yang sudah ada.
  Future<AuditEntity> updateAudit({
    required AuditEntity audit,
    required String title,
    required String auditorName,
    required List<String> isoTemplates,
    required String department,
    required DateTime date,
    required String description,
    required bool isPriority,
  });

  /// Menandai audit sebagai selesai / tidak selesai.
  Future<AuditEntity> markAuditFinished({
    required AuditEntity audit,
    required bool isFinished,
  });

  /// Menghapus audit.
  Future<void> deleteAudit(AuditEntity audit);
}