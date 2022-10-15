import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../functions/theme_path.dart';

class BGDropZone extends StatelessWidget {
  const BGDropZone({super.key});

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        final themePath = CurrentTheme.getPath(context);
        final bgPath = File("$themePath\\lockscreen\\advance\\bg.png");
        await detail.files.first.saveTo(bgPath.path);
      },
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.pinkAccent,
        ),
        alignment: Alignment.center,
        child: Text(
          "BG Drop",
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
