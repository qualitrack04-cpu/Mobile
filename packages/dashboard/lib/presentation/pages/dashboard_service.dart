import 'package:core_services/core_services.dart';

class DashboardSummary {
  final int totalAudit;
  final int totalFinding;
  final int totalCapa;

  DashboardSummary({
    required this.totalAudit,
    required this.totalFinding,
    required this.totalCapa,
  });
}

class DashboardService {
  final ApiService apiService;

  DashboardService({required this.apiService});

  Future<DashboardSummary> getSummary() async {
    // Panggil 3 endpoint sekaligus (paralel, lebih cepat)
    final results = await Future.wait([
      apiService.client.get('/api/AuditPlan'),
      apiService.client.get('/api/Finding'),
      apiService.client.get('/api/Capa'),
    ]);

    // Total audit — response: { total: int, data: [...] }
    final totalAudit = results[0].data['total'] as int? ?? 0;

    // Total finding — response: array langsung
    final findingList = results[1].data as List;
    final totalFinding = findingList.length;

    // Total CAPA — semua CAPA tanpa filter
    final capaList = results[2].data as List;
    final totalCapa = capaList.length;

    return DashboardSummary(
      totalAudit: totalAudit,
      totalFinding: totalFinding,
      totalCapa: totalCapa,
    );
  }
}