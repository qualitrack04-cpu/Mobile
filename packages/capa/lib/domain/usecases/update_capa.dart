import 'package:capa/domain/entities/capa.dart';
import 'package:capa/domain/repositories/capa_repository.dart';

class UpdateCapa {
  final CapaRepository repository;

  UpdateCapa({required this.repository});

  Future<Capa> call({
    required String id,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
  }) async {
    return await repository.updateCapa(
      id: id,
      rootCause: rootCause,
      correctiveAction: correctiveAction,
      preventiveAction: preventiveAction,
      picId: picId,
      deadline: deadline,
    );
  }
}