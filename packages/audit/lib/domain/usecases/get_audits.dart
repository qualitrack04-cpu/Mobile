import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/domain/repositories/audit_repository.dart';

class GetAudits {
  final AuditRepository repository;

  GetAudits({required this.repository});

  Future<List<AuditEntity>> call() async {
    return await repository.getAudits();
  }
}