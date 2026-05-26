import 'package:finding/domain/entities/finding.dart';

class ChecklistEntity {
  final String id;
  final String title;
  final String description;
  final String category;
  bool? isPassed;
  bool hasFinding;

  Finding? finding;

  ChecklistEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isPassed,
    required this.hasFinding,
    this.finding,
  });
}