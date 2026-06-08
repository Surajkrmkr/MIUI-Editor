// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdMobMetrics _$AdMobMetricsFromJson(Map<String, dynamic> json) =>
    _AdMobMetrics(
      earnings: (json['earnings'] as num).toDouble(),
      impressions: (json['impressions'] as num).toInt(),
      ecpm: (json['ecpm'] as num).toDouble(),
      matchRate: (json['matchRate'] as num).toDouble(),
      requests: (json['requests'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$AdMobMetricsToJson(_AdMobMetrics instance) =>
    <String, dynamic>{
      'earnings': instance.earnings,
      'impressions': instance.impressions,
      'ecpm': instance.ecpm,
      'matchRate': instance.matchRate,
      'requests': instance.requests,
      'date': instance.date.toIso8601String(),
    };

_PlayConsoleMetrics _$PlayConsoleMetricsFromJson(Map<String, dynamic> json) =>
    _PlayConsoleMetrics(
      revenue: (json['revenue'] as num).toDouble(),
      installs: (json['installs'] as num).toInt(),
      activeDevices: (json['activeDevices'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      crashRate: (json['crashRate'] as num).toDouble(),
      anrRate: (json['anrRate'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$PlayConsoleMetricsToJson(_PlayConsoleMetrics instance) =>
    <String, dynamic>{
      'revenue': instance.revenue,
      'installs': instance.installs,
      'activeDevices': instance.activeDevices,
      'averageRating': instance.averageRating,
      'crashRate': instance.crashRate,
      'anrRate': instance.anrRate,
      'date': instance.date.toIso8601String(),
    };
