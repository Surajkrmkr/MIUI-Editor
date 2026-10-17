import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';

import 'fixtures/lock_elements.dart';

/// Pins the LockElement JSON contract (presets, AI output, spec). Regenerate
/// with `UPDATE_GOLDENS=1 flutter test`.
const _goldenPath = 'test/theme_editor/goldens/lock_element_json.json';

Map<String, Object?> _snapshot() => {
  'kitchenSink': kitchenSink.toJson(),
  'default': const LockElement(type: ElementType.hourClock).toJson(),
  'types': [for (final t in ElementType.values) t.name],
};

void main() {
  test('LockElement JSON matches the golden', () {
    final actual = jsonDecode(jsonEncode(_snapshot()));
    final golden = File(_goldenPath);
    if (Platform.environment['UPDATE_GOLDENS'] == '1' || !golden.existsSync()) {
      golden.parent.createSync(recursive: true);
      golden.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(actual)}\n',
      );
      return;
    }
    expect(actual, jsonDecode(golden.readAsStringSync()));
  });

  test('fromJson(toJson) is stable for the kitchen sink and every type', () {
    for (final e in [
      kitchenSink,
      for (final t in ElementType.values) LockElement(type: t),
    ]) {
      final json = jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>;
      expect(LockElement.fromJson(json).toJson(), json, reason: e.name);
    }
  });
}
