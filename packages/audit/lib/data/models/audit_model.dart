import 'package:audit/domain/entities/audit_entity.dart';

class AuditModel extends AuditEntity {
  const AuditModel({
    required super.id,
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
    // ✅ FIX: Backend enum Priority adalah "Common" atau "Priority"
    final priorityStr = (json['priority'] as String? ?? 'Common');
    final isPriority = priorityStr == 'Priority';

    // ✅ FIX: Backend simpan "ISO9001" bukan "ISO 9001:2015"
    final standard = json['standard'] as String? ?? '';
    final isoTemplates = standard.isNotEmpty ? [standard] : <String>[];

    // ✅ FIX: department & auditorName diambil dari schedules[0]
    final schedules = json['schedules'] as List<dynamic>? ?? [];
    final firstSchedule = schedules.isNotEmpty
        ? schedules[0] as Map<String, dynamic>
        : <String, dynamic>{};

    final department =
        firstSchedule['department'] as String? ??
        json['department'] as String? ??
        '';

    // auditorName berasal dari relasi AuditSchedule → User
    // Backend perlu di-include saat query (lihat Step 6 catatan backend)
    final auditorName =
        firstSchedule['auditorName'] as String? ??
        firstSchedule['auditor']?['fullName'] as String? ??
        '';

    // ✅ isFinished: tidak ada di AuditPlan backend
    // Gunakan false sebagai default (bisa dikembangkan dari AuditSession nanti)
    final isFinished = json['isFinished'] as bool? ?? false;

    return AuditModel(
      id: json['id'] as String, // ✅ String (Guid)
      title: json['title'] as String? ?? '',
      auditorName: auditorName,
      isoTemplates: isoTemplates,
      department: department,
      date: json['year'] != null
          ? DateTime(json['year'] as int)
          : DateTime.tryParse(json['scheduledDate'] as String? ?? '') ??
                DateTime.now(),
      description: json['description'] as String? ?? '',
      isPriority: isPriority,
      isFinished: isFinished,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'standard': isoTemplates.isNotEmpty
          ? isoTemplates.first
          : '', // langsung, tanpa konversi
      'year': date.year,
      'description': description,
      'priority': isPriority ? 'Priority' : 'Common',
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
