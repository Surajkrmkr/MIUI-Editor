import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:miui_icon_generator/theme_editor/domain/entities/theme_project.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/service_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/element_widget.dart';

class AiRemoteDataSource {
  const AiRemoteDataSource({
    required this.provider,
    this.geminiKey = '',
    this.groqKey = '',
    this.ollamaHost = AppConstants.ollamaDefaultHost,
    this.ollamaModel = AppConstants.ollamaDefaultModel,
  });

  final AiProvider provider;
  final String geminiKey;
  final String groqKey;
  final String ollamaHost;
  final String ollamaModel;

  // ── Compact element serialiser (omits default values to save tokens) ─────────

  // Defaults mirror LockElement.fromJson fallbacks
  static const Map<String, dynamic> _elementDefaults = {
    'scale': 1.0,      'height': 200.0,  'width': 200.0,   'radius': 10.0,
    'borderWidth': 0.0,'angle': 0.0,     'fontSize': 20.0, 'blurRadius': 0.0,
    // Colors intentionally NOT in defaults — always emit so the AI learns color usage
    'gradientType': 'linear',
    'font': 'Roboto',  'path': '',       'text': 'Text',
    'fontWeight': 'FontWeight.w400',
    'isShort': false,  'isWrap': false,  'showGuideLines': false,
    'isVisible': true, 'isLocked': false,'useSeparateColors': false,
  };

  static Map<String, dynamic> _compact(LockElement e) {
    final full = e.toJson();
    return {
      for (final kv in full.entries)
        if (!_elementDefaults.containsKey(kv.key) ||
            _elementDefaults[kv.key] != kv.value)
          kv.key: kv.value,
    };
  }

  // ── System prompt ────────────────────────────────────────────────────────────

