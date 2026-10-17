import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/preset_repository.dart';

class PresetRepositoryImpl implements PresetRepository {
  @override
  Future<Failure?> save(
    String presetName,
    List<LockElement> elements, {
    Uint8List? previewBytes,
  }) async {
    try {
      final base = '${PathConstants.presetPath}$presetName${PathConstants.sep}';
      final jsonPath = PathConstants.p('${base}preset.json');
      final previewPath = PathConstants.p('${base}preview.png');

      final dir = Directory(PathConstants.p(base));
      await dir.create(recursive: true);

      final assets = <String, Uint8List>{};
      for (final element in elements) {
        for (final source in [
          element.unlockIconPath,
          element.unlockTargetPath,
        ]) {
          if (source.isNotEmpty && !assets.containsKey(source)) {
            assets[source] = await File(source).readAsBytes();
          }
        }
      }
      final saved = <LockElement>[];
      for (var index = 0; index < elements.length; index++) {
        final element = elements[index];
        Future<String> bundle(String source, String kind) async {
          if (source.isEmpty) return '';
          final relative = 'assets/element_${index}_$kind.png';
          final destination = File(path.join(dir.path, relative));
          await destination.parent.create(recursive: true);
          await destination.writeAsBytes(assets[source]!);
          return relative;
        }

        saved.add(
          element.copyWith(
            unlockIconPath: await bundle(element.unlockIconPath, 'icon'),
            unlockTargetPath: await bundle(element.unlockTargetPath, 'target'),
          ),
        );
      }

      await File(
        jsonPath,
      ).writeAsString(jsonEncode(saved.map((e) => e.toJson()).toList()));

      if (previewBytes != null) {
        await File(previewPath).writeAsBytes(previewBytes);
      }

      return null;
    } catch (e) {
      return FileFailure(e.toString());
    }
  }

  @override
  Future<(List<LockElement>?, Failure?)> load(String jsonPath) async {
    try {
      final raw = await File(jsonPath).readAsString();
      final base = path.dirname(path.absolute(jsonPath));
      String resolve(String value) {
        if (value.isEmpty || path.isAbsolute(value)) return value;
        final resolved = path.normalize(path.join(base, value));
        if (!path.isWithin(base, resolved)) {
          throw const FormatException('Preset asset escapes its directory');
        }
        return resolved;
      }

      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => LockElement.fromJson(e as Map<String, dynamic>))
          .map(
            (element) => element.copyWith(
              unlockIconPath: resolve(element.unlockIconPath),
              unlockTargetPath: resolve(element.unlockTargetPath),
            ),
          )
          .toList();
      return (list, null);
    } catch (e) {
      return (null, FileFailure(e.toString()));
    }
  }

  @override
  Future<(List<String>, Failure?)> listPaths() async {
    try {
      final dir = Directory(PathConstants.presetPath);
      if (!await dir.exists()) return (const <String>[], null);
      final entities = (await dir.list().toList());

      final dirs = entities.whereType<Directory>().toList();
      // Sort by last modified time (most recent first)
      dirs.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      final paths = dirs.map((d) => d.path).toList();
      return (paths, null);
    } catch (e) {
      return (const <String>[], FileFailure(e.toString()));
    }
  }
}
