import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:download_task/download_task.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../../../provider/directory.dart';
import '../../../provider/tag.dart';
import '../../../provider/wallpaper.dart';
import '../../../widgets/tags.dart';
import '../../../widgets/ui_widgets.dart';

class CropWalls extends StatefulWidget {
  const CropWalls({super.key, required this.file});
  final File file;

  @override
  State<CropWalls> createState() => _CropWallsState();
}

class _CropWallsState extends State<CropWalls> {
  final CropController cropController = CropController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Wall"),
        actions: [
          UIWidgets.iconButton(
              onPressed: () {
                cropController.crop();
              },
              icon: Icons.crop),
          const SizedBox(width: 20)
        ],
      ),
      body: Crop(
        aspectRatio: 6 / 13,
        image: widget.file.readAsBytesSync(),
        controller: cropController,
        onCropped: (image) async {
          img.Image decodedImage = img.decodeImage(image)!;
          img.Image thumbnail = img.copyResize(decodedImage, width: 1080);
          File(widget.file.path).writeAsBytesSync(img.encodeJpg(thumbnail));
          Provider.of<DirectoryProvider>(context, listen: false)
              .setPreviewWallsPath(
                  folderNum:
                      Provider.of<WallpaperProvider>(context, listen: false)
                          .folderNum);
          Navigator.of(context)
            ..pop()
            ..pop();
        },
      ),
    );
  }
}

class RenameWall extends StatefulWidget {
  const RenameWall(
      {super.key,
      required this.downloadUrl,
      required this.pageUrl,
      required this.tags});

  final String downloadUrl;
  final String pageUrl;
  final String tags;

  @override
  State<RenameWall> createState() => _RenameWallState();
}

class _RenameWallState extends State<RenameWall> {
  int currentStep = 0;
  final TextEditingController controller = TextEditingController();
  List<String> tags = [];

  @override
  void initState() {
    extractTags();
    super.initState();
  }

  void extractTags() {
    final pixabayTags =
        widget.tags.split(",").map((e) => e.toLowerCase().trim()).toList();
    final allTags = Provider.of<TagProvider>(context, listen: false)
        .flatTagList
        .map((e) => e.toLowerCase().trim())
        .toList();
    for (final tag in pixabayTags) {
      if (allTags.contains(tag)) {
        tags.add(tag);
      }
    }
    if (tags.isEmpty) {
      tags = ["Simple", "Abstract", "Clock", "cool", "Regular", "Slide"];
    }
  }

  void _onInfoSubmit() async {
    await Provider.of<WallpaperProvider>(context, listen: false)
        .downloadWallpaper(widget.downloadUrl, controller.text);
    Provider.of<WallpaperProvider>(context, listen: false)
        .makeCopyrightZip(widget.pageUrl, controller.text, context);
    Provider.of<WallpaperProvider>(context, listen: false)
        .task!
        .events
        .listen((event) async {
      if (event.state == TaskState.success) {
        final file =
            Provider.of<WallpaperProvider>(context, listen: false).task!.file;
        if (widget.downloadUrl.endsWith(".png")) {
          final image = img.decodeImage(await file.readAsBytes())!;
          await File(file.path).writeAsBytes(img.encodeJpg(image));
        }
        Provider.of<WallpaperProvider>(context, listen: false)
            .setIsDownloading = false;
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return CropWalls(file: file);
        }));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Row(
          children: [Text("Give wall a name"), Spacer(), CloseButton()],
        ),
        content: SizedBox(
          height: 600,
          width: 400,
          child: Row(
            children: [
              Expanded(
                child: Stepper(
                    controlsBuilder: (BuildContext context,
                        ControlsDetails controlsDetails) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: <Widget>[
                            UIWidgets.getElevatedButton(
                                isLoading: Provider.of<WallpaperProvider>(
                                        context,
                                        listen: true)
                                    .isDownloading,
                                onTap: controlsDetails.onStepContinue,
                                text: 'Next',
                                icon: const Icon(Icons.check)),
                            const SizedBox(width: 20),
                            UIWidgets.iconButton(
                                onPressed: controlsDetails.onStepCancel!,
                                icon: Icons.close),
                          ],
                        ),
                      );
                    },
                    onStepCancel: () => Navigator.of(context).pop(),
                    onStepContinue: () async {
                      if ((currentStep == 1 && tags.isEmpty) ||
                          (currentStep == 0 && controller.text.isEmpty)) {
                        return;
                      }

                      if (currentStep == 1) {
                        _onInfoSubmit();
                      }
                      if (currentStep == 0) {
                        Provider.of<TagProvider>(context, listen: false)
                            .setTags(tags);
                        await Provider.of<DirectoryProvider>(context,
                                listen: false)
                            .createTagDirectory(
                                context: context, themeName: controller.text);
                        setState(() {
                          currentStep++;
                        });
                      }
                    },
                    currentStep: currentStep,
                    steps: [
                      Step(
                        title: const Text("Enter name"),
                        content: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Text("Wall Name"))),
                        ),
                      ),
                      Step(
                          title: const Text("Tags"),
                          content: SizedBox(
                              height: 350,
                              child: Tags(
                                themeName: controller.text,
                              )))
                    ]),
              ),
            ],
          ),
        ));
  }
}
