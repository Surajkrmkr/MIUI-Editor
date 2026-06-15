import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/ai_repository.dart';

class GenerateAiVariantsUseCase {
  const GenerateAiVariantsUseCase(this._repo);
  final AiRepository _repo;

  Future<(List<List<LockElement>>, Failure?)> call({
    required List<LockElement> currentElements,
    required String prompt,
    required int count,
  }) =>
      _repo.generateVariants(
        currentElements: currentElements,
        prompt: prompt,
        count: count,
      );
}
