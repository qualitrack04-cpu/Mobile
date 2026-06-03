import 'package:core_services/core_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuditSummary{
  final int activeAudit;
  final int totalCapa;
  final int capaOpen;
  final int capaOverdue;

  AuditSummary({
    required this.activeAudit,
    required this.totalCapa,
    required this.capaOpen,
    required this.capaOverdue,
  });

  factory AuditSummary.fromJson(Map<String, dynamic> json){
    return AuditSummary(
      activeAudit: json['activeAudit'] ?? 0,
      totalCapa: json['totalCapa'] ?? 0,
      capaOpen: json['capaOpen'] ?? 0,
      capaOverdue: json['capaOverdue'] ?? 0,
    );
  }
}

class ComplianceScore{
  final String department;
  final double score;
  final int totalAudit;
  final int totalResponses;
  final int conformResponses;

  ComplianceScore({
    required this.department,
    required this.score,
    required this.totalAudit,
    required this.totalResponses,
    required this.conformResponses,
  });

  factory ComplianceScore.fromJson(Map<String, dynamic> json){
    return ComplianceScore(
      department: json['department'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalAudit: json['totalAudit'] ?? 0,
      totalResponses: json['totalResponses'] ?? 0,
      conformResponses: json['conformResponses'] ?? 0,
    );
  }
}

class ComplianceScoreResponse{
  final double overallScore;
  final List<ComplianceScore> data;

  ComplianceScoreResponse({
    required this.overallScore,
    required this.data
  });

  factory ComplianceScoreResponse.fromJson(Map<String, dynamic> json){
    final list = json['data'] as List? ?? [];

    return ComplianceScoreResponse(
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      data: list.map((e)=>ComplianceScore.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// Level 3: detail satu departemen dalam jadwal
class ScheduleDepartment {
  final String department;
  final String scheduleId;
  final String planTitle;
  final String standard;

  ScheduleDepartment({
    required this.department,
    required this.scheduleId,
    required this.planTitle,
    required this.standard,
  });

  factory ScheduleDepartment.fromJson(Map<String, dynamic> json) {
    return ScheduleDepartment(
      department: json['department'] ?? '',
      scheduleId: json['scheduleId'] ?? '',
      planTitle: json['planTitle'] ?? '',
      standard: json['standard'] ?? '',
    );
  }
}

// Level 2: jadwal untuk satu hari tertentu
class AuditScheduleDay {
  final int day;
  final List<ScheduleDepartment> departments;

  AuditScheduleDay({required this.day, required this.departments});

  factory AuditScheduleDay.fromJson(Map<String, dynamic> json) {
    final list = json['departments'] as List? ?? [];
    return AuditScheduleDay(
      day: json['day'] ?? 0,
      departments: list.map((e) => ScheduleDepartment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// Level 1: wrapper keseluruhan response dari API
class AuditScheduleResponse {
  final int month;
  final int year;
  final List<AuditScheduleDay> data;

  AuditScheduleResponse({required this.month, required this.year, required this.data});

  factory AuditScheduleResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return AuditScheduleResponse(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      data: list.map((e) => AuditScheduleDay.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

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
  // Fungsi 1: Ambil Audit Summary
Future<AuditSummary> getAuditSummary() async {
  try {
    final res = await apiService.client.get('/api/Dashboard/summary');
    return AuditSummary.fromJson(res.data as Map<String, dynamic>);
  } catch (e) {
    print('Error getAuditSummary: $e');
    return AuditSummary(activeAudit: 0, totalCapa: 0, capaOpen: 0, capaOverdue: 0);
  }
}

// Fungsi 2: Ambil Compliance Score
Future<ComplianceScoreResponse> getComplianceScores() async {
  try {
    final res = await apiService.client.get('/api/Dashboard/compliance-score');
    return ComplianceScoreResponse.fromJson(res.data as Map<String, dynamic>);
  } catch (e) {
    print('Error getComplianceScores: $e');
    return ComplianceScoreResponse(overallScore: 0, data: []);
  }
}

// Fungsi 3: Ambil Jadwal Audit per Bulan
Future<AuditScheduleResponse> getAuditSchedule({required int month, required int year}) async {
  try {
    final res = await apiService.client.get(
      '/api/Dashboard/audit-schedule',
      queryParameters: {'month': month, 'year': year},
    );
    return AuditScheduleResponse.fromJson(res.data as Map<String, dynamic>);
  } catch (e) {
    print('Error getAuditSchedule: $e');
    return AuditScheduleResponse(month: month, year: year, data: []);
  }
}

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