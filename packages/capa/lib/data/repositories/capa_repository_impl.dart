import 'package:capa/data/datasources/capa_mock_datasource.dart';
import 'package:capa/domain/entities/capa.dart';
import 'package:capa/domain/repositories/capa_repository.dart';

class CapaRepositoryImpl implements CapaRepository {
  final CapaMockDatasource datasource;

  CapaRepositoryImpl({required this.datasource});

  @override
  Future<List<Capa>> getCapas() async {
    try {
      return await datasource.getCapas();
    } catch (e) {
      throw Exception('Gagal mengambil data CAPA: $e');
    }
  }

  @override
  Future<Capa> getCapaDetail(String id) async {
    try {
      return await datasource.getCapaDetail(id);
    } catch (e) {
      throw Exception('Gagal mengambil detail CAPA: $e');
    }
  }

  @override
  Future<Capa> createCapa({
    required String findingId,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
    required String status,
  }) async {
    try {
      return await datasource.createCapa(
        findingId: findingId,
        rootCause: rootCause,
        correctiveAction: correctiveAction,
        preventiveAction: preventiveAction,
        picId: picId,
        deadline: deadline,
        status: status,
      );
    } catch (e) {
      throw Exception('Gagal membuat CAPA: $e');
    }
  }

  @override
  Future<Capa> updateCapa({
    required String id,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
    required String status, // ✅ fix: tidak error lagi
  }) async {
    try {
      return await datasource.updateCapa(
        id: id,
        rootCause: rootCause,
        correctiveAction: correctiveAction,
        preventiveAction: preventiveAction,
        picId: picId,
        deadline: deadline,
        status: status,
      );
    } catch (e) {
      throw Exception('Gagal update CAPA: $e');
    }
  }

  // ✅ implementasi update status
  @override
  Future<void> updateCapaStatus({
    required String id,
    required String status,
  }) async {
    try {
      await datasource.updateCapaStatus(id: id, status: status);
    } catch (e) {
      throw Exception('Gagal update status CAPA: $e');
    }
  }

  @override
  Future<void> closeoutCapa({
    required String id,
    required bool isEffective,
    required String verificationNotes,
    required String verifiedById,
  }) async {
    try {
      await datasource.closeoutCapa(
        id: id,
        isEffective: isEffective,
        verificationNotes: verificationNotes,
        verifiedById: verifiedById,
      );
    } catch (e) {
      throw Exception('Gagal closeout CAPA: $e');
    }
  }
}