import 'package:flutter/material.dart';

class MIUIBanners {
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
}
