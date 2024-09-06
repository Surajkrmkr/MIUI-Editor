import 'dart:convert';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../model/font_model.dart';
import '../provider/userprofile.dart';

class FontApi {
  static Future<FontModel> fetchFontList(context) async {
    final userProfile =
        Provider.of<UserProfileProvider>(context, listen: false).activeUser;
    var res = await get(Uri.parse(users[userProfile]!["fontUrl"]!));

    if (res.statusCode == 200) {
      return FontModel.fromJson(json.decode(res.body));
    }
    return FontModel();
  }
}
