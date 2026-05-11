import 'package:capa/domain/repositories/capa_repository.dart';

class CloseoutCapa {
  final CapaRepository repository;

  CloseoutCapa({required this.repository});

  Future<void> call({
    required String id,
    required bool isEffective,
    required String verificationNotes,
    required String verifiedById,
  }) async {
    return await repository.closeoutCapa(
      id: id,
      isEffective: isEffective,
      verificationNotes: verificationNotes,
      verifiedById: verifiedById,
    );
  }
}