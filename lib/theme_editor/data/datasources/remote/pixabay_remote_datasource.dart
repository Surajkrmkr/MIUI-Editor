import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/models/pixabay_model.dart';

class PixabayRemoteDataSource {
  // Move to env / secure storage for production
  static const _apiKey = '31113124-f106490fe1e04de14da97dcb6';

  Future<PixabayResult> search({
    required String query,
    required PixabayImageType type,
    required int page,
  }) async {
    final url = Uri.parse(
      'https://pixabay.com/api/?q=\$query&image_type=\${type.name}&page=\$page&key=\$_apiKey',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('Pixabay error \${res.statusCode}');
    return PixabayResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
