class AuditEntity {
  final int? id; // ID dari backend (null untuk data lokal)
  final String title;
  final String auditorName;
  final List<String> isoTemplates;
  final String department;
  final DateTime date;
  final String description;
  final bool isPriority;
  final bool isFinished;

  const AuditEntity({
    this.id,
    required this.title,
    required this.auditorName,
    required this.isoTemplates,
    required this.department,
    required this.date,
    required this.description,
    required this.isPriority,
    required this.isFinished,
  });

  AuditEntity copyWith({
    int? id,
    String? title,
    String? auditorName,
    List<String>? isoTemplates,
    String? department,
    DateTime? date,
    String? description,
    bool? isPriority,
    bool? isFinished,
  }) {
    return AuditEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      auditorName: auditorName ?? this.auditorName,
      isoTemplates: isoTemplates ?? this.isoTemplates,
      department: department ?? this.department,
      date: date ?? this.date,
      description: description ?? this.description,
      isPriority: isPriority ?? this.isPriority,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}