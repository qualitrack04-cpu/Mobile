import 'package:equatable/equatable.dart';

class Capa extends Equatable {
  final String id;
  final String findingId;
  final String findingCategory;
  final String rootCause;
  final String correctiveAction;
  final String preventiveAction;
  final String picId;
  final DateTime deadline;
  final bool isClosed;
  final DateTime createdAt;
  final String status;

  const Capa({
    required this.id,
    required this.findingId,
    required this.findingCategory,
    required this.rootCause,
    required this.correctiveAction,
    required this.preventiveAction,
    required this.picId,
    required this.deadline,
    required this.isClosed,
    required this.createdAt,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        findingId,
        findingCategory,
        rootCause,
        correctiveAction,
        preventiveAction,
        picId,
        deadline,
        isClosed,
        createdAt,
        status,
      ];
}