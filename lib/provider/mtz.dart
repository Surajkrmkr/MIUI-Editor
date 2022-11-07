import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';
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
    final descFile = "${themePath!}\\description.xml";
    final pluginInfoFile = "$themePath\\plugin_config.xml";
    final wallDir = Directory("$themePath\\wallpaper");
    var encoder = ZipFileEncoder();
    try {
      encoder.create("${Directory(themePath).parent.path}\\$themeName.mtz");
      encoder.addFile(File(descFile));
      encoder.addFile(File(pluginInfoFile));
      encoder.addDirectory(wallDir);
      for (String? path in MIUIThemeData.mtzModuleList) {
        final zipPath =
            await compressModule(themePath, path!.replaceAll('\\', ''));
        await encoder.addFile(File(zipPath!));
      }
      UIWidgets.getBanner(
          content: "$themeName.mtz exported",
          context: context,
          hasError: false);
    } catch (e) {
      UIWidgets.getBanner(
          content: e.toString(), context: context, hasError: true);
    } finally {
      encoder.close();
      setIsExporting = false;
      Directory("$themePath\\temp").exists().then((value) {
        if (value) {
          Directory("$themePath\\temp").delete(recursive: true);
        }
      });
    }
  }

  Future<String?> compressModule(String? path, String? moduleName) async {
    var encoder = ZipFileEncoder();
    encoder.create("${path!}\\temp\\$moduleName");
    await encoder.addDirectory(Directory("$path\\$moduleName"),
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
    return SizedBox(
      width: 190,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 23, horizontal: 35)),
          onPressed: () {
            Provider.of<MTZProvider>(context, listen: false)
                .export(context: context);
          },
          child: const Text("MTZ")),
    );
  }
}
