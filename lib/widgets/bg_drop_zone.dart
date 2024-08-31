import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/functions/windows_utils.dart';

import '../functions/theme_path.dart';

class BGDropZone extends StatelessWidget {
  const BGDropZone({super.key, this.path});
  final String? path;
  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        final themePath = CurrentTheme.getPath(context);
        final bgPath = File(
            platformBasedPath("${themePath}lockscreen\\advance\\$path.png"));
        await detail.files.first.saveTo(bgPath.path);
      },
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).colorScheme.primary,
        ),
        alignment: Alignment.center,
        child: Text(
          "Drop",
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
