import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/theme_project.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/element_widget.dart';

class AiRemoteDataSource {
  AiRemoteDataSource(this._apiKey);
  final String _apiKey;

  Future<List<LockElement>> generateLockscreen({
    required List<LockElement> currentElements,
    required String prompt,
  }) async {
    final exampleJson =
        jsonEncode(currentElements.map((e) => e.toJson()).toList());

    final schema = Schema.array(
      description: 'List of lockscreen elements',
      items: Schema.object(properties: {
        'type': Schema.enumString(
          enumValues: ElementType.values.map((e) => e.name).toList(),
          description: 'Element type',
        ),
        'dx': Schema.number(),
        'dy': Schema.number(),
        'scale': Schema.number(),
        'height': Schema.number(),
        'width': Schema.number(),
        'radius': Schema.number(),
        'borderWidth': Schema.number(),
        'angle': Schema.number(),
        'fontSize': Schema.number(),
        'borderColor': Schema.integer(),
        'color': Schema.integer(),
        'colorSecondary': Schema.integer(),
        'gradientType': Schema.enumString(
            enumValues: GradientType.values.map((e) => e.name).toList()),
        'font': Schema.string(),
        'path': Schema.string(),
        'text': Schema.string(),
        'fontWeight': Schema.enumString(enumValues: [
          'FontWeight.w100',
          'FontWeight.w200',
          'FontWeight.w300',
          'FontWeight.w400',
          'FontWeight.w500',
          'FontWeight.w600',
          'FontWeight.w700',
          'FontWeight.w800',
          'FontWeight.w900',
        ]),
        'isShort': Schema.boolean(),
        'isWrap': Schema.boolean(),
        'showGuideLines': Schema.boolean(),
      }),
    );

    final model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are a MIUI lockscreen designer. '
        'Example current layout: $exampleJson',
      ),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) throw Exception('Empty AI response');
    final list = jsonDecode(text) as List<dynamic>;
    return list
        .map((e) => LockElement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ColorEntry>?> generatePalette(String prompt) async {
    return null;
  }

  Future<String?> suggestIconStyle(IconVariant current) async {
    return null;
  }

  Stream<String> streamChat(String userMessage, ThemeProject context) {
    // Implementation for streaming chat
    return Stream.value('Response');
  }
}
