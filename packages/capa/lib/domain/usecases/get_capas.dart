import 'package:capa/domain/entities/capa.dart';
import 'package:capa/domain/repositories/capa_repository.dart';

class GetCapas {
  final CapaRepository repository;

  GetCapas({required this.repository});

  Future<List<Capa>> call() async {
    return await repository.getCapas();
  }
}