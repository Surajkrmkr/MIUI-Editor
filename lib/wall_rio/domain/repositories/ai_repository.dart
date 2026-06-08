import '../models/ai_models.dart';

abstract class AIRepository {
  Future<AIAnalysisResult?> analyzeImage(String filePath);
}
