import 'package:core_services/services/api_service.dart';
import 'package:capa/data/datasources/capa_remote_datasource.dart'; // ← ganti ini
import 'package:capa/data/models/capa_model.dart';
import 'package:capa/domain/entities/capa.dart';
import 'package:capa/domain/repositories/capa_repository.dart';

class CapaRepositoryImpl implements CapaRepository {
  final CapaRemoteDatasource datasource; // ← ganti tipe ini

  CapaRepositoryImpl({required this.datasource});

  @override
  Future<List<Capa>> getCapas() async {
    try {
      return await datasource.getCapas();
    } catch (e) {
      throw Exception('Failed to load CAPA items: $e');
    }
  }

  @override
  Future<Capa> getCapaDetail(String id) async {
    try {
      return await datasource.getCapaDetail(id);
    } catch (e) {
      throw Exception('Failed to load CAPA details: $e');
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
      throw Exception('Failed to create the CAPA: $e');
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
      throw Exception('Failed to update the CAPA: $e');
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
      throw Exception('Failed to update the CAPA status: $e');
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
      throw Exception('Failed to close out the CAPA: $e');
    }
  }
}
