import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';

class FindingModel extends Finding {
  const FindingModel({
    required super.id,
    super.sessionId,
    required super.category,
    required super.description,
    required super.clauseRef,
    required super.foundAt,
    required super.status,
    required super.department,
    required super.reporter,
    required super.reporterId,
    super.isCapaClosed,
    super.capaClosedAt,
  });

  // JSON dari backend → FindingModel
  factory FindingModel.fromJson(Map<String, dynamic> json) {
    bool isCapaClosed = false;
    DateTime? capaClosedAt;

    if (json['capa'] != null) {
      final capaJson = json['capa'];
      final statusRaw = capaJson['status'];
      isCapaClosed = statusRaw == 3 || statusRaw == 'Closed';
      
      if (capaJson['closeOut'] != null && capaJson['closeOut']['verifiedAt'] != null) {
        capaClosedAt = DateTime.tryParse(capaJson['closeOut']['verifiedAt'].toString());
      } else if (capaJson['closedAt'] != null) {
        capaClosedAt = DateTime.tryParse(capaJson['closedAt'].toString());
      }
    } else {
      if (json['capaStatus'] != null) {
        final statusRaw = json['capaStatus'];
        isCapaClosed = statusRaw == 3 || statusRaw == 'Closed';
      }
      if (json['capaClosedAt'] != null) {
        capaClosedAt = DateTime.tryParse(json['capaClosedAt'].toString());
      }
    }

    return FindingModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String?,
      category: FindingCategory.fromString(json['category'] as String),
      description: json['description'] as String,
      clauseRef: json['clauseRef'] as String,
      foundAt: DateTime.parse(json['foundAt'] as String),
      status: FindingStatus.fromString(json['status'] as String),
      department: json['department'] as String,
      reporter: json['reporterName'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      isCapaClosed: isCapaClosed,
      capaClosedAt: capaClosedAt,
    );
  }

  // FindingModel → JSON untuk kirim ke backend
  Map<String, dynamic> toJson() {
    return {
      'category': category.toBackendString(),
      'description': description,
      'clauseRef': clauseRef,
      'department': department,
      'reporterName': reporter,
      'reporterId': reporterId,
    };
  }
}