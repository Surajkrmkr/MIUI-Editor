import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/miui_theme_data.dart';
import '../provider/icon.dart';

class IconWidget extends StatelessWidget {
  final double? margin;
  final double? padding;
  final Color? bgColor;
  final double? radius;
  final Color? iconColor;
  final double? borderWidth;
  final Color? borderColor;
  final String? name;
  const IconWidget(
      {super.key,
      required this.margin,
      required this.padding,
      required this.bgColor,
      required this.radius,
      required this.iconColor,
      required this.name,
      required this.borderWidth,
      required this.borderColor});

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
                color: name == 'icon_border' ? Colors.transparent : bgColor),
            child: !MIUIThemeData.extraIconList.contains(name)
                ? Center(
                    child: SvgPicture.asset(
                    "assets/icons/$name.svg",
                    colorFilter: ColorFilter.mode(iconColor!, BlendMode.srcIn),
                  ))
                : Container(),
          ),
        ),
      ),
    );
  }
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
                  color: provider.bgColor),
              child: Center(
                  child: SvgPicture.asset(
                "assets/icons/$name.svg",
                colorFilter:
                    ColorFilter.mode(provider.iconColor!, BlendMode.srcIn),
              )),
            ),
          ),
        );
      },
    );
  }
}
