import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/data/models/finding_model.dart';

class FindingMockDatasource {
  // Data dummy untuk test UI
  final List<FindingModel> _mockFindings = [
    FindingModel(
      id: '1',
      sessionId: null,
      category: FindingCategory.majorNC,
      description:
          'Prosedur tidak terdokumentasi dengan baik di departemen produksi',
      clauseRef: 'ISO9001 8.1',
      foundAt: DateTime(2024, 10, 14),
      status: FindingStatus.open,
    ),
    FindingModel(
      id: '2',
      sessionId: null,
      category: FindingCategory.minorNC,
      description:
          'Kalibrasi alat ukur tekanan belum dilakukan sesuai jadwal',
      clauseRef: 'ISO9001 7.1.5',
      foundAt: DateTime(2024, 10, 15),
      status: FindingStatus.inProgress,
    ),
    FindingModel(
      id: '3',
      sessionId: null,
      category: FindingCategory.observation,
      description:
          'Catatan pemeliharaan mesin tidak lengkap',
      clauseRef: 'ISO9001 7.1.3',
      foundAt: DateTime(2024, 10, 16),
      status: FindingStatus.closed,
    ),
    FindingModel(
      id: '4',
      sessionId: null,
      category: FindingCategory.ofi,
      description:
          'Peluang peningkatan pada proses pengecekan kualitas bahan baku',
      clauseRef: 'ISO9001 8.4',
      foundAt: DateTime(2024, 10, 17),
      status: FindingStatus.open,
    ),
  ];

  // Get semua finding
  Future<List<FindingModel>> getFindings({
    FindingStatus? status,
    FindingCategory? category,
  }) async {
    // Simulasi delay network
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

  // Get detail finding
  Future<FindingModel> getFindingDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final finding = _mockFindings.firstWhere(
      (f) => f.id == id,
      orElse: () => throw Exception('Finding not found'),
    );

    return finding;
  }

  // Buat finding baru
  Future<FindingModel> createFinding({
    required FindingCategory category,
    required String description,
    required String clauseRef,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newFinding = FindingModel(
      id: DateTime.now().millisecondsSince