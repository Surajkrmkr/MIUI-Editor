import 'dart:io';

import 'package:theme_core/theme_core.dart';

/// Packs the theme folder into a `.mtz`.
///
/// With [dualVersion] it also builds a HyperOS 1 variant, a legacy option the
/// HyperOS 3 build in theme_core doesn't know about:
///   - `<name>_V1.mtz` with uiVersion 15
///   - `<name>_V3.mtz` with uiVersion 17
class ExportMtzUseCase {
  const ExportMtzUseCase();

  static const _packager = MtzPackager();

  Future<(String?, Failure?)> call({
    required ThemeLayout layout,
    required String themeName,
    bool dualVersion = false,
  }) async {
    if (!dualVersion) {
      return _packager.pack(layout: layout, name: themeName);
    }

    final descFile = File(layout.descriptionXml);
    final original = descFile.existsSync()
        ? await descFile.readAsString()
        : null;
    for (final (suffix, uiVersion) in const [('_V1', '15'), ('_V3', '17')]) {
      final (_, failure) = await _packager.pack(
        layout: layout,
        name: '$themeName$suffix',
        descriptionXml: original?.replaceFirst(
          RegExp(r'<uiVersion>[^<]*</uiVersion>'),
          '<uiVersion>$uiVersion</uiVersion>',
        ),
      );
      if (failure != null) return (null, failure);
    }
    return (layout.parentDir, null);
  }
}
