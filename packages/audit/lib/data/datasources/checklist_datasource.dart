import '../../domain/entities/checklist_entity.dart';

class ChecklistDatasource {
  Future<List<ChecklistEntity>> getChecklist() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    return [
      ChecklistEntity(
        title: '1.1 Emergency Stop Accessibility',
        description:
            'Verify all emergency stop buttons are unobstructed and clearly visible from operator stations.',
        category: 'Safety',
      ),

      ChecklistEntity(
        title: '1.2 Machine Guard Safety',
        description:
            'Ensure machine guards are properly installed and functional.',
        category: 'Safety',
      ),

      ChecklistEntity(
        title: '2.1 Documentation Validation',
        description:
            'Check whether operational documentation is updated.',
        category: 'Documentation',
      ),
    ];
  }
}