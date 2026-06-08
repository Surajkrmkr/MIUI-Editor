import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/repositories/ai_repository.dart';

class GeminiCliAIRepository implements AIRepository {
  @override
  Future<AIAnalysisResult?> analyzeImage(String filePath) async {
    try {
      final prompt = """
Analyze the image at $filePath and provide:
1. A descriptive name (2-4 words).
2. 5-10 relevant tags.
3. 3-5 dominant hex color codes.
Return the result strictly as a JSON object with keys: 'name', 'tags', 'colors'.
""";

      final result = await Process.run('gemini', [
        '-p',
        prompt,
        '--raw-output',
      ]);

      if (result.exitCode != 0) {
        debugPrint('Gemini CLI error: ${result.stderr}');
        return null;
      }

      final output = result.stdout.toString().trim();
      final jsonStart = output.indexOf('{');
      final jsonEnd = output.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;
      
      final jsonStr = output.substring(jsonStart, jsonEnd + 1);
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      
      return AIAnalysisResult.fromJson(json);
    } catch (e) {
      debugPrint('Error calling Gemini CLI: $e');
      return null;
    }
  }
}
