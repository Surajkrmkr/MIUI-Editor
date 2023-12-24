import 'dart:io';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/screen/landing/export.dart';
import 'package:miui_icon_generator/screen/landing/widgets/folder_week_options.dart';
import 'package:provider/provider.dart';

import '../../provider/directory.dart';
import '../../widgets/ui_widgets.dart';
import 'widgets/pick_walls.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      final provider = Provider.of<DirectoryProvider>(context, listen: false);
      provider
        ..getPreLockCount()
        ..setPreviewWallsPath(folderNum: "1");
    });
    super.initState();
  }

  void showSettingsDialog(BuildContext context) {
    UIWidgets.dialog(context: context, child: const Settings());
  }

  void onWallPickClicked(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const PickWalls(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Consumer<DirectoryProvider>(builder: (context, provider, _) {
                  if (provider.isLoadingPrelockCount!) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.preLockPaths.isEmpty) {
                    return Text(
                      "NO FOLDER AVAILABLE",
                      style: Theme.of(context).textTheme.bodyLarge,
                    );
                  }
                  return Platform.isAndroid
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PreviewWeekWalls(provider: provider),
                            FolderWeekOptions(provider: provider),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FolderWeekOptions(provider: provider),
                            PreviewWeekWalls(provider: provider)
                          ],
                        );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
        title: const Text("Welcome to MIUI World", textAlign: TextAlign.center),
        actions: [
          UIWidgets.iconButton(
              onPressed: () => showSettingsDialog(context),
              icon: Icons.settings),
          UIWidgets.iconButton(
              onPressed: () => onWallPickClicked(context),
              icon: Icons.wallpaper),
          const SizedBox(width: 20)
        ]);
  }
}
