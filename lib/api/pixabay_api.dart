import 'dart:convert';

import 'package:http/http.dart';

import '../model/pixabay_wall_model.dart';

class PixabayApi {
  static String apiKey = "31113124-f106490fe1e04de14da97dcb6";
  static Future<PixabayWallModel> fetchList(
      String search, String imageType, int page) async {
    final url = Uri.parse(
        "https://pixabay.com/api/?q=$search&image_type=$imageType&page=$page&key=$apiKey");
    final res = await get(url);
    if (res.statusCode == 200) {
      return PixabayWallModel.fromJson(json.decode(res.body));
    }
    return PixabayWallModel();
  }
}
