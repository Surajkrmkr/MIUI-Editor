import '../../core/errors/failures.dart';
import '../../data/datasources/remote/ai_remote_datasource.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl(this._ds);
  final AiRemoteDataSource _ds;

  @override
  Future<(List<LockElement>?, Failure?)> generateLockscreen({
    required List<LockElement> currentElements,
    required String prompt,
  }) async {
    try {
      final result = await _ds.generateLockscreen(
        currentElements: currentElements,
        prompt: prompt,
      );
      return (result, null);
    } catch (e) {
      return (null, AiFailure(_friendlyMessage(e)));
    }
  }

  @override
  Future<(List<List<LockElement>>, Failure?)> generateVariants({
    required List<LockElement> currentElements,
    required String prompt,
    required int count,
  }) async {
    try {
      final result = await _ds.generateVariants(
        currentElements: currentElements,
        prompt: prompt,
        count: count,
      );
      return (result, null);
    } catch (e) {
      return (<List<LockElement>>[], AiFailure(_friendlyMessage(e)));
    }
  }

  static String _friendlyMessage(Object e) {
    final raw = e.toString();
    if (raw.contains('prepayment credits are depleted')) {
      return 'Gemini prepaid credits depleted. Go to aistudio.google.com → "Get API key" → "Create API key in new project" and paste the new key in Settings.';
    }
    if (raw.contains('limit: 0') || raw.contains('"limit": 0')) {
      return 'Your Google Cloud project has 0 free-tier quota for all Gemini models.\n\n'
          'Fix: go to aistudio.google.com → "Get API key" → "Create API key in new project" to get a fresh project with free quota, then paste the new key in Settings.';
    }
    if (raw.contains('RESOURCE_EXHAUSTED') || raw.contains('429')) {
      return 'Rate limit hit. Wait a few seconds and try again.\n\n'
          'If this keeps happening, your project may have 0 free quota — create a new project at aistudio.google.com.';
    }
    if (raw.contains('not found') && raw.contains('model')) {
      return 'Model not found in Ollama. Run "ollama pull <model>" in your terminal, '
          'or tap "List installed models" in Settings → AI to see what\'s available.';
    }
    if (raw.contains('NOT_FOUND')) {
      return 'Model not found. Open Settings → AI → tap "List models" to see which models your API key supports.';
    }
    if (raw.contains('API_KEY_INVALID') || raw.contains('PERMISSION_DENIED')) {
      return 'Invalid Gemini API key. Paste a fresh key in Settings → AI.';
    }
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return 'No internet connection.';
    }
    if (raw.contains('Empty AI response')) {
      return 'AI returned an empty response. Try a different prompt.';
    }
    return raw;
  }
}
