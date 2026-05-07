import 'package:capa/domain/entities/capa.dart';
import 'package:capa/domain/repositories/capa_repository.dart';

class GetCapaDetail {
  final CapaRepository repository;

  GetCapaDetail({required this.repository});

  Future<Capa> call(String id) async {
    return await repository.getCapaDetail(id);
  }
}