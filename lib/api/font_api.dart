import 'dart:convert';
import 'package:http/http.dart';
import '../model/font_model.dart';

class FontApi {
  static Future<FontModel> fetchFontList() async {
    var res = await get(Uri.parse(
        "https://raw.githubusercontent.com/Surajkrmkr/font-api/main/fonts.json"));

    if (res.statusCode == 200) {
      return FontModel.fromJson(json.decode(res.body));
    }
    return FontModel();
  }
}
