import 'package:core/core.dart';
import 'package:core_services/core_services.dart';

/// Satu audit yang jatuh tempo dalam waktu dekat.
class UpcomingAuditItem {
  const UpcomingAuditItem({
    required this.scheduleId,
    required this.title,
    required this.department,
    required this.rawDepartment,
    required this.standard,
    required this.auditorName,
    required this.date,
  });

  /// Audit yang tanggalnya lebih dari ini hari ke depan tidak ditampilkan.
  static const int windowDays = 5;

  final String scheduleId;
  final String title;

  /// Nama departemen untuk tampilan, misalnya "Production".
  final String department;

  /// Nama departemen apa adanya dari backend, misalnya "Produksi".
  final String rawDepartment;

  final String standard;
  final String auditorName;
  final DateTime date;

  /// Sisa hari dari hari ini. 0 berarti hari ini.
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  /// Memilih audit dari [schedule] yang jatuh tempo hari ini sampai
  /// [windowDays] hari ke depan, diurutkan dari tanggal terdekat.
  static List<UpcomingAuditItem> fromSchedule(AuditScheduleResponse schedule) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <UpcomingAuditItem>[];

    for (final scheduleDay in schedule.data) {
      final auditDate = DateTime(
        schedule.year,
        schedule.month,
        scheduleDay.day,
      );
      final daysLeft = auditDate.difference(today).inDays;
      if (daysLeft < 0 || daysLeft > windowDays) continue;

      for (final department in scheduleDay.departments) {
        result.add(
          UpcomingAuditItem(
            scheduleId: department.scheduleId,
            title: department.planTitle,
            department: DepartmentStyle.normalize(department.department),
            rawDepartment: department.department,
            standard: department.standard,
            auditorName: department.auditorName,
            date: auditDate,
          ),
        );
      }
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}