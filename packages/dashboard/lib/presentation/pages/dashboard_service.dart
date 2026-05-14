import 'package:core_services/core_services.dart';

class DashboardSummary {
  final int totalAudit;
  final int totalFinding;
  final int capaDone;
  final int capaOverdue;

  DashboardSummary({
    required this.totalAudit,
    required this.totalFinding,
    required this.capaDone,
    required this.capaOverdue,
  });
}

class DashboardService {
  final ApiService apiService;

  DashboardService({required this.apiService});

  Future<DashboardSummary> getSummary() async {
    // Panggil 4 endpoint sekaligus (paralel, lebih cepat)
    final results = await Future.wait([
      apiService.client.get('/api/AuditPlan'),
      apiService.client.get('/api/Finding'),
      apiService.client.get('/api/Capa'),
      apiService.client.get('/api/Capa/overdue'),
    ]);

    // Total audit — response: { total: int, data: [...] }
    final totalAudit = results[0].data['total'] as int? ?? 0;

    // Total finding — response: array langsung
    final findingList = results[1].data as List;
    final totalFinding = findingList.length;

    // CAPA Done — filter status == 2 (Closed)
    // CAPAStatus enum di backend: Open=0, InProgress=1, Closed=2
    final capaList = results[2].data as List;
    final capaDone = capaList.where((c) => c['status'] == 2).length;

    // CAPA Overdue — response: array langsung
    final overdueList = results[3].data as List;
    final capaOverdue = overdueList.length;

    return DashboardSummary(
      totalAudit: totalAudit,
      totalFinding: totalFinding,
      capaDone: capaDone,
      capaOverdue: capaOverdue,
    );
  }
}