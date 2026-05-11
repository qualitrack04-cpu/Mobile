import 'package:audit/domain/entities/checklist_entity.dart';

class ChecklistModel extends ChecklistEntity {
  ChecklistModel({
    required super.title,
    required super.description,
    required super.category,
    required super.isPassed,
    required super.hasFinding,
    super.finding,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    return ChecklistModel(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      isPassed: json['isPassed'] as bool?,
      hasFinding: json['hasFinding'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'isPassed': isPassed,
      'hasFinding': hasFinding,
    };
  }

  factory ChecklistModel.fromEntity(ChecklistEntity entity) {
    return ChecklistModel(
      title: entity.title,
      description: entity.description,
      category: entity.category,
      isPassed: entity.isPassed,
      hasFinding: entity.hasFinding,
      finding: entity.finding,
    );
  }
}