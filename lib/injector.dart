
import 'package:get_it/get_it.dart';
import 'package:core_services/services/api_service.dart';
import 'package:core_services/services/auth_service.dart';

// Finding
import 'package:finding/data/datasources/finding_remote_datasource.dart';
import 'package:finding/data/repositories/finding_repository_impl.dart';
import 'package:finding/domain/repositories/finding_repository.dart';
import 'package:finding/domain/usecases/create_finding.dart';
import 'package:finding/domain/usecases/update_finding.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';

// CAPA
import 'package:capa/data/datasources/capa_remote_datasource.dart';
import 'package:capa/data/repositories/capa_repository_impl.dart';
import 'package:capa/domain/repositories/capa_repository.dart';
import 'package:capa/domain/usecases/get_capas.dart';
import 'package:capa/domain/usecases/get_capa_detail.dart';
import 'package:capa/domain/usecases/create_capa.dart';
import 'package:capa/domain/usecases/closeout_capa.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';

// Audit
import 'package:audit/data/datasources/audit_remote_datasource.dart';
import 'package:audit/data/datasources/checklist_remote_datasource.dart';
import 'package:audit/data/datasources/auditor_remote_datasource.dart';
import 'package:audit/data/repositories/audit_repository_impl.dart';
import 'package:audit/data/repositories/checklist_repository_impl.dart';
import 'package:audit/domain/repositories/audit_repository.dart';
import 'package:audit/domain/repositories/checklist_repository.dart';
import 'package:audit/domain/usecases/get_audits.dart';
import 'package:audit/domain/usecases/create_audit.dart';
import 'package:audit/domain/usecases/update_audit.dart';
import 'package:audit/domain/usecases/mark_audit_finished.dart';
import 'package:audit/domain/usecases/get_checklist.dart';
import 'package:audit/domain/usecases/get_auditors.dart';
import 'package:audit/domain/usecases/submit_checklist.dart';
import 'package:audit/presentation/bloc/audit_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ===== FINDING =====
  sl.registerLazySingleton(() => FindingRemoteDatasource(apiService: sl()));

  sl.registerLazySingleton<FindingRepository>(
    () => FindingRepositoryImpl(datasource: sl()),
  );

  sl.registerLazySingleton(() => CreateFinding(repository: sl()));
  sl.registerLazySingleton(() => UpdateFinding(repository: sl())); // ✅ BARU

  sl.registerFactory(
    () => FindingBloc(
      repository: sl(),
      createFinding: sl(),
      updateFinding: sl(), // ✅ BARU
    ),
  );

  // ===== CAPA =====
  sl.registerLazySingleton(() => CapaRemoteDatasource(apiService: sl()));

  sl.registerLazySingleton<CapaRepository>(
    () => CapaRepositoryImpl(datasource: sl()),
  );

  sl.registerLazySingleton(() => GetCapas(repository: sl()));
  sl.registerLazySingleton(() => GetCapaDetail(repository: sl()));
  sl.registerLazySingleton(() => CreateCapa(repository: sl()));
  sl.registerLazySingleton(() => CloseoutCapa(repository: sl()));

  sl.registerFactory(
    () => CapaBloc(
      getCapas: sl(),
      getCapaDetail: sl(),
      createCapa: sl(),
      closeoutCapa: sl(),
      repository: sl(),
    ),
  );

  // ===== AUDIT =====
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(() => AuthService(apiService: sl()));
  sl.registerLazySingleton(() => AuditRemoteDatasource(apiService: sl()));
  sl.registerLazySingleton(() => ChecklistRemoteDatasource(apiService: sl()));
  sl.registerLazySingleton(() => AuditorRemoteDatasource(apiService: sl()));

  sl.registerLazySingleton<AuditRepository>(
    () => AuditRepositoryImpl(datasource: sl()),
  );
  sl.registerLazySingleton<ChecklistRepository>(
    () => ChecklistRepositoryImpl(datasource: sl()),
  );

  // Usecases
  sl.registerLazySingleton(() => GetAudits(repository: sl()));
  sl.registerLazySingleton(() => CreateAudit(repository: sl()));
  sl.registerLazySingleton(() => UpdateAudit(repository: sl()));
  sl.registerLazySingleton(() => MarkAuditFinished(repository: sl()));
  sl.registerLazySingleton(() => GetChecklist(repository: sl()));
  sl.registerLazySingleton(() => GetAuditors(datasource: sl()));
  sl.registerLazySingleton(() => SubmitChecklist(repository: sl()));

  // BLoC
  sl.registerFactory(
    () => AuditBloc(
      repository: sl(),
      getAudits: sl(),
      createAudit: sl(),
      updateAudit: sl(),
      markAuditFinished: sl(),
      getChecklist: sl(),
      getAuditors: sl(),
      submitChecklist: sl(),
    ),
  );
}
