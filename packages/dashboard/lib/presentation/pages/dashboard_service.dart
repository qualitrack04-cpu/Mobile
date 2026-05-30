import 'package:core_services/core_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final auditPlansList = results[0].data['data'] as List? ?? [];
    final now = DateTime.now();

    final activeAuditsCount = auditPlansList.where((planJson) {
      final schedules = planJson['schedules'] as List? ?? [];
      if (schedules.isEmpty) return true;

      final firstSchedule = schedules[0] as Map<String, dynamic>;
      final isFinished = firstSchedule['isFinished'] as bool? ?? false;
      final completedAtStr = firstSchedule['completedAt'] as String?;
      final completedAt = completedAtStr != null ? DateTime.tryParse(completedAtStr) : null;

      if (!isFinished) return true;
      if (completedAt == null) return true;
      return now.difference(completedAt).inHours <= 24;
    }).length;

    final totalAudit = activeAuditsCount;

    // Total finding — response: array langsung
    final findingList = results[1].data as List;
    final capaList = results[2].data as List;

    int activeFindingsCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Map findingId -> Capa
      final capaMap = <String, Map<String, dynamic>>{};
      for (final capa in capaList) {
        final fId = capa['findingId'] as String?;
        if (fId != null) {
          capaMap[fId] = capa as Map<String, dynamic>;
        }
      }

      for (final findingJson in findingList) {
        final findingId = findingJson['id'] as String? ?? '';
        final statusRaw = findingJson['status'] as String? ?? '';

        DateTime? closedTime;

        // 1. Cek CAPA terkait
        final capa = capaMap[findingId];
        if (capa != null) {
          final capaStatusRaw = capa['status'];
          const statusIntMap = {0: 'Open', 1: 'In Progress', 2: 'Pending Verification', 3: 'Closed'};
          const statusStrMap = {
            'Open': 'Open',
            'InProgress': 'In Progress',
            'PendingVerification': 'Pending Verification',
            'Closed': 'Closed',
          };
          final statusStr = capaStatusRaw is int
              ? (statusIntMap[capaStatusRaw] ?? 'Open')
              : statusStrMap[capaStatusRaw as String? ?? ''] ?? 'Open';

          if (statusStr == 'Closed') {
            final closeOut = capa['closeOut'] as Map<String, dynamic>?;
            final verifiedAtStr = closeOut?['verifiedAt'] as String?;
            if (verifiedAtStr != null && verifiedAtStr.isNotEmpty) {
              closedTime = DateTime.tryParse(verifiedAtStr);
            }

            if (closedTime == null) {
              final prefsKey = 'capa_closed_time_${capa['id']}';
              final localTimeStr = prefs.getString(prefsKey);
              if (localTimeStr != null) {
                closedTime = DateTime.tryParse(localTimeStr);
              } else {
                closedTime = now;
                await prefs.setString(prefsKey, now.toIso8601String());
              }
            }
          }
        }

        // 2. Jika tidak ada CAPA tapi status finding sendiri adalah Closed
        if (closedTime == null && statusRaw == 'Closed') {
          final prefsKey = 'finding_closed_time_$findingId';
          final localTimeStr = prefs.getString(prefsKey);
          if (localTimeStr != null) {
            closedTime = DateTime.tryParse(localTimeStr);
          } else {
            closedTime = now;
            await prefs.setString(prefsKey, now.toIso8601String());
          }
        }

        // 3. Jika belum closed ATAU closed tapi belum lewat 24 jam, maka dihitung aktif
        if (closedTime == null) {
          activeFindingsCount++;
        } else {
          final diff = now.difference(closedTime);
          if (diff.inHours < 24) {
            activeFindingsCount++;
          }
        }
      }
    } catch (e) {
      print('Error calculating dashboard findings: $e');
      activeFindingsCount = findingList.length;
    }

    final totalFinding = activeFindingsCount;

    // Total CAPA — semua CAPA tanpa filter
    final totalCapa = capaList.length;

    return DashboardSummary(
      totalAudit: totalAudit,
      totalFinding: totalFinding,
      totalCapa: totalCapa,
    );
  }
}