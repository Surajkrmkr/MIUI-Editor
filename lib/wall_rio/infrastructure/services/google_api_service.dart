import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'secure_storage_service.dart';

// AdMob API fields can arrive as JSON strings OR native numbers depending on
// the field type (int64 → string, double → number). These helpers handle both.
double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

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
    debugPrint('[WallRio] signIn: reading OAuth config…');
    final config = await _storage.getOAuthConfig();
    final clientIdStr = config['clientId'];
    final clientSecretStr = config['clientSecret'];

    if (clientIdStr == null || clientIdStr.isEmpty) {
      debugPrint('[WallRio] signIn: ABORT — clientId is null/empty');
      return false;
    }
    if (clientSecretStr == null || clientSecretStr.isEmpty) {
      debugPrint('[WallRio] signIn: ABORT — clientSecret is null/empty');
      return false;
    }

    debugPrint('[WallRio] signIn: clientId present, launching consent URL…');
    final clientId = ClientId(clientIdStr, clientSecretStr);

    try {
      final client = await clientViaUserConsent(
        clientId,
        scopes,
        (url) async {
          debugPrint('[WallRio] signIn: opening URL → $url');
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            debugPrint('[WallRio] signIn: ERROR — cannot launch URL');
          }
        },
      );

      debugPrint('[WallRio] signIn: consent completed, saving credentials…');
      debugPrint('[WallRio] signIn: credential keys = ${client.credentials.accessToken.type}');
      await _storage.saveCredentials(client.credentials.toJson());
      client.close();
      debugPrint('[WallRio] signIn: SUCCESS ✓');
      return true;
    } catch (e, st) {
      debugPrint('[WallRio] signIn: ERROR — $e');
      debugPrint('[WallRio] signIn: stacktrace — $st');
      return false;
    }
  }
}

class AdMobReportingService extends GoogleApiService {
  static const _scope = 'https://www.googleapis.com/auth/admob.report';

