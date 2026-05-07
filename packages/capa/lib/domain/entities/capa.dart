import 'package:equatable/equatable.dart';

class Capa extends Equatable {
  final String id;
  final String findingId;
  final String rootCause;
  final String correctiveAction;
  final String preventiveAction;
  final String picId;
  final DateTime deadline;
  final bool isClosed;
  final DateTime createdAt;

  const Capa({
    required this.id,
    required this.findingId,
    required this.rootCause,
    required this.correctiveAction,
    required this.preventiveAction,
    required this.picId,
    required this.deadline,
    required this.isClosed,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        findingId,
        rootCause,
        correctiveAction,
        preventiveAction,
        picId,
        deadline,
        isClosed,
        createdAt,
      ];
}