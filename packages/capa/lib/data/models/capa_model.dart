import 'package:capa/domain/entities/capa.dart';

class CapaModel extends Capa {
  const CapaModel({
    required super.id,
    required super.findingId,
    required super.rootCause,
    required super.correctiveAction,
    required super.preventiveAction,
    required super.picId,
    required super.deadline,
    required super.isClosed,
    required super.createdAt,
    required super.status,
  });

  factory CapaModel.fromJson(Map<String, dynamic> json) {
    return CapaModel(
      id: json['id'] as String,
      findingId: json['findingId'] as String,
      rootCause: json['rootCause'] as String,
      correctiveAction: json['correctiveAction'] as String,
      preventiveAction: json['preventiveAction'] as String,
      picId: json['picId'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      isClosed: json['isClosed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String,
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