  static String _systemPrompt() => '''
You are a MIUI lockscreen layout designer. Output ONLY a valid JSON array of LockElement objects — no markdown, no code fences, no extra text. Begin with [ and end with ].

## Canvas
Size: 276.9×600 px. Each element is a full-canvas SizedBox; dx/dy are LEFT and TOP offsets.
Content appears at center of each SizedBox (align=Alignment.center by default).
Screen position of content = (dx + 138, dy + 300).
dy=-300 = top | dy=0 = vertical center | dy=240 = swipe zone | dy=300 = bottom
dx=-138 = left edge | dx=0 = horizontal center | dx=138 = right edge

## Style → layout rules (follow these strictly based on the user's request)
- minimal/clean: NO containers. Clock fontSize 130-180, fontWeight w100-w200, white or accent text only.
- glass/frosted: containerBG + blurRadius 15-25 + color 822083583 (semi-transparent white). Clock inside at same dx,dy.
- neon/vivid: bright colored clock text (gold=4294951680, blue=4278223103, cyan=4278255615). No or minimal containers.
- analog: analogClockBg + analogHourHand + analogMinHand all at same dx,dy. Optionally inside a circular container.
- stats/info: large clock + horizontal pill container (width=360, height=72, radius=36) with battery/weather/steps inside.
- bento: 3-5 containers at varied dx,dy positions, each paired with content at the same dx,dy.
- music: music dock container + musicPrev + musicPlay + musicNext at same dy (300 = bottom area).

## Hard rules
1. LAST element MUST be: {"type":"swipeUpUnlock","dx":0,"dy":240}
2. Container + its content elements MUST share the same dx,dy (content listed AFTER container).
3. Clock colors MUST be explicit — never omit color for clock elements.
4. Max 14 elements total.

## Element types
${ElementType.values.map((e) => e.name).join(', ')}

## Colors (output as plain integers — NEVER as hex strings)
4294967295=white | 4278190080=black | 0=transparent
3435930624=white80% | 2566914048=white60% | 1711276032=white40%
822083583=glass-white(0x30) | 671088640=glass-dark(0x28) | 268435455=glass-border(0x0F)
4294951680=gold | 4278223103=blue | 4294198070=red | 4278255615=cyan

## Fields — omit any field that matches its default value
Required: type, dx, dy
Defaults (omit if equal): scale=1, height=200, width=200, radius=10, borderWidth=0, angle=0, fontSize=20, blurRadius=0, font=Roboto, text=Text, fontWeight=FontWeight.w400, isVisible=true, isLocked=false, isShort=false, isWrap=false, useSeparateColors=false
Optional only: color, colorSecondary, borderColor, colorDigit1, colorDigit2, gradientType, gradStartAlign, gradEndAlign, align, path

## Complete lockscreen templates — copy this structure quality:

[MINIMAL DARK — no containers, split clock]
[{"type":"hourClock","dx":-55,"dy":-160,"fontSize":155,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"minClock","dx":55,"dy":-160,"fontSize":155,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"dateClock","dx":0,"dy":30,"fontSize":30,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"weekClock","dx":0,"dy":72,"fontSize":18,"fontWeight":"FontWeight.w300","color":2566914048},{"type":"swipeUpUnlock","dx":0,"dy":240}]

[GLASS CLOCK — frosted card behind split clock]
[{"type":"containerBG1","dx":0,"dy":-50,"width":360,"height":260,"radius":48,"color":822083583,"blurRadius":20,"borderWidth":1,"borderColor":268435455},{"type":"hourClock","dx":-55,"dy":-80,"fontSize":130,"fontWeight":"FontWeight.w200","color":4294967295},{"type":"minClock","dx":55,"dy":-80,"fontSize":130,"fontWeight":"FontWeight.w200","color":4294967295},{"type":"dateClock","dx":0,"dy":32,"fontSize":24,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"swipeUpUnlock","dx":0,"dy":240}]

[STATS BAR — clock top + stats pill bottom]
[{"type":"hourClock","dx":-55,"dy":-130,"fontSize":145,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"minClock","dx":55,"dy":-130,"fontSize":145,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"dateClock","dx":0,"dy":30,"fontSize":26,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"containerBG1","dx":0,"dy":160,"width":350,"height":72,"radius":36,"color":671088640,"blurRadius":16,"borderWidth":1,"borderColor":268435455},{"type":"batteryLevel","dx":-100,"dy":160,"fontSize":17,"fontWeight":"FontWeight.w600","color":4294967295},{"type":"weatherTemp","dx":0,"dy":160,"fontSize":17,"fontWeight":"FontWeight.w600","color":4294967295},{"type":"stepsCount","dx":100,"dy":160,"fontSize":17,"fontWeight":"FontWeight.w600","color":4294967295},{"type":"swipeUpUnlock","dx":0,"dy":240}]

[ANALOG CLOCK — circular analog face centered]
[{"type":"containerBG1","dx":0,"dy":-50,"width":300,"height":300,"radius":150,"color":822083583,"blurRadius":20,"borderWidth":1,"borderColor":268435455},{"type":"analogClockBg","dx":0,"dy":-50,"width":260,"height":260},{"type":"analogHourHand","dx":0,"dy":-50,"width":160,"height":160},{"type":"analogMinHand","dx":0,"dy":-50,"width":180,"height":180},{"type":"dateClock","dx":0,"dy":110,"fontSize":22,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"swipeUpUnlock","dx":0,"dy":240}]

[GOLD NEON — accent-colored minimal clock]
[{"type":"hourClock","dx":-55,"dy":-160,"fontSize":155,"fontWeight":"FontWeight.w100","color":4294951680},{"type":"minClock","dx":55,"dy":-160,"fontSize":155,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"dateClock","dx":0,"dy":30,"fontSize":26,"fontWeight":"FontWeight.w300","color":4294951680},{"type":"weekClock","dx":0,"dy":68,"fontSize":16,"fontWeight":"FontWeight.w300","color":2566914048},{"type":"swipeUpUnlock","dx":0,"dy":240}]

[MUSIC + CLOCK — clock top + music dock bottom]
[{"type":"hourClock","dx":-55,"dy":-170,"fontSize":130,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"minClock","dx":55,"dy":-170,"fontSize":130,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"dateClock","dx":0,"dy":0,"fontSize":22,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"containerBG1","dx":0,"dy":155,"width":360,"height":140,"radius":28,"color":671088640,"blurRadius":20,"borderWidth":1,"borderColor":268435455},{"type":"musicBg","dx":-110,"dy":155,"scale":0.45},{"type":"musicPrev","dx":-30,"dy":155,"scale":0.5},{"type":"musicPlay","dx":30,"dy":155,"scale":0.6},{"type":"musicNext","dx":90,"dy":155,"scale":0.5},{"type":"swipeUpUnlock","dx":0,"dy":240}]
''';

