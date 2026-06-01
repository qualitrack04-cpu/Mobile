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
    super.closedAt, // ← tambah ini
  });

  factory CapaModel.fromJson(Map<String, dynamic> json) {
    const statusIntMap = {
      0: 'Open',
      1: 'In Progress',
      2: 'Pending Verification',
      3: 'Closed'
    };
    const statusStrMap = {
      'Open': 'Open',
      'InProgress': 'In Progress',
      'PendingVerification': 'Pending Verification',
      'Closed': 'Closed',
    };

    final statusRaw = json['status'];
    final statusStr = statusRaw is int
        ? (statusIntMap[statusRaw] ?? 'Open')
        : statusStrMap[statusRaw as String? ?? ''] ?? 'Open';

    String findingTitle = json['findingTitle'] as String? ?? '';
    String findingCategory = json['findingCategory'] as String? ?? '';

    if (json['finding'] != null && findingTitle.isEmpty) {
      final clause = json['finding']['clauseRef'] as String? ?? '';
      final desc = json['finding']['description'] as String? ?? '';
      findingTitle = clause.isNotEmpty ? '$clause - $desc' : desc;
    }

    if (json['finding'] != null && findingCategory.isEmpty) {
      final categoryRaw = json['finding']['category'];
      if (categoryRaw is int) {
        const categoryMap = {
          0: 'MajorNC',
          1: 'MinorNC',
          2: 'Observation',
          3: 'OFI'
        };
        findingCategory = categoryMap[categoryRaw] ?? '';
      } else if (categoryRaw is String) {
        findingCategory = categoryRaw;
      }
    }

    String picName = json['picName'] as String? ?? '';
    if (picName.isEmpty && json['pic'] != null) {
      picName = json['pic']['fullName'] as String? ?? '';
    }

    // Parse closedAt dari closeOut.verifiedAt
    DateTime? closedAt;
    if (json['closeOut'] != null) {
      final verifiedAt = json['closeOut']['verifiedAt'] as String?;
      if (verifiedAt != null) {
        closedAt = DateTime.parse(verifiedAt);
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
      picName: picName,
      findingTitle: findingTitle,
      deadline: DateTime.parse(json['deadline'] as String),
      isClosed: statusStr == 'Closed',
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: statusStr,
      closedAt: closedAt, // ← tambah ini
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