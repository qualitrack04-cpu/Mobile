import 'package:finding/data/models/finding_model.dart';
import 'package:finding/domain/entities/finding_severity.dart';

class FindingMockDatasource {
  final List<FindingModel> _mockFindings = [
    FindingModel(
      id: '1',
      sessionId: null,
      category: FindingCategory.majorNC,
      description: 'Prosedur tidak terdokumentasi dengan baik di departemen produksi',
      clauseRef: 'ISO9001 8.1',
      foundAt: DateTime(2024, 10, 14),
      status: FindingStatus.open,
    ),
    FindingModel(
      id: '2',
      sessionId: null,
      category: FindingCategory.minorNC,
      description: 'Kalibrasi alat ukur tekanan belum dilakukan sesuai jadwal',
      clauseRef: 'ISO9001 7.1.5',
      foundAt: DateTime(2024, 10, 15),
      status: FindingStatus.inProgress,
    ),
    FindingModel(
      id: '3',
      sessionId: null,
      category: FindingCategory.observation,
      description: 'Catatan pemeliharaan mesin tidak lengkap',
      clauseRef: 'ISO9001 7.1.3',
      foundAt: DateTime(2024, 10, 16),
      status: FindingStatus.closed,
    ),
    FindingModel(
      id: '4',
      sessionId: null,
      category: FindingCategory.ofi,
      description: 'Peluang peningkatan pada proses pengecekan kualitas bahan baku',
      clauseRef: 'ISO9001 8.4',
      foundAt: DateTime(2024, 10, 17),
      status: FindingStatus.open,
    ),
  ];

  Future<List<FindingModel>> getFindings({
    FindingStatus? status,
    FindingCategory? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var result = _mockFindings.toList();
    if (status != null) {
      result = result.where((f) => f.status == status).toList();
    }
    if (category != null) {
      result = result.where((f) => f.category == category).toList();
    }
    return result;
  }

  Future<FindingModel> getFindingDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockFindings.firstWhere(
      (f) => f.id == id,
      orElse: () => throw Exception('Finding not found'),
    );
  }

  Future<FindingModel> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newFinding = FindingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: null,
      category: category,
      description: description,
      clauseRef: clauseRef,
      foundAt: DateTime.now(),
      status: FindingStatus.open,
    );
    _mockFindings.add(newFinding);
    return newFinding;
  }

  // ✅ BARU: update keseluruhan data finding
  Future<FindingModel> updateFinding({
    required String id,
    required FindingCategory category,
    required String description,
    required String clauseRef,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockFindings.indexWhere((f) => f.id == id);
    if (index == -1) throw Exception('Finding not found');

    final updated = FindingModel(
      id: id,
      sessionId: _mockFindings[index].sessionId,
      category: category,
      description: description,
      clauseRef: clauseRef,
      foundAt: _mockFindings[index].foundAt,
      status: _mockFindings[index].status,
    );
    _mockFindings[index] = updated;
    return updated;
  }

  Future<void> updateFindingStatus({
    required String id,
    required FindingStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockFindings.indexWhere((f) => f.id == id);
    if (index == -1) throw Exception('Finding not found');
    _mockFindings[index] = FindingModel(
      id: _mockFindings[index].id,
      sessionId: _mockFindings[index].sessionId,
      category: _mockFindings[index].category,
      description: _mockFindings[index].description,
      clauseRef: _mockFindings[index].clauseRef,
      foundAt: _mockFindings[index].foundAt,
      status: status,
    );
  }

  Future<void> deleteFinding(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockFindings.removeWhere((f) => f.id == id);
  }
}
