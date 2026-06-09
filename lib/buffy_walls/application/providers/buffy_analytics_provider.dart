import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wall_rio/domain/models/analytics_models.dart';
import '../../infrastructure/services/buffy_secure_storage_service.dart';
import '../../../wall_rio/infrastructure/services/google_api_service.dart';
import 'buffy_credentials_provider.dart';
import 'buffy_settings_provider.dart';

double _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class BuffyAnalyticsStateNotifier extends AsyncNotifier<CombinedAnalytics?> {
  late final _storage = BuffySecureStorageService();
  late final _admobService = AdMobReportingService(_storage);
  late final _playService = PlayConsoleReportingService(_storage);

  @override
  FutureOr<CombinedAnalytics?> build() async {
    final credentials = await ref.watch(buffyCredentialsProvider.future);
    if (!credentials.hasGoogleCloud) {
      return null;
    }
    return _fetchData();
  }

  Future<CombinedAnalytics?> _fetchData() async {
    final settings = ref.read(buffySettingsProvider);
    final pubId = settings.admobPublisherId;
    final pkgName = settings.playPackageName;

    AdMobMetrics? admob;
    PlayConsoleMetrics? play;

    if (pubId.isNotEmpty) {
      final report = await _admobService.getYesterdayReport(pubId);
      if (report != null && report['rows'] != null && (report['rows'] as List).isNotEmpty) {
        final row = (report['rows'] as List).first as Map<String, dynamic>;
        final metrics = (row['metricValues'] ?? {}) as Map<String, dynamic>;
        final earnings    = _parseNum(metrics['ESTIMATED_EARNINGS']?['microsValue']) / 1000000;
        final impressions = (_parseNum(metrics['IMPRESSIONS']?['integerValue'])).toInt();
        admob = AdMobMetrics(
          earnings:    earnings,
          impressions: impressions,
          ecpm:        impressions > 0 ? (earnings / impressions) * 1000 : 0,
          matchRate:   _parseNum(metrics['MATCH_RATE']?['doubleValue']),
          requests:    (_parseNum(metrics['AD_REQUESTS']?['integerValue'])).toInt(),
          date:        DateTime.now().subtract(const Duration(days: 1)),
        );
      }
    }

    if (pkgName.isNotEmpty) {
      final metrics = await _playService.getAppMetrics(pkgName);
      if (metrics != null) {
        play = PlayConsoleMetrics(
          revenue: 0,
          installs: 0,
          activeDevices: metrics['distinctUsers'] ?? 0,
          averageRating: 0,
          crashRate: metrics['crashRate'] ?? 0,
          anrRate: metrics['anrRate'] ?? 0,
          date: DateTime.now().subtract(const Duration(days: 1)),
        );
      }
    }

    return CombinedAnalytics(
      admob: admob,
      play: play,
      lastRefreshed: DateTime.now(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }
}

final buffyAnalyticsStateProvider =
    AsyncNotifierProvider<BuffyAnalyticsStateNotifier, CombinedAnalytics?>(
  BuffyAnalyticsStateNotifier.new,
);
