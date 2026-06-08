import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/analytics_models.dart';
import '../../infrastructure/services/app_settings_service.dart';
import '../../infrastructure/services/google_api_service.dart';
import 'credentials_provider.dart';

double _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class AnalyticsStateNotifier extends AsyncNotifier<CombinedAnalytics?> {
  final _admobService = AdMobReportingService();
  final _settingsService = AppSettingsService();

  @override
  FutureOr<CombinedAnalytics?> build() async {
    final credentials = await ref.watch(credentialsStateProvider.future);
    debugPrint('[Analytics] build: isSignedIn=${credentials.hasGoogleCloud}');
    if (!credentials.hasGoogleCloud) {
      debugPrint('[Analytics] build: skipping fetch — not signed in');
      return null;
    }
    return _fetchData();
  }

  Future<CombinedAnalytics?> _fetchData() async {
    debugPrint('[Analytics] _fetchData: starting…');
    final pubId   = await _settingsService.getAdMobPublisherId();
    final pkgName = await _settingsService.getPlayPackageName();
    debugPrint('[Analytics] _fetchData: pubId=${pubId ?? "null"}, pkgName=${pkgName ?? "null"}');

    AdMobMetrics? admob;
    PlayConsoleMetrics? play;

    // ── AdMob ───────────────────────────────────────────────────────────────
    if (pubId != null && pubId.isNotEmpty) {
      debugPrint('[Analytics] _fetchData: fetching AdMob report…');
      final report = await _admobService.getYesterdayReport(pubId);

      if (report == null) {
        debugPrint('[Analytics] _fetchData [AdMob]: report is null — API call failed');
      } else if (report['rows'] == null || (report['rows'] as List).isEmpty) {
        debugPrint('[Analytics] _fetchData [AdMob]: report returned but has no rows (no data for yesterday)');
      } else {
        final row     = (report['rows'] as List).first as Map<String, dynamic>;
        final metrics = (row['metricValues'] ?? {}) as Map<String, dynamic>;

        final earnings    = _parseNum(metrics['ESTIMATED_EARNINGS']?['microsValue']) / 1000000;
        final impressions = _parseNum(metrics['IMPRESSIONS']?['integerValue']).toInt();
        final requests    = _parseNum(metrics['AD_REQUESTS']?['integerValue']).toInt();
        final matchRate   = _parseNum(metrics['MATCH_RATE']?['doubleValue']);

        debugPrint('[Analytics] _fetchData [AdMob] ──────────────────────────');
        debugPrint('[Analytics]   Earnings (yesterday) : \$${earnings.toStringAsFixed(4)}');
        debugPrint('[Analytics]   Impressions          : $impressions');
        debugPrint('[Analytics]   Ad Requests          : $requests');
        debugPrint('[Analytics]   Match Rate           : ${(matchRate * 100).toStringAsFixed(2)}%');
        debugPrint('[Analytics] ─────────────────────────────────────────────');

        admob = AdMobMetrics(
          earnings:    earnings,
          impressions: impressions,
          ecpm:        impressions > 0 ? (earnings / impressions) * 1000 : 0,
          matchRate:   matchRate,
          requests:    requests,
          date:        DateTime.now().subtract(const Duration(days: 1)),
        );

      }
    } else {
      debugPrint('[Analytics] _fetchData [AdMob]: skipped — no publisher ID configured');
    }

    // ── Play Console ────────────────────────────────────────────────────────
    if (pkgName != null && pkgName.isNotEmpty) {
      debugPrint('[Analytics] _fetchData [Play]: fetching crash/ANR rates for $pkgName…');
      final playData = await PlayConsoleReportingService().getAppMetrics(pkgName);

      if (playData == null) {
        debugPrint('[Analytics] _fetchData [Play]: API returned null — skipping');
      } else {
        final crashRate = _parseNum(playData['crashRate']);
        final anrRate   = _parseNum(playData['anrRate']);
        play = PlayConsoleMetrics(
          revenue:       0,   // not available via REST API
          installs:      0,   // not available via REST API
          activeDevices: _parseNum(playData['distinctUsers']).toInt(),
          averageRating: 0,   // requires androidpublisher scope
          crashRate:     crashRate,
          anrRate:       anrRate,
          date:          DateTime.now().subtract(const Duration(days: 1)),
        );
        debugPrint('[Analytics] _fetchData [Play] ───────────────────────────');
        debugPrint('[Analytics]   Crash Rate     : ${(crashRate * 100).toStringAsFixed(3)}%');
        debugPrint('[Analytics]   ANR Rate       : ${(anrRate * 100).toStringAsFixed(3)}%');
        debugPrint('[Analytics]   Distinct Users : ${play.activeDevices}');
        debugPrint('[Analytics]   Revenue/Installs: N/A (GCS export only)');
        debugPrint('[Analytics] ────────────────────────────────────────────');
      }
    } else {
      debugPrint('[Analytics] _fetchData [Play]: skipped — no package name configured');
    }

    final result = CombinedAnalytics(
      admob:         admob,
      play:          play,
      lastRefreshed: DateTime.now(),
    );
    debugPrint('[Analytics] _fetchData: done — admob=${admob != null}, play=${play != null}');
    return result;
  }

  Future<void> refresh() async {
    debugPrint('[Analytics] refresh: triggered');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _fetchData());
    debugPrint('[Analytics] refresh: complete, isError=${state.hasError}');
    if (state.hasError) debugPrint('[Analytics] refresh: error=${state.error}');
  }
}

final analyticsStateProvider =
    AsyncNotifierProvider<AnalyticsStateNotifier, CombinedAnalytics?>(
  AnalyticsStateNotifier.new,
);
