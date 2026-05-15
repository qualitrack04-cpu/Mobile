import 'package:capa/domain/entities/capa.dart';

class CapaModel extends Capa {
  const CapaModel({
    required super.id,
    required super.findingId,
    required super.findingCategory,
    required super.rootCause,
    required super.correctiveAction,
    required super.preventiveAction,
    required super.picId,
    required super.picName,
    required super.findingTitle,
    required super.deadline,
    required super.isClosed,
    required super.createdAt,
    required super.status,
  });

  factory CapaModel.fromJson(Map<String, dynamic> json) {
    // Backend kirim status sebagai int (0=Open, 1=InProgress, 2=Closed)
    // atau sebagai string enum ("Open", "InProgress", "PendingVerification", "Closed")
    const statusIntMap = {0: 'Open', 1: 'In Progress', 2: 'Pending Verification', 3: 'Closed'};
    const statusStrMap = {
      'Open': 'Open',
      'InProgress': 'In Progress',
      'PendingVerification': 'Pending Verification',
      'Closed': 'Closed',
    };
    final statusRaw = json['status'];
    final statusStr =
        statusRaw is int
            ? (statusIntMap[statusRaw] ?? 'Open')
            : statusStrMap[statusRaw as String? ?? ''] ?? 'Open';

    String findingTitle = '';
    String findingCategory = '';
    if (json['finding'] != null) {
      final clause = json['finding']['clauseRef'] as String? ?? '';
      final desc = json['finding']['description'] as String? ?? '';
      findingTitle = clause.isNotEmpty ? '$clause - $desc' : desc;
      
      final categoryRaw = json['finding']['category'];
      if (categoryRaw is int) {
        const categoryMap = {0: 'MajorNC', 1: 'MinorNC', 2: 'Observation', 3: 'OFI'};
        findingCategory = categoryMap[categoryRaw] ?? '';
      } else if (categoryRaw is String) {
        findingCategory = categoryRaw;
      }
    }

    return CapaModel(
      id: json['id'] as String,
      findingId: json['findingId'] as String,
      findingCategory: findingCategory,
      rootCause: json['rootCause'] as String? ?? '',
      correctiveAction: json['correctiveAction'] as String? ?? '',
      preventiveAction: json['preventiveAction'] as String? ?? '',
      picId: json['picId'] as String? ?? '',
      picName: (json['pic'] != null) ? (json['pic']['fullName'] as String? ?? '') : '',
      findingTitle: findingTitle,
      deadline: DateTime.parse(json['deadline'] as String),
      isClosed: statusStr == 'Closed',
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: statusStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'findingId': findingId,
      'rootCause': rootCause,
      'correctiveAction': correctiveAction,
      'preventiveAction': preventiveAction,
      'picId': picId,
      'deadline': deadline.toIso8601String(),
    };
  }
}