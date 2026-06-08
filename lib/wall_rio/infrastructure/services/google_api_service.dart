import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'secure_storage_service.dart';

class GoogleApiService {
  final _storage = SecureStorageService();

  Future<AutoRefreshingAuthClient?> getAuthenticatedClient(List<String> scopes) async {
    final config = await _storage.getOAuthConfig();
    final clientIdStr = config['clientId'];
    final clientSecretStr = config['clientSecret'];

    if (clientIdStr == null || clientSecretStr == null) return null;

    final clientId = ClientId(clientIdStr, clientSecretStr);
    final savedCredentialsJson = await _storage.getCredentials();

    if (savedCredentialsJson != null) {
      final credentials = AccessCredentials.fromJson(savedCredentialsJson);
      final client = autoRefreshingClient(clientId, credentials, http.Client());
      
      // Listen for background refreshes and save them
      client.credentialUpdates.listen((updated) {
        _storage.saveCredentials(updated.toJson());
      });
      
      return client;
    }

    // If no credentials, we need to trigger sign in flow
    return null;
  }

  Future<bool> signIn(List<String> scopes) async {
    final config = await _storage.getOAuthConfig();
    final clientIdStr = config['clientId'];
    final clientSecretStr = config['clientSecret'];

    if (clientIdStr == null || clientSecretStr == null) return false;

    final clientId = ClientId(clientIdStr, clientSecretStr);

    try {
      final client = await clientViaUserConsent(
        clientId,
        scopes,
        (url) async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        },
      );

      await _storage.saveCredentials(client.credentials.toJson());
      client.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AdMobReportingService extends GoogleApiService {
  static const _scope = 'https://www.googleapis.com/auth/admob.report';

  Future<Map<String, dynamic>?> getYesterdayReport(String publisherId) async {
    final client = await getAuthenticatedClient([_scope]);
    if (client == null) return null;

    try {
      final url = 'https://admob.googleapis.com/v1/accounts/$publisherId/networkReport:generate';
      
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final body = {
        "reportSpec": {
          "dateRange": {
            "startDate": {"year": yesterday.year, "month": yesterday.month, "day": yesterday.day},
            "endDate": {"year": yesterday.year, "month": yesterday.month, "day": yesterday.day}
          },
          "dimensions": ["DATE"],
          "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS", "MATCH_RATE", "SHOW_RATE", "AD_REQUESTS"],
        }
      };

      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Parse the AdMob report response
        // Note: Real parsing logic for AdMob JSON reports is complex, 
        // this is a simplified version for implementation.
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } finally {
      client.close();
    }
  }
}

class PlayConsoleReportingService extends GoogleApiService {
  static const _scope = 'https://www.googleapis.com/auth/playdeveloperreporting';

  Future<Map<String, dynamic>?> getAppMetrics(String packageName) async {
    final client = await getAuthenticatedClient([_scope]);
    if (client == null) return null;

    try {
      // Format: apps/{package_name}/fetch...
      // This varies significantly by specific metric. 
      // We'll use a placeholder for the complex Play Console reporting API.
      return {}; 
    } finally {
      client.close();
    }
  }
}
