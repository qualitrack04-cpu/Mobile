import 'package:audit/data/datasources/auditor_remote_datasource.dart';
import 'package:audit/domain/entities/auditor_entity.dart';

class GetAuditors {
  final AuditorRemoteDatasource datasource;

  GetAuditors({required this.datasource});

  Future<List<AuditorEntity>> call() async {
    try {
      return await datasource.getAuditors();
    } catch (e) {
      rethrow;
    }
  }
}
