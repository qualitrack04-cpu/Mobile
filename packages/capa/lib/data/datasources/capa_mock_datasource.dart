import 'package:capa/data/models/capa_model.dart';

class CapaMockDatasource {
  final List<CapaModel> _mockCapas = [
    CapaModel(
      id: '1',
      findingId: '1',
      rootCause: 'Tidak ada SOP tertulis untuk prosedur dokumentasi',
      correctiveAction: 'Buat SOP dokumen produksi yang lengkap',
      preventiveAction: 'Training rutin tiap bulan untuk semua staff',
      picId: 'Amir, S.T',
      deadline: DateTime(2026, 5, 12),
      isClosed: false,
      createdAt: DateTime(2024, 10, 24),
    ),
    CapaModel(
      id: '2',
      findingId: '2',
      rootCause: 'Jadwal kalibrasi tidak dipantau secara rutin',
      correctiveAction: 'Buat sistem reminder kalibrasi otomatis',
      preventiveAction: 'Audit kalibrasi setiap 3 bulan sekali',
      picId: 'Budi, S.T',
      deadline: DateTime(2026, 6, 30),
      isClosed: false,
      createdAt: DateTime(2024, 10, 25),
    ),
    CapaModel(
      id: '3',
      findingId: '3',
      rootCause: 'Form pemeliharaan tidak diisi dengan lengkap',
      correctiveAction: 'Revisi form pemeliharaan dan training pengisian',
      preventiveAction: 'Checklist verifikasi form setiap minggu',
      picId: 'Citra, S.T',
      deadline: DateTime(2026, 7, 31),
      isClosed: true,
      createdAt: DateTime(2024, 10, 26),
    ),
  ];

  // Get semua CAPA
  Future<List<CapaModel>> getCapas() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockCapas.toList();
  }

  // Get detail CAPA
  Future<CapaModel> getCapaDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockCapas.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('CAPA not found'),
    );
  }

  // Buat CAPA baru
  Future<CapaModel> createCapa({
    required String findingId,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newCapa = CapaModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      findingId: findingId,
      rootCause: rootCause,
      correctiveAction: correctiveAction,
      preventiveAction: preventiveAction,
      picId: picId,
      deadline: deadline,
      isClosed: false,
      createdAt: DateTime.now(),
    );
    _mockCapas.add(newCapa);
    return newCapa;
  }

  // Update CAPA
  Future<CapaModel> updateCapa({
    required String id,
    required String rootCause,
    required String correctiveAction,
    required String preventiveAction,
    required String picId,
    required DateTime deadline,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockCapas.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception('CAPA not found');

    final updated = CapaModel(
      id: _mockCapas[index].id,
      findingId: _mockCapas[index].findingId,
      rootCause: rootCause,
      correctiveAction: correctiveAction,
      preventiveAction: preventiveAction,
      picId: picId,
      deadline: deadline,
      isClosed: _mockCapas[index].isClosed,
      createdAt: _mockCapas[index].createdAt,
    );
    _mockCapas[index] = updated;
    return updated;
  }

  // Closeout CAPA
  Future<void> closeoutCapa({
    required String id,
    required bool isEffective,
    required String verificationNotes,
    required String verifiedById,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockCapas.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception('CAPA not found');

    _mockCapas[index] = CapaModel(
      id: _mockCapas[index].id,
      findingId: _mockCapas[index].findingId,
      rootCause: _mockCapas[index].rootCause,
      correctiveAction: _mockCapas[index].correctiveAction,
      preventiveAction: _mockCapas[index].preventiveAction,
      picId: _mockCapas[index].picId,
      deadline: _mockCapas[index].deadline,
      isClosed: true,
      createdAt: _mockCapas[index].createdAt,
    );
  }
}