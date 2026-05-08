import '../../domain/entities/audit_entity.dart';

class AuditDatasource {
  Future<List<AuditEntity>> getAudits() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      AuditEntity(
        title: 'Inventory Logic Audit',
        auditorName: 'S. Mitchell',
        isoTemplates: [
          'ISO 90001 Compliance',
        ],
        department: 'Production',
        date: DateTime(2026, 4, 26),
        description:
            'Detail the non-conformance observed during the audit.',
        isPriority: true,
        isFinished: false,
      ),

      AuditEntity(
        title: 'Warehouse Audit',
        auditorName: 'John Doe',
        isoTemplates: [
          'ISO 90002 Compliance',
        ],
        department: 'Warehouse',
        date: DateTime(2026, 5, 12),
        description:
            'Warehouse operational audit and stock validation.',
        isPriority: false,
        isFinished: false,
      ),

      AuditEntity(
        title: 'Safety Procedure Audit',
        auditorName: 'Amir Oakwood',
        isoTemplates: [
          'ISO 90001 Compliance',
          'ISO 90002 Compliance',
        ],
        department: 'Production',
        date: DateTime(2026, 6, 8),
        description:
            'Safety protocol inspection for production division.',
        isPriority: true,
        isFinished: true,
      ),
    ];
  }
}