import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audit/domain/usecases/get_audits.dart';
import 'package:audit/domain/usecases/create_audit.dart';
import 'package:audit/domain/usecases/update_audit.dart';
import 'package:audit/domain/usecases/mark_audit_finished.dart';
import 'package:audit/domain/usecases/get_checklist.dart';
import 'package:audit/domain/repositories/audit_repository.dart';
import 'audit_event.dart';
import 'audit_state.dart';

class AuditBloc extends Bloc<AuditEvent, AuditState> {
  final AuditRepository repository;
  final GetAudits getAudits;
  final CreateAudit createAudit;
  final UpdateAudit updateAudit;
  final MarkAuditFinished markAuditFinished;
  final GetChecklist getChecklist;

  AuditBloc({
    required this.repository,
    required this.getAudits,
    required this.createAudit,
    required this.updateAudit,
    required this.markAuditFinished,
    required this.getChecklist,
  }) : super(AuditInitial()) {
    on<LoadAudits>(_onLoadAudits);
    on<CreateAuditEvent>(_onCreateAudit);
    on<UpdateAuditEvent>(_onUpdateAudit);
    on<MarkAuditFinishedEvent>(_onMarkAuditFinished);
    on<DeleteAuditEvent>(_onDeleteAudit);
    on<LoadChecklist>(_onLoadChecklist);
  }

  Future<void> _onLoadAudits(
    LoadAudits event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final audits = await getAudits();
      emit(AuditLoaded(audits: audits));
    } catch (e) {
      emit(AuditError(message: e.toString()));
    }
  }

  Future<void> _onCreateAudit(
    CreateAuditEvent event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final audit = await createAudit(
        title: event.title,
        auditorName: event.auditorName,
        isoTemplates: event.isoTemplates,
        department: event.department,
        date: event.date,
        description: event.description,
        isPriority: event.isPriority,
      );
      emit(AuditCreated(audit: audit));

      // Reload list setelah create
      final audits = await getAudits();
      emit(AuditLoaded(audits: audits));
    } catch (e) {
      emit(AuditError(message: e.toString()));
    }
  }

  Future<void> _onUpdateAudit(
    UpdateAuditEvent event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final audit = await updateAudit(
        audit: event.audit,
        title: event.title,
        auditorName: event.auditorName,
        isoTemplates: event.isoTemplates,
        department: event.department,
        date: event.date,
        description: event.description,
        isPriority: event.isPriority,
      );
      emit(AuditUpdated(audit: audit));

      // Reload list setelah update
      final audits = await getAudits();
      emit(AuditLoaded(audits: audits));
    } catch (e) {
      emit(AuditError(message: e.toString()));
    }
  }

  Future<void> _onMarkAuditFinished(
    MarkAuditFinishedEvent event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final audit = await markAuditFinished(
        audit: event.audit,
        isFinished: event.isFinished,
      );
      emit(AuditMarkedFinished(audit: audit));

      // Reload list setelah status berubah
      final audits = await getAudits();
      emit(AuditLoaded(audits: audits));
    } catch (e) {
      emit(AuditError(message: e.toString()));
    }
  }

  Future<void> _onDeleteAudit(
    DeleteAuditEvent event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      await repository.deleteAudit(event.audit);
      emit(AuditDeleted());

      // Reload list setelah delete
      final audits = await getAudits();
      emit(AuditLoaded(audits: audits));
    } catch (e) {
      emit(AuditError(message: e.toString()));
    }
  }

  Future<void> _onLoadChecklist(
    LoadChecklist event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final checklists = await getChecklist(
        isoTemplate: event.isoTemplate,
        department: event.department,
      );
      emit(ChecklistLoaded(checklists: checklists));
    } catch (e) {
      emit(AuditError(message: e.toString()));
    }
  }
}