  // Each variant gets a DIFFERENT structural template to adapt from — this is what ensures
  // visual diversity, not just style name hints which LLMs tend to ignore.
  static final _variantTemplates = <(String, String)>[
    (
      'MINIMAL — large split clock, NO containers',
      '[{"type":"hourClock","dx":-55,"dy":-160,"fontSize":155,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"minClock","dx":55,"dy":-160,"fontSize":155,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"dateClock","dx":0,"dy":30,"fontSize":30,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"weekClock","dx":0,"dy":72,"fontSize":18,"fontWeight":"FontWeight.w300","color":2566914048},{"type":"swipeUpUnlock","dx":0,"dy":240}]',
    ),
    (
      'GLASS — frosted card behind split clock',
      '[{"type":"containerBG1","dx":0,"dy":-50,"width":360,"height":260,"radius":48,"color":822083583,"blurRadius":20,"borderWidth":1,"borderColor":268435455},{"type":"hourClock","dx":-55,"dy":-80,"fontSize":130,"fontWeight":"FontWeight.w200","color":4294967295},{"type":"minClock","dx":55,"dy":-80,"fontSize":130,"fontWeight":"FontWeight.w200","color":4294967295},{"type":"dateClock","dx":0,"dy":32,"fontSize":24,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"swipeUpUnlock","dx":0,"dy":240}]',
    ),
    (
      'STATS BAR — clock upper half + horizontal info pill lower',
      '[{"type":"hourClock","dx":-55,"dy":-130,"fontSize":145,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"minClock","dx":55,"dy":-130,"fontSize":145,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"dateClock","dx":0,"dy":30,"fontSize":26,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"containerBG1","dx":0,"dy":160,"width":350,"height":72,"radius":36,"color":671088640,"blurRadius":16,"borderWidth":1,"borderColor":268435455},{"type":"batteryLevel","dx":-100,"dy":160,"fontSize":17,"fontWeight":"FontWeight.w600","color":4294967295},{"type":"weatherTemp","dx":0,"dy":160,"fontSize":17,"fontWeight":"FontWeight.w600","color":4294967295},{"type":"stepsCount","dx":100,"dy":160,"fontSize":17,"fontWeight":"FontWeight.w600","color":4294967295},{"type":"swipeUpUnlock","dx":0,"dy":240}]',
    ),
    (
      'ANALOG — circular analog clock as centerpiece',
      '[{"type":"containerBG1","dx":0,"dy":-50,"width":300,"height":300,"radius":150,"color":822083583,"blurRadius":20,"borderWidth":1,"borderColor":268435455},{"type":"analogClockBg","dx":0,"dy":-50,"width":260,"height":260},{"type":"analogHourHand","dx":0,"dy":-50,"width":160,"height":160},{"type":"analogMinHand","dx":0,"dy":-50,"width":180,"height":180},{"type":"dateClock","dx":0,"dy":110,"fontSize":22,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"swipeUpUnlock","dx":0,"dy":240}]',
    ),
    (
      'MUSIC + CLOCK — split clock top + music player dock bottom',
      '[{"type":"hourClock","dx":-55,"dy":-170,"fontSize":130,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"minClock","dx":55,"dy":-170,"fontSize":130,"fontWeight":"FontWeight.w100","color":4294967295},{"type":"dateClock","dx":0,"dy":0,"fontSize":22,"fontWeight":"FontWeight.w300","color":3435930624},{"type":"containerBG1","dx":0,"dy":155,"width":360,"height":140,"radius":28,"color":671088640,"blurRadius":20,"borderWidth":1,"borderColor":268435455},{"type":"musicBg","dx":-110,"dy":155,"scale":0.45},{"type":"musicPrev","dx":-30,"dy":155,"scale":0.5},{"type":"musicPlay","dx":30,"dy":155,"scale":0.6},{"type":"musicNext","dx":90,"dy":155,"scale":0.5},{"type":"swipeUpUnlock","dx":0,"dy":240}]',
    ),
  ];

  static String _userPrompt(String request, List<LockElement> current) {
    if (current.isEmpty) {
      return 'Design a MIUI lockscreen: $request\n\nReturn ONLY a JSON array.';
    }
    final compact = jsonEncode(current.map(_compact).toList());
    return 'Design a MIUI lockscreen: $request\n\n'
        'Style reference (adapt this style into a fresh layout — do not copy values verbatim):\n$compact\n\n'
        'Return ONLY a JSON array.';
  }

  static String _variantPrompt(String request, int index) {
    final (styleName, template) = _variantTemplates[index % _variantTemplates.length];
    return 'Design a MIUI lockscreen: $request\n\n'
        'BASE TEMPLATE ($styleName):\n$template\n\n'
        'INSTRUCTIONS: Adapt the template above to match the user request. '
        'Keep the same element types. Vary colors to fit the mood, '
        'adjust font sizes by up to ±30, shift dy positions by up to ±50. '
        'Do NOT copy the template verbatim — produce a fresh variation.\n\n'
        'Return ONLY a JSON array.';
  }

