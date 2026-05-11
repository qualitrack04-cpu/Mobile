import 'package:get_it/get_it.dart';

// Finding
import 'package:finding/data/datasources/finding_mock_datasource.dart';
import 'package:finding/data/repositories/finding_repository_impl.dart';
import 'package:finding/domain/repositories/finding_repository.dart';
import 'package:finding/domain/usecases/create_finding.dart';
import 'package:finding/domain/usecases/update_finding.dart'; // ✅ BARU
import 'package:finding/presentation/bloc/finding_bloc.dart';

// CAPA
import 'package:capa/data/datasources/capa_mock_datasource.dart';
import 'package:capa/data/repositories/capa_repository_impl.dart';
import 'package:capa/domain/repositories/capa_repository.dart';
import 'package:capa/domain/usecases/get_capas.dart';
import 'package:capa/domain/usecases/get_capa_detail.dart';
import 'package:capa/domain/usecases/create_capa.dart';
import 'package:capa/domain/usecases/closeout_capa.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';

// Audit
import 'package:audit/data/datasources/audit_datasource.dart';
import 'package:audit/data/datasources/checklist_datasource.dart';
import 'package:audit/data/repositories/audit_repository_impl.dart';
import 'package:audit/data/repositories/checklist_repository_impl.dart';
import 'package:audit/domain/repositories/audit_repository.dart';
import 'package:audit/domain/repositories/checklist_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ===== FINDING =====
  sl.registerLazySingleton(() => FindingMockDatasource());

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
  sl.registerLazySingleton(() => CapaMockDatasource());

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
    ),
  );

  // ===== AUDIT =====
  sl.registerLazySingleton(() => AuditDatasource());
  sl.registerLazySingleton(() => ChecklistDatasource());

  sl.registerLazySingleton<AuditRepository>(
    () => AuditRepositoryImpl(datasource: sl()),
  );
  sl.registerLazySingleton<ChecklistRepository>(
    () => ChecklistRepositoryImpl(datasource: sl()),
  );
}
