import 'package:get_it/get_it.dart';
import 'package:finding/data/datasources/finding_mock_datasource.dart';
import 'package:finding/data/repositories/finding_repository_impl.dart';
import 'package:finding/domain/repositories/finding_repository.dart';
import 'package:finding/domain/usecases/create_finding.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
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
}