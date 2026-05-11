import 'package:capa/domain/entities/capa.dart';

abstract class CapaRepository {
  Future<List<Capa>> getCapas();

  Future<Capa> getCapaDetail(String id);

  Future<Capa> createCapa({
    required String findingId,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
  });

  Future<Capa> updateCapa({
    required String id,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
  });

  Future<void> closeoutCapa({
    required String id,
    required bool isEffective,
    required String verificationNotes,
    required String verifiedById,
  });
}