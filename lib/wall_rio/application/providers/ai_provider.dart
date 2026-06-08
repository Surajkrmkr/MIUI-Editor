import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ai_models.dart';
import 'repository_providers.dart';

class AiStateNotifier extends Notifier<Map<String, AITask>> {
  @override
  Map<String, AITask> build() => {};

  Future<void> analyzeImage(String taskId, String filePath) async {
    state = {
      ...state,
      taskId: AITask(
        id: taskId,
        filePath: filePath,
        status: AITaskStatus.analyzing,
      ),
    };

    try {
      final repository = ref.read(wallRioAiRepositoryProvider);
      final result = await repository.analyzeImage(filePath);

      if (result != null) {
        state = {
          ...state,
          taskId: state[taskId]!.copyWith(
            status: AITaskStatus.completed,
            result: result,
          ),
        };
      } else {
        state = {
          ...state,
          taskId: state[taskId]!.copyWith(
            status: AITaskStatus.failed,
            errorMessage: 'Analysis failed to return a result',
          ),
        };
      }
    } catch (e) {
      state = {
        ...state,
        taskId: state[taskId]!.copyWith(
          status: AITaskStatus.failed,
          errorMessage: e.toString(),
        ),
      };
    }
  }
}

final aiStateProvider = NotifierProvider<AiStateNotifier, Map<String, AITask>>(
  AiStateNotifier.new,
);
