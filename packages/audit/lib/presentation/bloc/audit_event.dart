import 'package:equatable/equatable.dart';
import 'package:audit/domain/entities/audit_entity.dart';

abstract class AuditEvent extends Equatable {
  const AuditEvent();

  @override
  List<Object?> get props => [];
}

// Muat semua audit
class LoadAudits extends AuditEvent {
  const LoadAudits();
}

// Buat audit baru
class CreateAuditEvent extends AuditEvent {
  final String title;
  final String auditorName;
  final List<String> isoTemplates;
  final String department;
  final DateTime date;
  final String description;
  final bool isPriority;

  const CreateAuditEvent({
    required this.title,
    required this.auditorName,
    required this.isoTemplates,
    required this.department,
    required this.date,
    required this.description,
    required this.isPriority,
  });

  @override
  List<Object?> get props => [
        title,
        auditorName,
        isoTemplates,
        department,
        date,
        description,
        isPriority,
      ];
}

// Edit audit yang sudah ada
class UpdateAuditEvent extends AuditEvent {
  final AuditEntity audit;
  final String title;
  final String auditorName;
  final List<String> isoTemplates;
  final String department;
  final DateTime date;
  final String description;
  final bool isPriority;

  const UpdateAuditEvent({
    required this.audit,
    required this.title,
    required this.auditorName,
    required this.isoTemplates,
    required this.department,
    required this.date,
    required this.description,
    required this.isPriority,
  });

  @override
  List<Object?> get props => [
        audit,
        title,
        auditorName,
        isoTemplates,
        department,
        date,
        description,
        isPriority,
      ];
}

// Tandai audit selesai / belum selesai
class MarkAuditFinishedEvent extends AuditEvent {
  final AuditEntity audit;
  final bool isFinished;

  const MarkAuditFinishedEvent({
    required this.audit,
    required this.isFinished,
  });

  @override
  List<Object?> get props => [audit, isFinished];
}

// Hapus audit
class DeleteAuditEvent extends AuditEvent {
  final AuditEntity audit;

  const DeleteAuditEvent({required this.audit});

  @override
  List<Object?> get props => [audit];
}

// Muat checklist berdasarkan ISO template & department
class LoadChecklist extends AuditEvent {
  final String isoTemplate;
  final String department;

  const LoadChecklist({
    required this.isoTemplate,
    required this.department,
  });

  @override
  List<Object?> get props => [isoTemplate, department];
}

// Muat daftar auditor dari backend untuk dropdown
class LoadAuditors extends AuditEvent {
  const LoadAuditors();
}