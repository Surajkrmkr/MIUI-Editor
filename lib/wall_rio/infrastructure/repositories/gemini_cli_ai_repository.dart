import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/ai_models.dart';
import '../../domain/repositories/ai_repository.dart';

class GeminiCliAIRepository implements AIRepository {
  String? _cachedCommand;

  Future<String> _getGeminiCommand() async {
    if (_cachedCommand != null) return _cachedCommand!;

    // 1. Try standard 'gemini' (with shell)
    try {
      final check = await Process.run('gemini', ['--version'], runInShell: true);
      if (check.exitCode == 0) {
        return _cachedCommand = 'gemini';
      }
    } catch (_) {}

    // 2. Try 'gemini.cmd' explicitly on Windows
    if (Platform.isWindows) {
      try {
        final check = await Process.run('gemini.cmd', ['--version'], runInShell: true);
        if (check.exitCode == 0) {
          return _cachedCommand = 'gemini.cmd';
        }
      } catch (_) {}

      // 3. Try common npm path
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        final npmPath = p.join(appData, 'npm', 'gemini.cmd');
        if (await File(npmPath).exists()) {
          return _cachedCommand = npmPath;
        }
      }
    }

    // Default back to 'gemini' and let it fail with error if still not found
    return 'gemini';
  }

  @override
  Future<AIAnalysisResult?> analyzeImage(String filePath) async {
    try {
      final command = await _getGeminiCommand();
      final prompt = """
Analyze the image at $filePath and provide:
1. A descriptive name (2-4 words).
2. 5-10 relevant tags.
3. 3-5 dominant hex color codes.
Return the result strictly as a JSON object with keys: 'name', 'tags', 'colors'.
""";

      final result = await Process.run(command, [
        '-p',
        prompt,
        '--raw-output',
      ], runInShell: true);

      if (result.exitCode != 0) {
        debugPrint('Gemini CLI error (exit ${result.exitCode}): ${result.stderr}');
        return null;
      }
// ... rest of method remains same

      final output = result.stdout.toString().trim();
      final jsonStart = output.indexOf('{');
      final jsonEnd = output.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;
      
      final jsonStr = output.substring(jsonStart, jsonEnd + 1);
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      
      return AIAnalysisResult.fromJson(json);
    } catch (e) {
      if (e is ProcessException) {
        debugPrint('Gemini CLI not found or failed to start: ${e.message}');
        debugPrint('Command attempted: ${e.executable} ${e.arguments.join(' ')}');
      } else {
        debugPrint('Error calling Gemini CLI: $e');
      }
      return null;
    }
  }
}
