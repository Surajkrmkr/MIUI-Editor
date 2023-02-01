import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';
import '../functions/windows_utils.dart';
import '../widgets/ui_widgets.dart';

class MTZProvider extends ChangeNotifier {
  bool? isExporting = true;

  set setIsExporting(bool val) {
    isExporting = val;
    notifyListeners();
  }

  void export({BuildContext? context}) async {
    setIsExporting = true;
    final themePath = CurrentTheme.getPath(context);
    final themeName = CurrentTheme.getCurrentThemeName(context);
    var encoder = ZipFileEncoder();
    try {
      final descFile = platformBasedPath("${themePath!}\\description.xml");
      final pluginInfoFile = platformBasedPath("$themePath\\plugin_config.xml");
      final wallDir = Directory(platformBasedPath("$themePath\\wallpaper"));

      encoder.create(platformBasedPath(
          "${Directory(themePath).parent.path}\\$themeName.mtz"));
      encoder.addFile(File(descFile));
      encoder.addFile(File(pluginInfoFile));
      encoder.addDirectory(wallDir);

      for (String? path in MIUIThemeData.mtzModuleList) {
        final zipPath = await compressModule(
            themePath, path!.replaceAll(Platform.isWindows ? '\\' : "/", ''));
        if (zipPath!.isEmpty) {
          throw Exception("error occured");
        }
        await encoder.addFile(File(zipPath));
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        UIWidgets.getBanner(
            content: "$themeName.mtz exported",
            context: context,
            hasError: false);
      });
    } catch (e) {
      UIWidgets.getBanner(
          content: e.toString(), context: context, hasError: true);
    } finally {
      encoder.close();
      setIsExporting = false;
      Directory(platformBasedPath("$themePath\\temp")).exists().then((value) {
        if (value) {
          Directory(platformBasedPath("$themePath\\temp"))
              .delete(recursive: true);
        }
      });
    }
  }

  Future<String?> compressModule(String? path, String? moduleName) async {
    var encoder = ZipFileEncoder();
    encoder.create(platformBasedPath("${path!}\\temp\\$moduleName"));
    await encoder.addDirectory(
        Directory(platformBasedPath("$path\\$moduleName")),
        includeDirName: false);
    final zipPath = encoder.zipPath;
    encoder.close();
    return zipPath;
  }
}

class ExportMTZBtn extends StatelessWidget {
  const ExportMTZBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return UIWidgets.getElevatedButton(
        icon: const Icon(Icons.archive),
        onTap: () => Provider.of<MTZProvider>(context, listen: false)
            .export(context: context),
        text: "MTZ");
  }
}