  // ── Provider-specific callers ────────────────────────────────────────────────

  Future<String> _callGemini(String userText) async {
    const model = AppConstants.geminiModel;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey',
    );
    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt()}
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userText}
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 1.2,
        'maxOutputTokens': 8192,
      },
    });

    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode != 200) throw Exception(res.body);

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final text = (((json['candidates'] as List?)?.first
            as Map?)?['content'] as Map?)?['parts']
        ?.first['text'] as String?;
    if (text == null || text.trim().isEmpty) throw Exception('Empty AI response');
    return text;
  }

  Future<String> _callGroq(String userText) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final body = jsonEncode({
      'model': AppConstants.groqModel,
      'messages': [
        {'role': 'system', 'content': _systemPrompt()},
        {'role': 'user', 'content': userText},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 1.2,
    });

    final res = await http.post(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $groqKey',
    }, body: body);
    if (res.statusCode != 200) throw Exception(res.body);

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final text = ((json['choices'] as List?)?.first
        as Map?)?['message']?['content'] as String?;
    if (text == null || text.trim().isEmpty) throw Exception('Empty AI response');
    return text;
  }

  Future<String> _callOllama(String userText) async {
    final uri = Uri.parse('$ollamaHost/api/chat');
    final body = jsonEncode({
      'model': ollamaModel,
      'messages': [
        {'role': 'system', 'content': _systemPrompt()},
        {'role': 'user', 'content': userText},
      ],
      'format': 'json',
      'stream': false,
    });

    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
        // Ollama can be slow on first run; give it 3 minutes
        ).timeout(const Duration(minutes: 3));
    if (res.statusCode != 200) throw Exception(res.body);

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final text = (json['message'] as Map?)?['content'] as String?;
    if (text == null || text.trim().isEmpty) throw Exception('Empty AI response');
    return text;
  }

  // ── Dispatch + retry ─────────────────────────────────────────────────────────

  String get _providerLabel => switch (provider) {
        AiProvider.gemini => 'Gemini(${AppConstants.geminiModel})',
        AiProvider.groq   => 'Groq(${AppConstants.groqModel})',
        AiProvider.ollama => 'Ollama($ollamaModel)',
      };

  Future<String> _dispatch(String userText) => switch (provider) {
        AiProvider.gemini => _callGemini(userText),
        AiProvider.groq   => _callGroq(userText),
        AiProvider.ollama => _callOllama(userText),
      };

  static bool _isRateLimit(Object e) {
    final s = e.toString();
    return s.contains('RESOURCE_EXHAUSTED') ||
        s.contains('"code": 429') ||
        s.contains('"code":429') ||
        s.contains('rate_limit_exceeded'); // Groq: "code":"rate_limit_exceeded"
  }

  /// Parses "try again in X.Xs" from Groq errors; falls back to [10, 30, 60].
  static int _retryDelaySecs(Object e, int attempt) {
    final match =
        RegExp(r'try again in (\d+(?:\.\d+)?)s').firstMatch(e.toString());
    if (match != null) {
      final secs = double.tryParse(match.group(1) ?? '');
      if (secs != null) return (secs + 3).ceil(); // +3 s buffer
    }
    const fallback = [10, 30, 60];
    return fallback[attempt.clamp(0, fallback.length - 1)];
  }

  Future<String> _callWithRetry(String userText) async {
    const maxAttempts = 4;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await _dispatch(userText);
      } catch (e) {
        if (_isRateLimit(e) && attempt < maxAttempts - 1) {
          final delay = _retryDelaySecs(e, attempt);
          dev.log(
            'AI: rate limited — retry in ${delay}s '
            '(attempt ${attempt + 1}/$maxAttempts)',
            name: 'AiDs',
          );
          await Future.delayed(Duration(seconds: delay));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }

  // ── Parsing ──────────────────────────────────────────────────────────────────

  static List<LockElement> _parse(String text) {
    if (text.trim().isEmpty) throw Exception('Empty AI response');
    var s = text.trim();

    // Groq json_object wraps in {"elements":[...]} sometimes
    if (s.startsWith('{')) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      // Find the first List value
      final listVal = map.values.whereType<List>().firstOrNull;
      if (listVal != null) {
        return listVal
            .map((e) => LockElement.fromJson(_sanitize(e as Map<String, dynamic>)))
            .toList();
      }
    }

    // Strip markdown code fences
    if (s.startsWith('```')) {
      final nl = s.indexOf('\n');
      if (nl != -1) s = s.substring(nl + 1);
      final fence = s.lastIndexOf('```');
      if (fence != -1) s = s.substring(0, fence).trim();
    }

    // Locate array bounds
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start != -1 && end > start) s = s.substring(start, end + 1);

    final list = jsonDecode(s) as List<dynamic>;
    return list
        .map((e) => LockElement.fromJson(_sanitize(e as Map<String, dynamic>)))
        .toList();
  }

  // ── Type sanitizer ───────────────────────────────────────────────────────────
  // LLMs often return color integers as hex strings ("0xFF123456").
  // This coerces them back to the types fromJson expects.

  static const _colorKeys = {
    'borderColor', 'color', 'colorSecondary', 'colorDigit1', 'colorDigit2',
  };
  static const _numKeys = {
    'dx', 'dy', 'scale', 'height', 'width', 'radius', 'borderWidth',
    'angle', 'fontSize', 'blurRadius',
  };
  static const _boolKeys = {
    'isShort', 'isWrap', 'showGuideLines', 'isVisible', 'isLocked',
    'useSeparateColors',
  };

  static Map<String, dynamic> _sanitize(Map<String, dynamic> j) => {
        for (final kv in j.entries) kv.key: _coerce(kv.key, kv.value),
      };

  static dynamic _coerce(String key, dynamic value) {
    if (_colorKeys.contains(key))  return _toColorInt(value);
    if (_numKeys.contains(key))    return _toDouble(value);
    if (_boolKeys.contains(key))   return _toBool(value);
    return value;
  }

  static int _toColorInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final s = v.trim();
      if (s.startsWith('0x') || s.startsWith('0X')) {
        return int.tryParse(s.substring(2), radix: 16) ?? 0xFFFFFFFF;
      }
      if (s.startsWith('#')) {
        final hex = s.substring(1);
        if (hex.length == 6) return int.tryParse('FF$hex', radix: 16) ?? 0xFFFFFFFF;
        if (hex.length == 8) return int.tryParse(hex, radix: 16) ?? 0xFFFFFFFF;
      }
      return int.tryParse(s) ?? 0xFFFFFFFF;
    }
    return 0xFFFFFFFF;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<List<LockElement>> generateLockscreen({
    required List<LockElement> currentElements,
    required String prompt,
  }) async {
    dev.log('AI[$_providerLabel]: generateLockscreen "$prompt"', name: 'AiDs');
    try {
      final text = await _callWithRetry(_userPrompt(prompt, currentElements));
      final elements = _parse(text);
      dev.log('AI: parsed ${elements.length} elements', name: 'AiDs');
      return elements;
    } catch (e, st) {
      dev.log('AI: failed', name: 'AiDs', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<List<LockElement>>> generateVariants({
    required List<LockElement> currentElements,
    required String prompt,
    required int count,
  }) async {
    dev.log('AI[$_providerLabel]: generating $count variants for "$prompt"',
        name: 'AiDs');
    final variants = <List<LockElement>>[];

    for (int i = 0; i < count; i++) {
      try {
        final text = await _callWithRetry(_variantPrompt(prompt, i));
        final elements = _parse(text);
        dev.log('AI: variant ${i + 1} → ${elements.length} elements',
            name: 'AiDs');
        variants.add(elements);
      } catch (e, st) {
        dev.log('AI: variant ${i + 1} failed', name: 'AiDs', error: e, stackTrace: st);
        rethrow;
      }
    }

    dev.log('AI: ${variants.length}/$count succeeded', name: 'AiDs');
    return variants;
  }

  /// Lists Gemini models that support generateContent (v1beta).
  Future<List<String>> listGeminiModels() async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$geminiKey',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception(res.body);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final models = json['models'] as List<dynamic>? ?? [];
    return models
        .where((m) {
          final methods =
              (m['supportedGenerationMethods'] as List?)?.cast<String>() ?? [];
          return methods.contains('generateContent');
        })
        .map((m) => (m['name'] as String).replaceFirst('models/', ''))
        .toList()
      ..sort();
  }

  /// Returns model names installed in the local Ollama instance.
  Future<List<String>> listOllamaModels() async {
    final uri = Uri.parse('$ollamaHost/api/tags');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception(res.body);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final models = json['models'] as List<dynamic>? ?? [];
    return models
        .map((m) => (m['name'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();
  }

  // ── Unused stubs ─────────────────────────────────────────────────────────────

  Future<List<ColorEntry>?> generatePalette(String prompt) async => null;
  Future<String?> suggestIconStyle(IconVariant current) async => null;
  Stream<String> streamChat(String userMessage, ThemeProject context) =>
      Stream.value('Response');
}
