class ChecklistEntity {
  final String title;
  final String description;
  final String category;
  bool? isPassed;
  bool hasFinding;

  ChecklistEntity({
    required this.title,
    required this.description,
    required this.category,
    required this.isPassed,
    required this.hasFinding,
  });
}