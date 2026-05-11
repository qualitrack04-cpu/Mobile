import 'package:finding/domain/entities/finding.dart';

class ChecklistEntity {
  final String title;
  final String description;
  final String category;
  bool? isPassed;
  bool hasFinding;

  /// Menyimpan finding yang terhubung dengan checklist item ini.
  /// Diisi saat add finding berhasil, dipakai saat edit finding.
  Finding? finding;

  ChecklistEntity({
    required this.title,
    required this.description,
    required this.category,
    required this.isPassed,
    required this.hasFinding,
    this.finding,
  });
}