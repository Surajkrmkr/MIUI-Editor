import 'dart:io';

import 'package:flutter/material.dart';

class UIWidgets {
  static void getBanner(
      {String? content, bool? hasError, BuildContext? context}) {
    ScaffoldMessenger.of(context!).showMaterialBanner(MaterialBanner(
        backgroundColor: hasError! ? Colors.redAccent : Colors.pinkAccent,
        leading: const Icon(
          Icons.done,
          color: Colors.white,
        ),
        content: Text(
          content!,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(onPressed: () {}, child: const Text("Okay"))
        ]));
    Future.delayed(const Duration(seconds: 3), () {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  static Widget getElevatedButton(
          {required String? text,
          required Icon icon,
          required Function()? onTap}) =>
      SizedBox(
        width: Platform.isWindows ? 190 : 150,
        child: ElevatedButton.icon(
            icon: icon,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: Platform.isWindows
                    ? const EdgeInsets.symmetric(vertical: 23)
                    : EdgeInsets.zero),
            onPressed: onTap,
            label: Text(text!)),
      );
}
