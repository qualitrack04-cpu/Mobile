import 'package:audit/data/datasources/audit_datasource.dart';
import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/domain/repositories/audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  final AuditDatasource datasource;

  // Menyimpan data audit sementara di memory (karena masih pakai mock datasource)
  List<AuditEntity> _cachedAudits = [];

  AuditRepositoryImpl({required this.datasource});

  @override
  Future<List<AuditEntity>> getAudits() async {
    try {
      _cachedAudits = await datasource.getAudits();
      return _cachedAudits;
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
  }) async {
    try {
      final newAudit = AuditEntity(
        title: title,
        auditorName: auditorName,
        isoTemplates: isoTemplates,
        department: department,
        date: date,
        description: description,
        isPriority: isPriority,
        isFinished: false,
      );

      // Tambahkan ke cache lokal (nanti diganti dengan call ke backend)
      _cachedAudits = [..._cachedAudits, newAudit];

      return newAudit;
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
      final updated = audit.copyWith(
        title: title,
        auditorName: auditorName,
        isoTemplates: isoTemplates,
        department: department,
        date: date,
        description: description,
        isPriority: isPriority,
      );

      // Update di cache lokal (nanti diganti dengan call ke backend)
      _cachedAudits = _cachedAudits
          .map((a) => a == audit ? updated : a)
          .toList();

      return updated;
    } catch (e) {
      throw Exception('Gagal mengupdate audit: $e');
    }
  }

  @override
  Future<AuditEntity> markAuditFinished({
    required AuditEntity audit,
    required bool isFinished,
  }) async {
    try {
      final updated = audit.copyWith(isFinished: isFinished);

      _cachedAudits = _cachedAudits
          .map((a) => a == audit ? updated : a)
          .toList();

      return updated;
    } catch (e) {
      throw Exception('Gagal mengupdate status audit: $e');
    }
  }

  @override
  Future<void> deleteAudit(AuditEntity audit) async {
    try {
      _cachedAudits = _cachedAudits
          .where((a) => a != audit)
          .toList();
    } catch (e) {
      throw Exception('Gagal menghapus audit: $e');
    }
  }
}