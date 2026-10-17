import '../values/rgba.dart';
import 'spec_issue.dart';

/// Typed access to a JSON node that records problems with their path instead
/// of throwing, so one pass can report everything wrong with a spec.
class JsonReader {
  JsonReader(this.node, this.path, this.issues);

  final Object? node;
  final String path;
  final List<SpecIssue> issues;

  Map<String, dynamic>? get _map => node is Map<String, dynamic>
      ? node as Map<String, dynamic>
      : node is Map
      ? Map<String, dynamic>.from(node as Map)
      : null;

  void _issue(String code, String at, String message, {String? hint}) =>
      issues.add(SpecIssue(code: code, path: at, message: message, hint: hint));

  /// This node as an object, or null (and an issue) when it isn't one.
  /// A missing node is only an issue when [required].
  Map<String, dynamic>? object({bool required = false}) {
    if (node == null) {
      if (required) {
        _issue('spec.missing', path, 'Required object is missing.');
      }
      return null;
    }
    final m = _map;
    if (m == null) _issue('spec.type', path, 'Expected an object.');
    return m;
  }

  void _missingIf(bool required, String key) {
    if (required) {
      _issue('spec.missing', _at(key), 'Required value is missing.');
    }
  }

  JsonReader child(String key) => JsonReader(_map?[key], '$path/$key', issues);

  String _at(String key) => '$path/$key';

  bool has(String key) => _map?.containsKey(key) == true && _map![key] != null;

  String? string(String key, {bool required = false}) {
    final v = _map?[key];
    if (v == null) {
      _missingIf(required, key);
      return null;
    }
    if (v is! String) {
      _issue('spec.type', _at(key), 'Expected a string.');
      return null;
    }
    if (required && v.trim().isEmpty) {
      _issue('spec.empty', _at(key), 'Must not be empty.');
    }
    return v;
  }

  double? number(String key, {bool required = false}) {
    final v = _map?[key];
    if (v == null) {
      _missingIf(required, key);
      return null;
    }
    if (v is! num) {
      _issue('spec.type', _at(key), 'Expected a number.');
      return null;
    }
    return v.toDouble();
  }

  int? integer(String key, {bool required = false}) {
    final v = _map?[key];
    if (v == null) {
      _missingIf(required, key);
      return null;
    }
    if (v is! int) {
      _issue('spec.type', _at(key), 'Expected a whole number.');
      return null;
    }
    return v;
  }

  bool? boolean(String key) {
    final v = _map?[key];
    if (v == null) return null;
    if (v is! bool) {
      _issue('spec.type', _at(key), 'Expected true or false.');
      return null;
    }
    return v;
  }

  Rgba? color(String key, {bool required = false}) {
    final v = _map?[key];
    if (v == null) {
      _missingIf(required, key);
      return null;
    }
    final c = Rgba.tryParse(v);
    if (c == null) {
      _issue(
        'spec.color',
        _at(key),
        'Not a valid color: $v',
        hint: 'Use "#RRGGBB" or "#AARRGGBB".',
      );
    }
    return c;
  }

  List<Rgba>? colors(String key) {
    final v = _map?[key];
    if (v == null) return null;
    if (v is! List) {
      _issue('spec.type', _at(key), 'Expected a list of colors.');
      return null;
    }
    final out = <Rgba>[];
    for (var i = 0; i < v.length; i++) {
      final c = Rgba.tryParse(v[i]);
      if (c == null) {
        _issue(
          'spec.color',
          '${_at(key)}/$i',
          'Not a valid color: ${v[i]}',
          hint: 'Use "#RRGGBB" or "#AARRGGBB".',
        );
      } else {
        out.add(c);
      }
    }
    return out;
  }

  T? enumValue<T extends Enum>(
    String key,
    List<T> values, {
    bool required = false,
  }) {
    final v = _map?[key];
    if (v == null) {
      _missingIf(required, key);
      return null;
    }
    for (final e in values) {
      if (e.name == v) return e;
    }
    _issue(
      'spec.enum',
      _at(key),
      'Unknown value "$v".',
      hint: 'Allowed: ${values.map((e) => e.name).join(', ')}.',
    );
    return null;
  }

  List<Object?>? list(String key) {
    final v = _map?[key];
    if (v == null) return null;
    if (v is! List) {
      _issue('spec.type', _at(key), 'Expected a list.');
      return null;
    }
    return v;
  }

  /// Warns about keys the reader doesn't know, which usually means a typo.
  void warnUnknownKeys(Set<String> known) {
    for (final k in _map?.keys ?? const <String>[]) {
      if (!known.contains(k)) {
        warn(
          'spec.unknown_key',
          _at(k),
          'Unknown key "$k"; it will be ignored.',
          hint: 'Known keys: ${(known.toList()..sort()).join(', ')}.',
        );
      }
    }
  }

  /// Issues recorded with severity warning rather than error.
  void warn(String code, String at, String message, {String? hint}) =>
      issues.add(
        SpecIssue(
          code: code,
          path: at,
          message: message,
          hint: hint,
          severity: IssueSeverity.warning,
        ),
      );
}
