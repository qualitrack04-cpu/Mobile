import 'package:audit/domain/entities/audit_entity.dart';

class AuditModel extends AuditEntity {
  const AuditModel({
    super.id,
    required super.title,
    required super.auditorName,
    required super.isoTemplates,
    required super.department,
    required super.date,
    required super.description,
    required super.isPriority,
    required super.isFinished,
  });

  factory AuditModel.fromJson(Map<String, dynamic> json) {
    // Backend mengirim priority sebagai string: "Low","Medium","High","Critical"
    // isPriority = true kalau High atau Critical
    final priorityStr = (json['priority'] as String? ?? 'Medium');
    final isPriority =
        priorityStr == 'High' || priorityStr == 'Critical';

    // isoTemplates: backend simpan di field "standard" (string tunggal)
    final standard = json['standard'] as String? ?? '';
    final isoTemplates = standard.isNotEmpty ? [standard] : <String>[];

    // department: bisa dari field "department" langsung atau dari schedules
    final department = json['department'] as String? ?? '';

    return AuditModel(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      auditorName: json['auditorName'] as String? ?? '',
      isoTemplates: isoTemplates,
      department: department,
      date: json['year'] != null
          ? DateTime(json['year'] as int)
          : DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      description: json['description'] as String? ?? '',
      isPriority: isPriority,
      isFinished: json['isFinished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'standard': isoTemplates.isNotEmpty ? isoTemplates.first : '',
      'department': department,
      'year': date.year,
      'description': description,
      'priority': isPriority ? 'High' : 'Medium',
      'schedules': [],
    };
  }

  factory AuditModel.fromEntity(AuditEntity entity) {
    return AuditModel(
      id: entity.id,
      title: entity.title,
      auditorName: entity.auditorName,
      isoTemplates: entity.isoTemplates,
      department: entity.department,
      date: entity.date,
      description: entity.description,
      isPriority: entity.isPriority,
      isFinished: entity.isFinished,
    );
  }
}