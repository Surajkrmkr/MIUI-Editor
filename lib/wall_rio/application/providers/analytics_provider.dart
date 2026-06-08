import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/analytics_models.dart';
import '../../infrastructure/services/app_settings_service.dart';
import '../../infrastructure/services/google_api_service.dart';
import 'credentials_provider.dart';

class AnalyticsStateNotifier extends AsyncNotifier<CombinedAnalytics?> {
  final _admobService = AdMobReportingService();
  final _settingsService = AppSettingsService();

  @override
  FutureOr<CombinedAnalytics?> build() async {
    final credentials = await ref.watch(credentialsStateProvider.future);
    if (!credentials.hasGoogleCloud) return null;
    return _fetchData();
  }

  Future<CombinedAnalytics?> _fetchData() async {
    final pubId = await _settingsService.getAdMobPublisherId();
    final pkgName = await _settingsService.getPlayPackageName();

    AdMobMetrics? admob;
    PlayConsoleMetrics? play;

    if (pubId != null && pubId.isNotEmpty) {
      final report = await _admobService.getYesterdayReport(pubId);
      if (report != null && report['rows'] != null) {
        final row = (report['rows'] as List).first;
        final metrics = row['metricValues'] as Map<String, dynamic>;
        admob = AdMobMetrics(
          earnings: (double.tryParse(metrics['ESTIMATED_EARNINGS']?['microsValue'] ?? '0') ?? 0) / 1000000,
          impressions: int.tryParse(metrics['IMPRESSIONS']?['integerValue'] ?? '0') ?? 0,
          ecpm: 0,
          matchRate: double.tryParse(metrics['MATCH_RATE']?['doubleValue'] ?? '0') ?? 0,
          requests: int.tryParse(metrics['AD_REQUESTS']?['integerValue'] ?? '0') ?? 0,
          date: DateTime.now().subtract(const Duration(days: 1)),
        );
      }
    }

    if (pkgName != null && pkgName.isNotEmpty) {
      play = PlayConsoleMetrics(
        revenue: 0,
        installs: 0,
        activeDevices: 0,
        averageRating: 0,
        crashRate: 0,
        anrRate: 0,
        date: DateTime.now().subtract(const Duration(days: 1)),
      );
    }

    return CombinedAnalytics(
      admob: admob,
      play: play,
      lastRefreshed: DateTime.now(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _fetchData());
  }
}

final analyticsStateProvider =
    AsyncNotifierProvider<AnalyticsStateNotifier, CombinedAnalytics?>(
  AnalyticsStateNotifier.new,
);
