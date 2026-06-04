import 'package:flutter/material.dart';
import '../../domain/entities/element_widget.dart';

extension MamlEaseX on MamlEase {
  Curve get curve {
    switch (this) {
      case MamlEase.linear: return Curves.linear;
      case MamlEase.sineEaseIn: return Curves.easeInSine;
      case MamlEase.sineEaseOut: return Curves.easeOutSine;
      case MamlEase.sineEaseInOut: return Curves.easeInOutSine;
      case MamlEase.quadEaseIn: return Curves.easeInQuad;
      case MamlEase.quadEaseOut: return Curves.easeOutQuad;
      case MamlEase.quadEaseInOut: return Curves.easeInOutQuad;
      case MamlEase.cubicEaseIn: return Curves.easeInCubic;
      case MamlEase.cubicEaseOut: return Curves.easeOutCubic;
      case MamlEase.cubicEaseInOut: return Curves.easeInOutCubic;
      case MamlEase.quartEaseIn: return Curves.easeInQuart;
      case MamlEase.quartEaseOut: return Curves.easeOutQuart;
      case MamlEase.quartEaseInOut: return Curves.easeInOutQuart;
      case MamlEase.quintEaseIn: return Curves.easeInQuint;
      case MamlEase.quintEaseOut: return Curves.easeOutQuint;
      case MamlEase.quintEaseInOut: return Curves.easeInOutQuint;
      case MamlEase.expoEaseIn: return Curves.easeInExpo;
      case MamlEase.expoEaseOut: return Curves.easeOutExpo;
      case MamlEase.expoEaseInOut: return Curves.easeInOutExpo;
      case MamlEase.circEaseIn: return Curves.easeInCirc;
      case MamlEase.circEaseOut: return Curves.easeOutCirc;
      case MamlEase.circEaseInOut: return Curves.easeInOutCirc;
      case MamlEase.backEaseIn: return Curves.easeInBack;
      case MamlEase.backEaseOut: return Curves.easeOutBack;
      case MamlEase.backEaseInOut: return Curves.easeInOutBack;
      case MamlEase.elasticEaseIn: return Curves.elasticIn;
      case MamlEase.elasticEaseOut: return Curves.elasticOut;
      case MamlEase.elasticEaseInOut: return Curves.elasticInOut;
      case MamlEase.bounceEaseIn: return Curves.bounceIn;
      case MamlEase.bounceEaseOut: return Curves.bounceOut;
      case MamlEase.bounceEaseInOut: return Curves.bounceInOut;
    }
  }
}
