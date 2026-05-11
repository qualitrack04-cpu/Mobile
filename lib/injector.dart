import 'package:get_it/get_it.dart';

// Finding
import 'package:finding/data/datasources/finding_mock_datasource.dart';
import 'package:finding/data/repositories/finding_repository_impl.dart';
import 'package:finding/domain/repositories/finding_repository.dart';
import 'package:finding/domain/usecases/create_finding.dart';
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

final sl = GetIt.instance;

Future<void> init() async {
  // ===== FINDING =====
  // Datasource
  sl.registerLazySingleton(() => FindingMockDatasource());

  // Repository
  sl.registerLazySingleton<FindingRepository>(
    () => FindingRepositoryImpl(datasource: sl()),
  );

  // Usecases
  sl.registerLazySingleton(() => CreateFinding(repository: sl()));

  // Bloc
  sl.registerFactory(
    () => FindingBloc(
      repository: sl(),
      createFinding: sl(),
    ),
  );

  // ===== CAPA =====
  // Datasource
  sl.registerLazySingleton(() => CapaMockDatasource());

  // Repository
  sl.registerLazySingleton<CapaRepository>(
    () => CapaRepositoryImpl(datasource: sl()),
  );

  // Usecases
  sl.registerLazySingleton(() => GetCapas(repository: sl()));
  sl.registerLazySingleton(() => GetCapaDetail(repository: sl()));
  sl.registerLazySingleton(() => CreateCapa(repository: sl()));
  sl.registerLazySingleton(() => CloseoutCapa(repository: sl()));

  // Bloc
  sl.registerFactory(
    () => CapaBloc(
      getCapas: sl(),
      getCapaDetail: sl(),
      createCapa: sl(),
      closeoutCapa: sl(),
    ),
  );
}