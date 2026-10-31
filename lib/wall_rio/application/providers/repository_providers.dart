import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../infrastructure/repositories/gemini_cli_ai_repository.dart';

final wallRioAiRepositoryProvider = Provider<AIRepository>(
  (ref) => GeminiCliAIRepository(),
);
