import 'package:audit/domain/entities/checklist_entity.dart';
import 'package:audit/domain/repositories/checklist_repository.dart';

class SubmitChecklist {
  final ChecklistRepository repository;

  SubmitChecklist({required this.repository});

  /// Menyimpan semua jawaban PASS/FAIL ke backend dan menyelesaikan sesi.
  Future<void> call({
    required String sessionId,
    required List<ChecklistEntity> checklists,
  }) async {
    return await repository.submitChecklistResponses(
      sessionId: sessionId,
      checklists: checklists,
    );
  }
}
