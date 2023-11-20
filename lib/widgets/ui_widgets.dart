import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:shimmer/shimmer.dart';

import '../theme.dart';

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
          {required String text,
          required Icon icon,
          bool isLoading = false,
          required Function()? onTap}) =>
      SizedBox(
        width: MIUIConstants.isDesktop ? 190 : 150,
        child: isLoading
            ? Shimmer.fromColors(
                baseColor: AppThemeData.accentColor,
                highlightColor: Colors.white,
                direction: ShimmerDirection.ltr,
                child: UIWidgets.getElevatedButton(
                    text: text, icon: icon, onTap: null),
              )
            : ElevatedButton.icon(
                icon: icon,
                style: ElevatedButton.styleFrom(
                    padding: MIUIConstants.isDesktop
                        ? const EdgeInsets.symmetric(vertical: 23)
                        : EdgeInsets.zero),
                onPressed: onTap,
                label: Text(text)),
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

  static iconButton({required Function() onPressed, required IconData icon}) {
    return IconButton(onPressed: onPressed, icon: Icon(icon));
  }

  static void dialog({required BuildContext context, required Widget child}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return child;
        });
  }
}
