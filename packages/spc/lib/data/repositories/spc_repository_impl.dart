import 'package:spc/data/datasources/spc_remote_datasource.dart';
import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/domain/repositories/spc_repository.dart';

class SpcRepositoryImpl implements SpcRepository {
  final SpcRemoteDatasource datasource;

  SpcRepositoryImpl({required this.datasource});

  @override
  Future<List<SpcAnalysisSummary>> getHistory({
    required SpcPeriod period,
    SpcStatus? status,
    String? productName,
  }) async {
    return datasource.getHistory(
      period: period,
      status: status,
      productName: productName,
    );
  }

    @override
  Future<SpcAnalysisResult> analyze({
    required String filePath,
    required String fileName,
    required String parameterName,
    required double lsl,
    required double usl,
    double? target,
    String? unit,
    String? description,
  }) {
    return datasource.analyze(
      filePath: filePath,
      fileName: fileName,
      parameterName: parameterName,
      lsl: lsl,
      usl: usl,
      target: target,
      unit: unit,
      description: description,
    );
  }
  @override
  Future<SpcAnalysisResult> getDetail(String id) {
    return datasource.getById(id);
  }
}
