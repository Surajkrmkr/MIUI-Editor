import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:theme_core/theme_core.dart' show themeUserOf;
import '../../core/errors/failures.dart';
import '../../domain/entities/widget_style.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/widget_style_repository.dart';

class WidgetStyleRepositoryImpl implements WidgetStyleRepository {
  const WidgetStyleRepositoryImpl(this.directory);
  final String directory;
  static const format = 'miui-editor.widget-style-set';
  static const version = 1;
  static const maxFileBytes = 20 * 1024 * 1024;

  Future<WidgetStyleSet> _read(String path) async {
    final file = File(path);
    if (await file.length() > maxFileBytes) {
      throw const FormatException('Style set exceeds 20 MB');
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (json['format'] != format || json['version'] != version) {
      throw const FormatException('Unsupported style set format or version');
    }
    final entries = json['styles'] as List<dynamic>;
    if (entries.isEmpty || entries.length > 256) {
      throw const FormatException('Invalid style count');
    }
    final styles = <WidgetStyle>[];
    for (final value in entries) {
      final entry = Map<String, dynamic>.from(value as Map);
      final appearance = Map<String, dynamic>.from(entry['appearance'] as Map);
      if ((appearance['unlockIconPath'] as String? ?? '').isNotEmpty) {
        throw const FormatException(
          'External image paths are not allowed in style sets',
        );
      }
      final type = ElementType.values.byName(entry['type'] as String);
      final style = WidgetStyle(
        id: entry['id'] as String,
        name: entry['name'] as String,
        type: type,
        appearance: appearance,
      );
      if (appearance['unlockIcon'] == UnlockIcon.customPng.name) {
        final encoded = entry['iconPng'] as String?;
        if (encoded == null || encoded.length > 12 * 1024 * 1024) {
          throw const FormatException('Missing or oversized PNG icon');
        }
        final bytes = base64Decode(encoded);
        await _validatePng(bytes);
      }
      styles.add(style);
    }
    return WidgetStyleSet(
      id: json['id'] as String,
      name: json['name'] as String,
      styles: styles,
      user: themeUserOf(json['user']),
    );
  }

  Future<void> _validatePng(Uint8List bytes) async {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 24 ||
        bytes.length > 8 * 1024 * 1024 ||
        !List.generate(
          8,
          (index) => bytes[index] == signature[index],
        ).every((value) => value)) {
      throw const FormatException(
        'Style icons must be PNG files of at most 8 MB',
      );
    }
    final header = ByteData.sublistView(bytes);
    final width = header.getUint32(16);
    final height = header.getUint32(20);
    if (width == 0 || height == 0 || width > 4096 || height > 4096) {
      throw const FormatException(
        'Style PNG dimensions must be between 1 and 4096 pixels',
      );
    }
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1,
      targetHeight: 1,
    );
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  }

  Future<Map<String, dynamic>> _encode(WidgetStyleSet set) async {
    final styles = <Map<String, dynamic>>[];
    for (final style in set.styles) {
      final appearance = {...style.appearance}..remove('unlockIconPath');
      final entry = <String, dynamic>{
        'id': style.id,
        'name': style.name,
        'type': style.type.name,
        'appearance': appearance,
      };
      if (style.appearance['unlockIcon'] == UnlockIcon.customPng.name) {
        final path = style.appearance['unlockIconPath'] as String? ?? '';
        final file = File(path);
        if (path.isEmpty ||
            !await file.exists() ||
            await file.length() > 8 * 1024 * 1024) {
          throw const FormatException(
            'Choose an available PNG icon before saving the style',
          );
        }
        final bytes = await file.readAsBytes();
        await _validatePng(bytes);
        entry['iconPng'] = base64Encode(bytes);
      }
      styles.add(entry);
    }
    return {
      'format': format,
      'version': version,
      'id': set.id,
      'name': set.name,
      if (set.user != null) 'user': set.user,
      'styles': styles,
    };
  }

  Future<WidgetStyleSet> _materialize(String path, WidgetStyleSet set) async {
    final json =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    final entries = json['styles'] as List<dynamic>;
    final styles = <WidgetStyle>[];
    for (var index = 0; index < set.styles.length; index++) {
      final style = set.styles[index];
      var appearance = style.appearance;
      if (appearance['unlockIcon'] == UnlockIcon.customPng.name) {
        final file = File('$directory/assets/${set.id}/${style.id}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
          base64Decode(entries[index]['iconPng'] as String),
        );
        appearance = {...appearance, 'unlockIconPath': file.path};
      }
      styles.add(
        WidgetStyle(
          id: style.id,
          name: style.name,
          type: style.type,
          appearance: appearance,
        ),
      );
    }
    return WidgetStyleSet(
      id: set.id,
      name: set.name,
      styles: styles,
      user: set.user,
    );
  }

  @override
  Future<(List<WidgetStyleSet>, Failure?)> load() async {
    try {
      final root = Directory(directory);
      if (!await root.exists()) return (<WidgetStyleSet>[], null);
      final files =
          (await root.list().toList())
              .whereType<File>()
              .where((file) => file.path.endsWith('.json'))
              .toList()
            ..sort((first, second) => first.path.compareTo(second.path));
      final sets = <WidgetStyleSet>[];
      for (final file in files) {
        final set = await _read(file.path);
        sets.add(await _materialize(file.path, set));
      }
      return (sets, null);
    } catch (error) {
      return (
        <WidgetStyleSet>[],
        FileFailure('Could not load widget styles: $error'),
      );
    }
  }

  @override
  Future<Failure?> save(WidgetStyleSet set) async {
    try {
      final contents = jsonEncode(await _encode(set));
      if (utf8.encode(contents).length > maxFileBytes) {
        throw const FormatException('Style set exceeds 20 MB');
      }
      final file = File('$directory/${set.id}.json');
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(contents, flush: true);
      await temporary.rename(file.path);
      return null;
    } catch (error) {
      return FileFailure('Could not save widget styles: $error');
    }
  }

  @override
  Future<Failure?> delete(String id) async {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$').hasMatch(id)) {
      return const ValidationFailure('Invalid style set ID');
    }
    try {
      final file = File('$directory/$id.json');
      if (await file.exists()) await file.delete();
      return null;
    } catch (error) {
      return FileFailure('Could not delete style set: $error');
    }
  }

  @override
  Future<(WidgetStyleSet?, Failure?)> importSet(String path) async {
    try {
      var set = await _read(path);
      if (set.id.startsWith('builtin-') ||
          await File('$directory/${set.id}.json').exists()) {
        set = WidgetStyleSet(
          id: 'imported-${DateTime.now().microsecondsSinceEpoch}',
          name: set.name,
          styles: set.styles,
          user: set.user,
        );
      }
      set = await _materialize(path, set);
      final failure = await save(set);
      return failure == null ? (set, null) : (null, failure);
    } catch (error) {
      return (
        null,
        ValidationFailure('Could not import widget styles: $error'),
      );
    }
  }

  @override
  Future<Failure?> exportSet(WidgetStyleSet set, String path) async {
    try {
      final contents = const JsonEncoder.withIndent(
        '  ',
      ).convert(await _encode(set));
      if (utf8.encode(contents).length > maxFileBytes) {
        throw const FormatException('Style set exceeds 20 MB');
      }
      await File(path).writeAsString(contents);
      return null;
    } catch (error) {
      return FileFailure('Could not export widget styles: $error');
    }
  }
}
