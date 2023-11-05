import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../provider/icon.dart';
import '../../provider/wallpaper.dart';

Widget ninePatchSvg({required BuildContext context, required String svgPath}) {
  return SvgPicture.string(svgPath.replaceAll(
      "#FF8CEE",
      colorToHexString(
          Provider.of<IconProvider>(context, listen: false).accentColor)));
}

Widget ninePatchPng({required BuildContext context, required String pngPath}) {
  return Container(
    height: MIUIConstants.screenHeight,
    width: MIUIConstants.screenWidth,
    decoration: BoxDecoration(
      image: DecorationImage(image: AssetImage(pngPath), fit: BoxFit.fill),
    ),
    child: Align(
        alignment: Alignment.center,
        child: Image.file(
          File(Provider.of<WallpaperProvider>(context, listen: false).paths![
              Provider.of<WallpaperProvider>(context, listen: false).index!]),
          height: MIUIConstants.screenHeight - 2,
          width: MIUIConstants.screenWidth - 2,
          color: Colors.black54,
          colorBlendMode: BlendMode.srcATop,
        )),
  );
}

colorToHexString(Color? color) {
  return '#${color!.value.toRadixString(16).substring(2, 8)}';
}
