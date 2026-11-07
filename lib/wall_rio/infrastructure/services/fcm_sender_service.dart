import 'dart:convert';
import 'google_api_service.dart';
import 'secure_storage_service.dart';

class FCMSenderService extends GoogleApiService {
  static const _scope = 'https://www.googleapis.com/auth/firebase.messaging';

  /// Sends to [topic]; throws with the reason if FCM can't be reached or rejects it.
  Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    Map<String, String>? data,
  }) async {
    final client = await getAuthenticatedClient([_scope]);
    if (client == null) throw StateError('Sign in with Google in Settings first');

    final config = await SecureStorageService().getOAuthConfig();
    final projectId = config['projectId'];
    if (projectId == null || projectId.isEmpty) {
      client.close();
      throw StateError('Set the Firebase project ID in Settings → Credentials');
    }

    try {
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
      final hasLink = deepLink != null && deepLink.isNotEmpty;

      final message = {
        "message": {
          "topic": topic,
          "notification": {
            "title": title,
            "body": body,
            if (hasImage) "image": imageUrl,
          },
          "data": {
            if (hasLink) "click_action": deepLink,
            ...?data,
          },
          if (hasImage) "apns": {
            "payload": {"aps": {"mutable-content": 1}},
            "fcm_options": {"image": imageUrl},
          },
        }
      };

      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );
      if (response.statusCode != 200) {
        throw StateError('FCM ${response.statusCode}: ${response.body}');
      }
    } finally {
      client.close();
    }
  }
}
