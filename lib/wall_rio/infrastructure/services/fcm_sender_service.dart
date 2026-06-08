import 'dart:convert';
import 'google_api_service.dart';
import 'secure_storage_service.dart';

class FCMSenderService extends GoogleApiService {
  static const _scope = 'https://www.googleapis.com/auth/firebase.messaging';

  Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    Map<String, String>? data,
  }) async {
    final client = await getAuthenticatedClient([_scope]);
    if (client == null) return false;

    // We need the project ID from secure storage
    final config = await SecureStorageService().getOAuthConfig();
    final projectId = config['projectId'];
    if (projectId == null) return false;

    try {
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      
      final message = {
        "message": {
          "topic": topic,
          "notification": {
            "title": title,
            "body": body,
            if (imageUrl != null) "image": imageUrl,
          },
          "data": {
            if (deepLink != null) "click_action": deepLink,
            ...?data,
          },
          "android": {
            "notification": {
              "image": imageUrl,
            }
          }
        }
      };

      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } finally {
      client.close();
    }
  }
}
