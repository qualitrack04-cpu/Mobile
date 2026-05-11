import 'package:audit/domain/entities/audit_entity.dart';

class AuditModel extends AuditEntity {
  const AuditModel({
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
    return AuditModel(
      title: json['title'] as String,
      auditorName: json['auditorName'] as String,
      isoTemplates: List<String>.from(json['isoTemplates'] as List),
      department: json['department'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      isPriority: json['isPriority'] as bool? ?? false,
      isFinished: json['isFinished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'auditorName': auditorName,
      'isoTemplates': isoTemplates,
      'department': department,
      'date': date.toIso8601String(),
      'description': description,
      'isPriority': isPriority,
      'isFinished': isFinished,
    };
  }

  factory AuditModel.fromEntity(AuditEntity entity) {
    return AuditModel(
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