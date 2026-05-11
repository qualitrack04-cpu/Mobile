import 'package:capa/domain/entities/capa.dart';
import 'package:capa/domain/repositories/capa_repository.dart';

class CreateCapa {
  final CapaRepository repository;

  CreateCapa({required this.repository});

  Future<Capa> call({
    required String findingId,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
  }) async {
    return await repository.createCapa(
      findingId: findingId,
      rootCause: rootCause,
      correctiveAction: correctiveAction,
      preventiveAction: preventiveAction,
      picId: picId,
      deadline: deadline,
    );
  }
}