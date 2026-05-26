import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/domain/repositories/audit_repository.dart';

class MarkAuditFinished {
  final AuditRepository repository;

  MarkAuditFinished({required this.repository});

  Future<AuditEntity> call({
    required AuditEntity audit,
    required bool isFinished,
  }) async {
    return await repository.markAuditFinished(
      audit: audit,
      isFinished: isFinished,
    );
  }
}