import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/domain/repositories/audit_repository.dart';

class UpdateAudit {
  final AuditRepository repository;

  UpdateAudit({required this.repository});

  Future<AuditEntity> call({
    required AuditEntity audit,
    required String title,
    required String auditorName,
    required List<String> isoTemplates,
    required String department,
    required DateTime date,
    required String description,
    required bool isPriority,
  }) async {
    return await repository.updateAudit(
      audit: audit,
      title: title,
      auditorName: auditorName,
      isoTemplates: isoTemplates,
      department: department,
      date: date,
      description: description,
      isPriority: isPriority,
    );
  }
}