  /// Parses the user's input into a publisher ID (for the URL) and an optional
  /// app ID (for per-app filtering).
  ///
  ///   ca-app-pub-4861691653340010~3248847115
  ///     → publisherId = pub-4861691653340010
  ///     → appId       = ca-app-pub-4861691653340010~3248847115
  ///
  ///   pub-4861691653340010
  ///     → publisherId = pub-4861691653340010
  ///     → appId       = null  (total account, no app filter)
  ({String publisherId, String? appId}) _parseInput(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'(ca-app-pub-(\d+)~\d+)').firstMatch(trimmed);
    if (match != null) {
      final pubId = 'pub-${match.group(2)}';
      debugPrint('[AdMob] parseInput: appId="${match.group(1)}" → publisherId=$pubId');
      return (publisherId: pubId, appId: match.group(1));
    }
    debugPrint('[AdMob] parseInput: publisherId only — $trimmed (no per-app filter)');
    return (publisherId: trimmed, appId: null);
  }

  Future<Map<String, dynamic>?> getYesterdayReport(String publisherId) async {
    final parsed = _parseInput(publisherId);
    debugPrint('[AdMob] getYesterdayReport: publisherId=${parsed.publisherId}, appId=${parsed.appId ?? "all apps"}');

    final client = await getAuthenticatedClient([_scope]);
    if (client == null) {
      debugPrint('[AdMob] getYesterdayReport: ERROR — no authenticated client (not signed in or tokens missing)');
      return null;
    }
    debugPrint('[AdMob] getYesterdayReport: authenticated client obtained ✓');

    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      debugPrint('[AdMob] getYesterdayReport: requesting date=$dateStr');

      final url = 'https://admob.googleapis.com/v1/accounts/${parsed.publisherId}/networkReport:generate';

      final reportSpec = <String, dynamic>{
        "dateRange": {
          "startDate": {"year": yesterday.year, "month": yesterday.month, "day": yesterday.day},
          "endDate":   {"year": yesterday.year, "month": yesterday.month, "day": yesterday.day},
        },
        "dimensions": ["DATE"],
        "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS", "MATCH_RATE", "SHOW_RATE", "AD_REQUESTS"],
      };

      // When a full App ID was supplied, filter to that specific app only
      if (parsed.appId != null) {
        reportSpec["dimensionFilters"] = [
          {
            "dimension": "APP",
            "matchesAny": {"values": [parsed.appId]},
          }
        ];
        debugPrint('[AdMob] getYesterdayReport: filtering to appId=${parsed.appId}');
      } else {
        debugPrint('[AdMob] getYesterdayReport: no app filter — returning total account revenue');
      }

      final body = {"reportSpec": reportSpec};

      debugPrint('[AdMob] getYesterdayReport: POST $url');
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('[AdMob] getYesterdayReport: HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[AdMob] getYesterdayReport: ERROR body → ${response.body}');
        return null;
      }

      // AdMob Reporting API returns a JSON array — each element is tagged as
      // {"header": {...}}, {"row": {...}}, or {"footer": {...}}.
      debugPrint('[AdMob] getYesterdayReport: raw body (first 500 chars) → ${response.body.substring(0, response.body.length.clamp(0, 500))}');
      final decoded = jsonDecode(response.body);
      debugPrint('[AdMob] getYesterdayReport: decoded type = ${decoded.runtimeType}');

      // Normalise to a list regardless of whether the API wraps in an array
      final List<dynamic> items = decoded is List ? decoded : [decoded];
      debugPrint('[AdMob] getYesterdayReport: ${items.length} item(s) in response');

      // Extract only the "row" entries
      final rowItems = items
          .whereType<Map<String, dynamic>>()
          .where((e) => e.containsKey('row'))
          .map((e) => e['row'] as Map<String, dynamic>)
          .toList();

      debugPrint('[AdMob] getYesterdayReport: ${rowItems.length} data row(s) found');

      if (rowItems.isEmpty) {
        debugPrint('[AdMob] getYesterdayReport: no row entries (possibly no data for yesterday)');
        // Log header/footer for context
        for (final item in items) {
          if (item is Map && (item.containsKey('header') || item.containsKey('footer'))) {
            debugPrint('[AdMob]   → $item');
          }
        }
        return {'rows': []};
      }

      for (final row in rowItems) {
        final metrics = (row['metricValues'] ?? {}) as Map<String, dynamic>;
        final earnings    = _parseDouble(metrics['ESTIMATED_EARNINGS']?['microsValue']) / 1000000;
        final impressions = _parseInt(metrics['IMPRESSIONS']?['integerValue']);
        final requests    = _parseInt(metrics['AD_REQUESTS']?['integerValue']);
        final matchRate   = _parseDouble(metrics['MATCH_RATE']?['doubleValue']);
        debugPrint('[AdMob] getYesterdayReport: earnings=\$$earnings, impressions=$impressions, requests=$requests, matchRate=${(matchRate * 100).toStringAsFixed(1)}%');
      }

      return {'rows': rowItems};
    } catch (e, st) {
      debugPrint('[AdMob] getYesterdayReport: EXCEPTION — $e');
      debugPrint('[AdMob] getYesterdayReport: stacktrace — $st');
      return null;
    } finally {
      client.close();
    }
  }
}

class PlayConsoleReportingService extends GoogleApiService {
  static const _scope = 'https://www.googleapis.com/auth/playdeveloperreporting';
  static const _baseUrl = 'https://playdeveloperreporting.googleapis.com/v1beta1';

