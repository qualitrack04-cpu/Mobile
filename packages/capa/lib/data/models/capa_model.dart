import 'package:capa/domain/entities/capa.dart';
import 'package:core/core.dart';

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
    final statusStr = _parseStatus(json['statusName'] ?? json['status']);

    String findingTitle = json['findingTitle'] as String? ?? '';
    String findingCategory = json['findingCategory'] as String? ?? '';

    if (json['finding'] != null && findingTitle.isEmpty) {
      final title = json['finding']['title'] as String? ?? '';
      final desc = json['finding']['description'] as String? ?? '';
      findingTitle = title.isNotEmpty ? title : desc;
    }

    if (json['finding'] != null && findingCategory.isEmpty) {
      final categoryRaw = json['finding']['category'];
      if (categoryRaw is int) {
        const categoryMap = {
          0: 'MajorNC',
          1: 'MinorNC',
          2: 'Observation',
          3: 'OFI',
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

    // Parse closedAt dari closeOut.verifiedAt atau langsung dari closedAt
    DateTime? closedAt;
    if (json['closedAt'] != null) {
      var dateStr = json['closedAt'].toString();
      if (!dateStr.endsWith('Z')) dateStr += 'Z';
      closedAt = DateTime.tryParse(dateStr);
    } else if (json['closeOut'] != null) {
      final verifiedAt = json['closeOut']['verifiedAt'] as String?;
      if (verifiedAt != null) {
        var dateStr = verifiedAt;
        if (!dateStr.endsWith('Z')) dateStr += 'Z';
        closedAt = DateTime.tryParse(dateStr);
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
      isClosed: CapaStatusStyle.isTerminal(statusStr),
      createdAt: AppClock.parseUtc(json['createdAt'] as String),
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

  static String _parseStatus(dynamic raw) {
    const legacy = {
      0: 'Open',
      1: 'In Progress',
      2: 'Pending Verification',
      3: 'Closed',
    };
    if (raw is int) return legacy[raw] ?? 'Open';
    if (raw is Map) return _parseStatus(raw['name']);
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return 'Open';
    return CapaStatusStyle.canonical(text);
  }
}
