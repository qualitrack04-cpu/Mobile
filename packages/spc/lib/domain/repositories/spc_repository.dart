import 'package:spc/domain/entities/spc_analysis.dart';

abstract class SpcRepository {
  Future<List<SpcAnalysisSummary>> getHistory({
    required SpcPeriod period,
    SpcStatus? status,
    String? productName,
  });
    Future<SpcAnalysisResult> analyze({
    required String filePath,
    required String fileName,
    required String parameterName,
    required double lsl,
    required double usl,
    double? target,
    String? unit,
    String? description,
  });
}
