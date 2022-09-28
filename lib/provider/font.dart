import 'package:flutter/material.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';

class FontProvider extends ChangeNotifier {
  PickerFont? font = PickerFont.fromFontSpec('Roboto:700i');

  set changeFont(PickerFont newFont) {
    font = newFont;
    notifyListeners();
  }
}
