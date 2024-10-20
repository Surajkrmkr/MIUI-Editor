import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/miui_theme_data.dart';
import '../provider/icon.dart';
import '../provider/userprofile.dart';

class IconWidget extends StatelessWidget {
  final double? margin;
  final double? padding;
  final Color? bgColor;
  final Color? bgColor2;
  final List<Color>? bgColors;
  final AlignmentGeometry? bgGradAlign;
  final AlignmentGeometry? bgGradAlign2;
  final double? radius;
  final bool? randomColors;
  final Color? iconColor;
  final double? borderWidth;
  final Color? borderColor;
  final String? name;
  final UserProfiles? userType;
  const IconWidget(
      {super.key,
      required this.margin,
      required this.padding,
      required this.bgColor,
      required this.radius,
      required this.iconColor,
      required this.name,
      required this.borderWidth,
      required this.borderColor,
      required this.bgColor2,
      required this.bgGradAlign,
      required this.bgGradAlign2,
      required this.userType,
      required this.bgColors,
      required this.randomColors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      width: 45,
      child: Container(
        margin: EdgeInsets.all(name == 'icon_mask' ? 10 : margin!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(name == 'icon_mask' ? 200 : 0),
          child: Container(
            padding: EdgeInsets.all(padding!),
            height: 130,
            width: 130,
            decoration: BoxDecoration(
              border: Border.all(width: borderWidth!, color: borderColor!),
              borderRadius: BorderRadius.circular(radius!),
              gradient: getGradient(
                  colors: name == 'icon_border'
                      ? [Colors.transparent, Colors.transparent]
                      : randomColors!
                          ? [
                              bgColors![
                                  Random().nextInt(bgColors!.length)]
                            ]
                          : [bgColor!, bgColor2!],
                  start: bgGradAlign,
                  end: bgGradAlign2),
            ),
            child: !MIUIThemeData.extraIconList.contains(name)
                ? Center(
                    child: SvgPicture.asset(
                    "assets/icons/${users[userType]!["user"]}/$name.svg",
                    colorFilter: ColorFilter.mode(iconColor!, BlendMode.srcIn),
                  ))
                : Container(),
          ),
        ),
      ),
    );
  }
}

Gradient getGradient(
    {List<Color>? colors, AlignmentGeometry? start, AlignmentGeometry? end}) {
  return LinearGradient(
      begin: start!,
      end: end!,
      colors: colors!.length > 1 ? colors : [colors.first, colors.last]);
}

class IconContainer extends StatelessWidget {
  final String? name;
  const IconContainer({
    Key? key,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<IconProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 45,
          width: 45,
          child: Container(
            margin: EdgeInsets.all(provider.margin!),
            child: Container(
              padding: EdgeInsets.all(provider.padding!),
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                  border: Border.all(
                      width: provider.borderWidth!,
                      color: provider.borderColor!),
                  borderRadius: BorderRadius.circular(provider.radius!),
                  gradient: getGradient(
                      colors: provider.randomColors!
                          ? [
                              provider.bgColors![
                                  Random().nextInt(provider.bgColors!.length)]
                            ]
                          : [provider.bgColor!, provider.bgColor2!],
                      start: provider.bgGradAlign,
                      end: provider.bgGradAlign2),
                  color: provider.bgColor),
              child: Center(child: Consumer<UserProfileProvider>(
                  builder: (context, userProvider, child) {
                return SvgPicture.asset(
                  "assets/icons/${users[userProvider.activeUser]!["user"]}/$name.svg",
                  colorFilter:
                      ColorFilter.mode(provider.iconColor!, BlendMode.srcIn),
                );
              })),
            ),
          ),
        );
      },
    );
  }
}
