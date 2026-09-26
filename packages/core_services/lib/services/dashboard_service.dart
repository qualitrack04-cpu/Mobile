import 'package:core_services/core_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuditSummary {
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

  factory AuditSummary.fromJson(Map<String, dynamic> json) {
    return AuditSummary(
      activeAudit: json['activeAudit'] ?? 0,
      totalCapa: json['totalCapa'] ?? 0,
      capaOpen: json['capaOpen'] ?? 0,
      capaOverdue: json['capaOverdue'] ?? 0,
    );
  }
}

class ComplianceScore {
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

  factory ComplianceScore.fromJson(Map<String, dynamic> json) {
    return ComplianceScore(
      department: json['department'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalAudit: json['totalAudit'] ?? 0,
      totalResponses: json['totalResponses'] ?? 0,
      conformResponses: json['conformResponses'] ?? 0,
    );
  }
}

class ComplianceScoreResponse {
  final double overallScore;
  final List<ComplianceScore> data;

  ComplianceScoreResponse({required this.overallScore, required this.data});

  factory ComplianceScoreResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];

    return ComplianceScoreResponse(
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      data:
          list
              .map((e) => ComplianceScore.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

// Level 3: detail satu departemen dalam jadwal
class ScheduleDepartment {
  final String department;
  final String scheduleId;
  final String planTitle;
  final String standard;
  final String auditorName;

  ScheduleDepartment({
    required this.department,
    required this.scheduleId,
    required this.planTitle,
    required this.standard,
    required this.auditorName,
  });

  factory ScheduleDepartment.fromJson(Map<String, dynamic> json) {
    return ScheduleDepartment(
      department: json['department'] ?? '',
      scheduleId: json['scheduleId'] ?? '',
      planTitle: json['planTitle'] ?? '',
      standard: json['standard'] ?? '',
      auditorName: json['auditorName'] ?? '',
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
      departments:
          list
              .map(
                (e) => ScheduleDepartment.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

// Level 1: wrapper keseluruhan response dari API
class AuditScheduleResponse {
  final int month;
  final int year;
  final List<AuditScheduleDay> data;

  AuditScheduleResponse({
    required this.month,
    required this.year,
    required this.data,
  });

  factory AuditScheduleResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return AuditScheduleResponse(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      data:
          list
              .map((e) => AuditScheduleDay.fromJson(e as Map<String, dynamic>))
              .toList(),
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

class CompletedAuditReport {
  final String sessionId;
  final String department;
  final String planTitle;

  CompletedAuditReport({
    required this.sessionId,
    required this.department,
    required this.planTitle,
  });

  factory CompletedAuditReport.fromJson(Map<String, dynamic> json) {
    return CompletedAuditReport(
      sessionId: json['sessionId'] ?? '',
      department: json['department'] ?? '',
      planTitle: json['auditPlanTitle'] ?? '',
    );
  }
}

class QualityTrendPoint {
  final int month;
  final int year;
  final String monthName;
  final double score;

  QualityTrendPoint({
    required this.month,
    required this.year,
    required this.monthName,
    required this.score,
  });

  factory QualityTrendPoint.fromJson(Map<String, dynamic> json) {
    final periodLabel = json['periodLabel'] as String? ?? '';

    return QualityTrendPoint(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      monthName:
          json['monthName'] as String? ?? periodLabel.split(' ').first,
      score:
          (json['overallScore'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

class QualityTrendResponse {
  final double currentScore;
  final double previousScore;
  final double change;
  final List<QualityTrendPoint> data;

  QualityTrendResponse({
    required this.currentScore,
    required this.previousScore,
    required this.change,
    required this.data,
  });

  factory QualityTrendResponse.fromJson(dynamic json) {
    if (json is List) {
      final points =
          json
              .map(
                (item) =>
                    QualityTrendPoint.fromJson(item as Map<String, dynamic>),
              )
              .toList();
      final currentScore = points.isEmpty ? 0.0 : points.last.score;
      final previousScore =
          points.length < 2 ? 0.0 : points[points.length - 2].score;

      return QualityTrendResponse(
        currentScore: currentScore,
        previousScore: previousScore,
        change: currentScore - previousScore,
        data: points,
      );
    }

    final map = json as Map<String, dynamic>;
    final list = map['data'] as List? ?? [];

    return QualityTrendResponse(
      currentScore: (map['currentScore'] as num?)?.toDouble() ?? 0.0,
      previousScore: (map['previousScore'] as num?)?.toDouble() ?? 0.0,
      change: (map['change'] as num?)?.toDouble() ?? 0.0,
      data:
          list
              .map((e) => QualityTrendPoint.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class DashboardService {
  final ApiService apiService;

  DashboardService({required this.apiService});

  Future<QualityTrendResponse> getQualityTrend({required int months}) async {
    try {
      final timeframe = switch (months) {
        6 => '6m',
        12 => '1y',
        _ => '3m',
      };
      final res = await apiService.client.get(
        '/api/QualityScore/overall-trend',
        queryParameters: {'timeframe': timeframe},
      );

      return QualityTrendResponse.fromJson(res.data);
    } catch (e) {
      print('Error getQualityTrend: $e');

      return QualityTrendResponse(
        currentScore: 0,
        previousScore: 0,
        change: 0,
        data: [],
      );
    }
  }

  // Fungsi 4: Ambil Laporan Audit Selesai
  Future<List<CompletedAuditReport>> getCompletedReports() async {
    try {
      final res = await apiService.client.get('/api/AuditReport');
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => CompletedAuditReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getCompletedReports: $e');
      return [];
    }
  }

  // Fungsi 1: Ambil Audit Summary
  Future<AuditSummary> getAuditSummary() async {
    try {
      final res = await apiService.client.get('/api/Dashboard/summary');
      return AuditSummary.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      print('Error getAuditSummary: $e');
      return AuditSummary(
        activeAudit: 0,
        totalCapa: 0,
        capaOpen: 0,
        capaOverdue: 0,
      );
    }
  }

  // Fungsi 2: Ambil Compliance Score
  Future<ComplianceScoreResponse> getComplianceScores() async {
    try {
      final res = await apiService.client.get(
        '/api/Dashboard/compliance-score',
      );
      return ComplianceScoreResponse.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      print('Error getComplianceScores: $e');
      return ComplianceScoreResponse(overallScore: 0, data: []);
    }
  }

  // Fungsi 3: Ambil Jadwal Audit per Bulan
  Future<AuditScheduleResponse> getAuditSchedule({
    required int month,
    required int year,
  }) async {
    try {
      final responses = await Future.wait([
        apiService.client.get(
          '/api/Dashboard/audit-schedule',
          queryParameters: {'month': month, 'year': year},
        ),
        apiService.client.get('/api/AuditPlan'),
      ]);

      final scheduleResponse = AuditScheduleResponse.fromJson(
        responses[0].data as Map<String, dynamic>,
      );
      final auditPlans = responses[1].data['data'] as List? ?? [];
      final existingScheduleIds = <String>{};
      final completedScheduleIds = <String>{};
      final auditorNamesByScheduleId = <String, String>{};

      for (final plan in auditPlans) {
        final schedules =
            (plan as Map<String, dynamic>)['schedules'] as List? ?? [];
        for (final schedule in schedules) {
          final scheduleData = schedule as Map<String, dynamic>;
          final scheduleId = scheduleData['id']?.toString();
          final auditorName =
              scheduleData['auditorName'] as String? ??
              (scheduleData['auditor'] as Map<String, dynamic>?)?['fullName']
                  as String? ??
              '';

            if (scheduleId != null && scheduleId.isNotEmpty) {
            existingScheduleIds.add(scheduleId);
            }

          if (scheduleId != null &&
              scheduleId.isNotEmpty &&
              auditorName.isNotEmpty) {
            auditorNamesByScheduleId[scheduleId] = auditorName;
          }

          if (scheduleData['isFinished'] == true) {
            if (scheduleId != null && scheduleId.isNotEmpty) {
              completedScheduleIds.add(scheduleId);
            }
          }
        }
      }

      final filteredDays =
          scheduleResponse.data
              .map(
                (day) => AuditScheduleDay(
                  day: day.day,
                  departments:
                      day.departments
                          .where(
                            (department) =>
                                existingScheduleIds.contains(
                                  department.scheduleId,
                                ) &&
                                !completedScheduleIds.contains(
                                  department.scheduleId,
                                ),
                          )
                          .map(
                            (department) => ScheduleDepartment(
                              department: department.department,
                              scheduleId: department.scheduleId,
                              planTitle: department.planTitle,
                              standard: department.standard,
                              auditorName:
                                  auditorNamesByScheduleId[department
                                      .scheduleId] ??
                                  department.auditorName,
                            ),
                          )
                          .toList(),
                ),
              )
              .where((day) => day.departments.isNotEmpty)
              .toList();

      return AuditScheduleResponse(
        month: scheduleResponse.month,
        year: scheduleResponse.year,
        data: filteredDays,
      );
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

    final activeAuditsCount =
        auditPlansList.where((planJson) {
          final schedules = planJson['schedules'] as List? ?? [];
          if (schedules.isEmpty) return true;

          final firstSchedule = schedules[0] as Map<String, dynamic>;
          final isFinished = firstSchedule['isFinished'] as bool? ?? false;
          final completedAtStr = firstSchedule['completedAt'] as String?;
          final completedAt =
              completedAtStr != null ? DateTime.tryParse(completedAtStr) : null;

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
          const statusIntMap = {
            0: 'Open',
            1: 'In Progress',
            2: 'Pending Verification',
            3: 'Closed',
          };
          const statusStrMap = {
            'Open': 'Open',
            'InProgress': 'In Progress',
            'PendingVerification': 'Pending Verification',
            'Closed': 'Closed',
          };
          final statusStr =
              capaStatusRaw is int
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
