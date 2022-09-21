import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data.dart';

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
        margin: EdgeInsets.all(margin!),
        child: Container(
          padding: EdgeInsets.all(padding!),
          height: 130,
          width: 130,
          decoration: BoxDecoration(
              border: Border.all(width: borderWidth!, color: borderColor!),
              borderRadius: BorderRadius.circular(radius!),
              color: name == 'icon_border' ? Colors.transparent : bgColor
              ),
          child: !IconVectorData.extraIconList.contains(name)
              ? Center(
                  child: SvgPicture.asset(
                  "assets/icons/$name.svg",
                  color: iconColor,
                ))
              : Container(),
        ),
      ),
    );
  }
}
