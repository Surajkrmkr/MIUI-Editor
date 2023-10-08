import 'dart:io';
import 'package:flutter/material.dart';

class UIWidgets {
  static void getBanner(
      {String? content, bool? hasError, BuildContext? context}) {
    ScaffoldMessenger.of(context!).showSnackBar(SnackBar(
      content: Text(content!, style: const TextStyle(color: Colors.white)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      showCloseIcon: true,
      closeIconColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 500),
    ));
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
                padding: Platform.isWindows
                    ? const EdgeInsets.symmetric(vertical: 23)
                    : EdgeInsets.zero),
            onPressed: onTap,
            label: Text(text!)),
      );

  static Widget getIconButton(
      {IconData? icon, Widget? widget, BuildContext? context}) {
    return IconButton(
        onPressed: () {
          showModalBottomSheet(
              barrierColor: Colors.transparent,
              context: context!,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              builder: ((context) => Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                          height: MediaQuery.of(context).size.height * 0.35,
                          width: MediaQuery.of(context).size.width * 0.7,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: widget!),
                    ],
                  )));
        },
        icon: Icon(icon!));
  }
}
