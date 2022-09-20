import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconWidget extends StatelessWidget {
  final double? margin;
  final double? padding;
  final Color? bgColor;
  final double? radius;
  final Color? iconColor;
  final String? name;
  const IconWidget(
      {super.key,
      required this.margin,
      required this.padding,
      required this.bgColor,
      required this.radius,
      required this.iconColor,
      required this.name});

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
              borderRadius: BorderRadius.circular(radius!), color: bgColor),
          child: Center(
              child: SvgPicture.asset(
            "assets/icons/$name.svg",
            color: iconColor,
          )),
        ),
      ),
    );
  }
}
