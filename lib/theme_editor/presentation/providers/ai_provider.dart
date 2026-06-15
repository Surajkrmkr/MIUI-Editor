import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import 'element_provider.dart';
import 'usecase_providers.dart';

class AiState {
  const AiState({
    this.isLoading = false,
    this.lastError,
    this.variants = const [],
  });

  final bool isLoading;
  final String? lastError;

  /// Each entry is a fully generated layout (list of LockElements).
  final List<List<LockElement>> variants;

  bool get hasVariants => variants.isNotEmpty;

  AiState copyWith({
    bool? isLoading,
    String? lastError,
    List<List<LockElement>>? variants,
  }) =>
      AiState(
        isLoading: isLoading ?? this.isLoading,
        lastError: lastError,
        variants: variants ?? this.variants,
      );
}

class AiNotifier extends Notifier<AiState> {
  @override
  AiState build() => const AiState();

  /// Generate [count] layout variants in parallel and store them in state.
  Future<void> generateVariants(String prompt, int count) async {
    state = const AiState(isLoading: true);
    final els = ref.read(elementProvider).elements;

    final (variants, failure) = await ref
        .read(generateAiVariantsUseCaseProvider)
        .call(currentElements: els, prompt: prompt, count: count);

    if (failure != null && variants.isEmpty) {
      state = AiState(lastError: failure.message);
      return;
    }

    state = AiState(variants: variants);
  }

  /// Apply one of the generated variants to the canvas.
  void applyVariant(List<LockElement> variant) {
    ref.read(elementProvider.notifier).setAll(variant);
    state = const AiState();
  }

  /// Dismiss the variants picker without applying anything.
  void clearVariants() => state = const AiState();

  // ── Legacy single-shot method (kept for backward compat) ─────────────────────

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

final aiProvider = NotifierProvider<AiNotifier, AiState>(AiNotifier.new);
