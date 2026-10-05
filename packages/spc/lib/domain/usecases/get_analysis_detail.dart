import 'package:spc/domain/entities/spc_analysis.dart';
import 'package:spc/domain/repositories/spc_repository.dart';

class GetAnalysisDetail {
  final SpcRepository repository;

  GetAnalysisDetail({required this.repository});

  Future<SpcAnalysisResult> call(String id) => repository.getDetail(id);
}