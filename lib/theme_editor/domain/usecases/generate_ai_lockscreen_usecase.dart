import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/ai_repository.dart';

class GenerateAiLockscreenUseCase {
  const GenerateAiLockscreenUseCase(this._repo);
  final AiRepository _repo;

  Future<(List<LockElement>?, Failure?)> call({
    required List<LockElement> currentElements,
    required String prompt,
  }) => _repo.generateLockscreen(
        currentElements: currentElements,
        prompt: prompt,
      );
}
