import 'package:core_services/services/api_service.dart';

class UserKpi {
  final int totalCapaAssigned;
  final int totalCapaClosed;
  final int totalCapaOpenInProgress;
  final int totalCapaClosedOnTime;
  final int totalFindingsReported;
  final double onTimeCompletionRate; // 0.0 - 1.0
  final int? totalAssigned;
  final int? totalCompleted;
  final int? totalCompletedOnTime;
  final int? totalOverdue;
  final int? totalStalled;
  final double? onTimeRate;
  final double? complianceScore;
  final double? qualityScore;

  UserKpi({
    required this.totalCapaAssigned,
    required this.totalCapaClosed,
    required this.totalCapaOpenInProgress,
    required this.totalCapaClosedOnTime,
    required this.totalFindingsReported,
    required this.onTimeCompletionRate,
    this.totalAssigned,
    this.totalCompleted,
    this.totalCompletedOnTime,
    this.totalOverdue,
    this.totalStalled,
    this.onTimeRate,
    this.complianceScore,
    this.qualityScore,
  });

  factory UserKpi.fromJson(Map<String, dynamic> json) {
    return UserKpi(
      totalCapaAssigned:
        (json['totalCapaAssigned'] ?? json['totalAssigned']) as int? ?? 0,
      totalCapaClosed:
        (json['totalCapaClosed'] ?? json['totalCompleted']) as int? ?? 0,
      totalCapaOpenInProgress:
        (json['totalCapaOpenInProgress'] ?? json['totalStalled']) as int? ?? 0,
      totalCapaClosedOnTime:
        (json['totalCapaClosedOnTime'] ?? json['totalCompletedOnTime'])
          as int? ??
        0,
      totalFindingsReported: json['totalFindingsReported'] as int? ?? 0,
      onTimeCompletionRate:
        ((json['onTimeCompletionRate'] ?? json['onTimeRate']) as num?)
          ?.toDouble() ??
        0.0,
      totalAssigned: json['totalAssigned'] as int?,
      totalCompleted: json['totalCompleted'] as int?,
      totalCompletedOnTime: json['totalCompletedOnTime'] as int?,
      totalOverdue: json['totalOverdue'] as int?,
      totalStalled: json['totalStalled'] as int?,
      onTimeRate: (json['onTimeRate'] as num?)?.toDouble(),
      complianceScore: (json['complianceScore'] as num?)?.toDouble(),
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
    );
  }

  factory UserKpi.empty() {
    return UserKpi(
      totalCapaAssigned: 0,
      totalCapaClosed: 0,
      totalCapaOpenInProgress: 0,
      totalCapaClosedOnTime: 0,
      totalFindingsReported: 0,
      onTimeCompletionRate: 0.0,
    );
  }
}

class UserRecentActivity {
  final String activityType; // "CapaAction" | "CapaVerified" | "FindingReported"
  final String description;
  final DateTime? timestamp;
  final String relatedId;

  UserRecentActivity({
    required this.activityType,
    required this.description,
    this.timestamp,
    required this.relatedId,
  });

  factory UserRecentActivity.fromJson(Map<String, dynamic> json) {
    return UserRecentActivity(
      activityType: json['activityType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'] as String)
              : null,
      relatedId: json['relatedId'] as String? ?? '',
    );
  }
}

class ProfileService {
  final ApiService apiService;

  ProfileService({required this.apiService});

  /// Mengambil KPI user saat ini dari GET /api/Profile/kpi
  Future<UserKpi?> getKpi() async {
    try {
      final res = await apiService.client.get('/api/Profile/kpi');
      if (res.data != null && res.data is Map<String, dynamic>) {
        return UserKpi.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getKpi: $e');
      return null;
    }
  }

  /// Mengambil aktivitas terbaru user saat ini dari GET /api/Profile/recent-activity
  Future<List<UserRecentActivity>> getRecentActivity({int limit = 10}) async {
    try {
      final res = await apiService.client.get(
        '/api/Profile/recent-activity',
        queryParameters: {'limit': limit},
      );
      final list = res.data as List? ?? [];
      return list
          .map((e) => UserRecentActivity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getRecentActivity: $e');
      return [];
    }
  }
}
