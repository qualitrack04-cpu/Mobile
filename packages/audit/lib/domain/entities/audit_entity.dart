class AuditEntity {
  final String id;
  final String scheduleId;
  final String title;
  final String auditorName;
  final List<String> isoTemplates;
  final String department;
  final DateTime date;
  final String description;
  final bool isPriority;
  final bool isFinished;
  final DateTime? completedAt;

  const AuditEntity({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.auditorName,
    required this.isoTemplates,
    required this.department,
    required this.date,
    required this.description,
    required this.isPriority,
    required this.isFinished,
    this.completedAt,
  });

  AuditEntity copyWith({
    String? id,
    String? scheduleId,
    String? title,
    String? auditorName,
    List<String>? isoTemplates,
    String? department,
    DateTime? date,
    String? description,
    bool? isPriority,
    bool? isFinished,
    DateTime? completedAt,
  }) {
    return AuditEntity(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      auditorName: auditorName ?? this.auditorName,
      isoTemplates: isoTemplates ?? this.isoTemplates,
      department: department ?? this.department,
      date: date ?? this.date,
      description: description ?? this.description,
      isPriority: isPriority ?? this.isPriority,
      isFinished: isFinished ?? this.isFinished,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}