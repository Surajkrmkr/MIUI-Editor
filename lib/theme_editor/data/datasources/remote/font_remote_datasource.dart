import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/models/font_model.dart';

class FontRemoteDataSource {
  Future<FontListModel> fetchFonts(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Font API error \${res.statusCode}');
    }
    return FontListModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
