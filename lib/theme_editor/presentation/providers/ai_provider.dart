import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import 'element_provider.dart';
import 'usecase_providers.dart';

class AiState {
  const AiState({this.isLoading = false, this.lastError});
  final bool    isLoading;
  final String? lastError;

  AiState copyWith({bool? isLoading, String? lastError}) => AiState(
    isLoading:  isLoading  ?? this.isLoading,
    lastError:  lastError,
  );
}

class AiNotifier extends Notifier<AiState> {
  @override
  AiState build() => const AiState();

  Future<Failure?> generateLockscreen(String prompt) async {
    state = const AiState(isLoading: true);
    final els = ref.read(elementProvider).elements;

    final (result, failure) = await ref
        .read(generateAiLockscreenUseCaseProvider)
        .call(currentElements: els, prompt: prompt);

    if (failure != null) {
      state = AiState(lastError: failure.message);
      return failure;
    }
    if (result != null) {
      ref.read(elementProvider.notifier).setAll(result);
    }
    state = const AiState();
    return null;
  }
}

final aiProvider =
    NotifierProvider<AiNotifier, AiState>(AiNotifier.new);
