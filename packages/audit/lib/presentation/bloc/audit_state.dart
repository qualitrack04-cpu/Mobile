import 'package:equatable/equatable.dart';
import 'package:audit/domain/entities/audit_entity.dart';
import 'package:audit/domain/entities/checklist_entity.dart';

abstract class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

// State awal
class AuditInitial extends AuditState {}

// State loading (untuk semua operasi async)
class AuditLoading extends AuditState {}

// State berhasil load daftar audit
class AuditLoaded extends AuditState {
  final List<AuditEntity> audits;

  const AuditLoaded({required this.audits});

  @override
  List<Object?> get props => [audits];
}

// State berhasil create audit
class AuditCreated extends AuditState {
  final AuditEntity audit;

  const AuditCreated({required this.audit});

  @override
  List<Object?> get props => [audit];
}

// State berhasil update audit
class AuditUpdated extends AuditState {
  final AuditEntity audit;

  const AuditUpdated({required this.audit});

  @override
  List<Object?> get props => [audit];
}

// State berhasil mark finished
class AuditMarkedFinished extends AuditState {
  final AuditEntity audit;

  const AuditMarkedFinished({required this.audit});

  @override
  List<Object?> get props => [audit];
}

// State berhasil hapus audit
class AuditDeleted extends AuditState {}

// State berhasil load checklist
class ChecklistLoaded extends AuditState {
  final List<ChecklistEntity> checklists;

  const ChecklistLoaded({required this.checklists});

  @override
  List<Object?> get props => [checklists];
}

// State error
class AuditError extends AuditState {
  final String message;

  const AuditError({required this.message});

  @override
  List<Object?> get props => [message];
}