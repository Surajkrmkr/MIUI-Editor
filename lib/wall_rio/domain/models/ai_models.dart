import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_models.freezed.dart';
part 'ai_models.g.dart';

@freezed
abstract class AIAnalysisResult with _$AIAnalysisResult {
  const factory AIAnalysisResult({
    required String name,
    required List<String> tags,
    required List<String> colors,
    String? category,
  }) = _AIAnalysisResult;

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) => _$AIAnalysisResultFromJson(json);
}

@freezed
abstract class AITask with _$AITask {
  const factory AITask({
    required String id,
    required String filePath,
    required AITaskStatus status,
    AIAnalysisResult? result,
    String? errorMessage,
  }) = _AITask;
}

enum AITaskStatus { pending, analyzing, completed, failed }