  // Fetches crash rate + ANR rate for yesterday via the Play Developer Reporting API.
  // NOTE: Revenue and installs are NOT available via this API — Google only exposes
  // them through daily GCS bucket exports, not real-time REST endpoints.
  Future<Map<String, dynamic>?> getAppMetrics(String packageName) async {
    debugPrint('[Play] getAppMetrics: packageName=$packageName');

    final client = await getAuthenticatedClient([_scope]);
    if (client == null) {
      debugPrint('[Play] getAppMetrics: ERROR — no authenticated client');
      return null;
    }
    debugPrint('[Play] getAppMetrics: authenticated client obtained ✓');

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final body = jsonEncode({
      'dimensions': [],
      'metrics': ['crashRate', 'distinctUsers'],
      'timelineSpec': {
        'aggregationPeriod': 'DAILY',
        'startTime': {
          'year': yesterday.year,
          'month': yesterday.month,
          'day': yesterday.day,
        },
        'endTime': {
          'year': yesterday.year,
          'month': yesterday.month,
          'day': yesterday.day,
        },
      },
      'userCohort': 'OS_PUBLIC',
    });

    try {
      // ── Crash rate ────────────────────────────────────────────────────────
      final crashUrl = '$_baseUrl/apps/$packageName/crashRateMetricSet:query';
      debugPrint('[Play] getAppMetrics: POST $crashUrl');
      final crashResp = await client.post(
        Uri.parse(crashUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint('[Play] crashRate HTTP ${crashResp.statusCode}');
      if (crashResp.statusCode != 200) {
        debugPrint('[Play] crashRate ERROR → ${crashResp.body}');
      } else {
        debugPrint('[Play] crashRate body (first 400) → ${crashResp.body.substring(0, crashResp.body.length.clamp(0, 400))}');
      }

      // ── ANR rate ──────────────────────────────────────────────────────────
      final anrBody = jsonEncode({
        'dimensions': [],
        'metrics': ['anrRate', 'distinctUsers'],
        'timelineSpec': {
          'aggregationPeriod': 'DAILY',
          'startTime': {
            'year': yesterday.year,
            'month': yesterday.month,
            'day': yesterday.day,
          },
          'endTime': {
            'year': yesterday.year,
            'month': yesterday.month,
            'day': yesterday.day,
          },
        },
        'userCohort': 'OS_PUBLIC',
      });
      final anrUrl = '$_baseUrl/apps/$packageName/anrRateMetricSet:query';
      debugPrint('[Play] getAppMetrics: POST $anrUrl');
      final anrResp = await client.post(
        Uri.parse(anrUrl),
        headers: {'Content-Type': 'application/json'},
        body: anrBody,
      );
      debugPrint('[Play] anrRate HTTP ${anrResp.statusCode}');
      if (anrResp.statusCode != 200) {
        debugPrint('[Play] anrRate ERROR → ${anrResp.body}');
      } else {
        debugPrint('[Play] anrRate body (first 400) → ${anrResp.body.substring(0, anrResp.body.length.clamp(0, 400))}');
      }

      double crashRate = 0;
      double anrRate   = 0;
      int    distinctUsers = 0;

      if (crashResp.statusCode == 200) {
        final crashData = jsonDecode(crashResp.body) as Map<String, dynamic>;
        final rows = (crashData['rows'] as List?) ?? [];
        if (rows.isNotEmpty) {
          final metrics = rows.first['metrics'] as Map<String, dynamic>? ?? {};
          crashRate    = _parseDouble(metrics['crashRate']);
          distinctUsers = _parseInt(metrics['distinctUsers']);
          debugPrint('[Play] crashRate=${(crashRate * 100).toStringAsFixed(3)}%, distinctUsers=$distinctUsers');
        } else {
          debugPrint('[Play] crashRate: no rows returned');
        }
      }

      if (anrResp.statusCode == 200) {
        final anrData = jsonDecode(anrResp.body) as Map<String, dynamic>;
        final rows = (anrData['rows'] as List?) ?? [];
        if (rows.isNotEmpty) {
          final metrics = rows.first['metrics'] as Map<String, dynamic>? ?? {};
          anrRate = _parseDouble(metrics['anrRate']);
          debugPrint('[Play] anrRate=${(anrRate * 100).toStringAsFixed(3)}%');
        } else {
          debugPrint('[Play] anrRate: no rows returned');
        }
      }

      debugPrint('[Play] getAppMetrics ─────────────────────────────────────');
      debugPrint('[Play]   Crash Rate     : ${(crashRate * 100).toStringAsFixed(3)}%');
      debugPrint('[Play]   ANR Rate       : ${(anrRate * 100).toStringAsFixed(3)}%');
      debugPrint('[Play]   Distinct Users : $distinctUsers');
      debugPrint('[Play]   Revenue        : N/A (GCS export only)');
      debugPrint('[Play]   Installs       : N/A (GCS export only)');
      debugPrint('[Play] ──────────────────────────────────────────────────');

      return {
        'crashRate': crashRate,
        'anrRate':   anrRate,
        'distinctUsers': distinctUsers,
      };
    } catch (e, st) {
      debugPrint('[Play] getAppMetrics: EXCEPTION — $e');
      debugPrint('[Play] getAppMetrics: stacktrace — $st');
      return null;
    } finally {
      client.close();
    }
  }
}
