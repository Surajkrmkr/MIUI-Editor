import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

@freezed
abstract class AdMobMetrics with _$AdMobMetrics {
  const factory AdMobMetrics({
    required double earnings,
    required int impressions,
    required double ecpm,
    required double matchRate,
    required int requests,
    required DateTime date,
  }) = _AdMobMetrics;

  factory AdMobMetrics.fromJson(Map<String, dynamic> json) => _$AdMobMetricsFromJson(json);
}

@freezed
abstract class PlayConsoleMetrics with _$PlayConsoleMetrics {
  const factory PlayConsoleMetrics({
    required double revenue,
    required int installs,
    required int activeDevices,
    required double averageRating,
    required double crashRate,
    required double anrRate,
    required DateTime date,
  }) = _PlayConsoleMetrics;

  factory PlayConsoleMetrics.fromJson(Map<String, dynamic> json) => _$PlayConsoleMetricsFromJson(json);
}

@freezed
abstract class CombinedAnalytics with _$CombinedAnalytics {
  const factory CombinedAnalytics({
    AdMobMetrics? admob,
    PlayConsoleMetrics? play,
    required DateTime lastRefreshed,
  }) = _CombinedAnalytics;
}
