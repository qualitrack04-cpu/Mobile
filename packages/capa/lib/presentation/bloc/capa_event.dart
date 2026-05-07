import 'package:equatable/equatable.dart';

abstract class CapaEvent extends Equatable {
  const CapaEvent();

  @override
  List<Object?> get props => [];
}

// Load semua CAPA
class LoadCapas extends CapaEvent {
  const LoadCapas();
}

// Load detail CAPA
class LoadCapaDetail extends CapaEvent {
  final String id;

  const LoadCapaDetail({required this.id});

  @override
  List<Object?> get props => [id];
}

// Buat CAPA baru
class CreateCapaEvent extends CapaEvent {
  final String findingId;
  final String rootCause;
  final String correctiveAction;
  final String preventiveAction;
  final String picId;
  final DateTime deadline;

  const CreateCapaEvent({
    required this.findingId,
    required this.rootCause,
    required this.correctiveAction,
    required this.preventiveAction,
    required this.picId,
    required this.deadline,
  });

  @override
  List<Object?> get props => [
        findingId,
        rootCause,
        correctiveAction,
        preventiveAction,
        picId,
        deadline,
      ];
}

// Closeout CAPA
class CloseoutCapaEvent extends CapaEvent {
  final String id;
  final bool isEffective;
  final String verificationNotes;
  final String verifiedById;

  const CloseoutCapaEvent({
    required this.id,
    required this.isEffective,
    required this.verificationNotes,
    required this.verifiedById,
  });

  @override
  List<Object?> get props => [id, isEffective, verificationNotes, verifiedById];
}