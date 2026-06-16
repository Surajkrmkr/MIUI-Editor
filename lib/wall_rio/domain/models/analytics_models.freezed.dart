// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdMobMetrics {

 double get earnings; int get impressions; double get ecpm; double get matchRate; int get requests; DateTime get date;
/// Create a copy of AdMobMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdMobMetricsCopyWith<AdMobMetrics> get copyWith => _$AdMobMetricsCopyWithImpl<AdMobMetrics>(this as AdMobMetrics, _$identity);

  /// Serializes this AdMobMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdMobMetrics&&(identical(other.earnings, earnings) || other.earnings == earnings)&&(identical(other.impressions, impressions) || other.impressions == impressions)&&(identical(other.ecpm, ecpm) || other.ecpm == ecpm)&&(identical(other.matchRate, matchRate) || other.matchRate == matchRate)&&(identical(other.requests, requests) || other.requests == requests)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,earnings,impressions,ecpm,matchRate,requests,date);

@override
String toString() {
  return 'AdMobMetrics(earnings: $earnings, impressions: $impressions, ecpm: $ecpm, matchRate: $matchRate, requests: $requests, date: $date)';
}


}

/// @nodoc
abstract mixin class $AdMobMetricsCopyWith<$Res>  {
  factory $AdMobMetricsCopyWith(AdMobMetrics value, $Res Function(AdMobMetrics) _then) = _$AdMobMetricsCopyWithImpl;
@useResult
$Res call({
 double earnings, int impressions, double ecpm, double matchRate, int requests, DateTime date
});




}
/// @nodoc
class _$AdMobMetricsCopyWithImpl<$Res>
    implements $AdMobMetricsCopyWith<$Res> {
  _$AdMobMetricsCopyWithImpl(this._self, this._then);

  final AdMobMetrics _self;
  final $Res Function(AdMobMetrics) _then;

/// Create a copy of AdMobMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? earnings = null,Object? impressions = null,Object? ecpm = null,Object? matchRate = null,Object? requests = null,Object? date = null,}) {
  return _then(_self.copyWith(
earnings: null == earnings ? _self.earnings : earnings // ignore: cast_nullable_to_non_nullable
as double,impressions: null == impressions ? _self.impressions : impressions // ignore: cast_nullable_to_non_nullable
as int,ecpm: null == ecpm ? _self.ecpm : ecpm // ignore: cast_nullable_to_non_nullable
as double,matchRate: null == matchRate ? _self.matchRate : matchRate // ignore: cast_nullable_to_non_nullable
as double,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AdMobMetrics].
extension AdMobMetricsPatterns on AdMobMetrics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdMobMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdMobMetrics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdMobMetrics value)  $default,){
final _that = this;
switch (_that) {
case _AdMobMetrics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdMobMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _AdMobMetrics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double earnings,  int impressions,  double ecpm,  double matchRate,  int requests,  DateTime date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdMobMetrics() when $default != null:
return $default(_that.earnings,_that.impressions,_that.ecpm,_that.matchRate,_that.requests,_that.date);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double earnings,  int impressions,  double ecpm,  double matchRate,  int requests,  DateTime date)  $default,) {final _that = this;
switch (_that) {
case _AdMobMetrics():
return $default(_that.earnings,_that.impressions,_that.ecpm,_that.matchRate,_that.requests,_that.date);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double earnings,  int impressions,  double ecpm,  double matchRate,  int requests,  DateTime date)?  $default,) {final _that = this;
switch (_that) {
case _AdMobMetrics() when $default != null:
return $default(_that.earnings,_that.impressions,_that.ecpm,_that.matchRate,_that.requests,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdMobMetrics implements AdMobMetrics {
  const _AdMobMetrics({required this.earnings, required this.impressions, required this.ecpm, required this.matchRate, required this.requests, required this.date});
  factory _AdMobMetrics.fromJson(Map<String, dynamic> json) => _$AdMobMetricsFromJson(json);

@override final  double earnings;
@override final  int impressions;
@override final  double ecpm;
@override final  double matchRate;
@override final  int requests;
@override final  DateTime date;

/// Create a copy of AdMobMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdMobMetricsCopyWith<_AdMobMetrics> get copyWith => __$AdMobMetricsCopyWithImpl<_AdMobMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdMobMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdMobMetrics&&(identical(other.earnings, earnings) || other.earnings == earnings)&&(identical(other.impressions, impressions) || other.impressions == impressions)&&(identical(other.ecpm, ecpm) || other.ecpm == ecpm)&&(identical(other.matchRate, matchRate) || other.matchRate == matchRate)&&(identical(other.requests, requests) || other.requests == requests)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,earnings,impressions,ecpm,matchRate,requests,date);

@override
String toString() {
  return 'AdMobMetrics(earnings: $earnings, impressions: $impressions, ecpm: $ecpm, matchRate: $matchRate, requests: $requests, date: $date)';
}


}

/// @nodoc
abstract mixin class _$AdMobMetricsCopyWith<$Res> implements $AdMobMetricsCopyWith<$Res> {
  factory _$AdMobMetricsCopyWith(_AdMobMetrics value, $Res Function(_AdMobMetrics) _then) = __$AdMobMetricsCopyWithImpl;
@override @useResult
$Res call({
 double earnings, int impressions, double ecpm, double matchRate, int requests, DateTime date
});




}
/// @nodoc
class __$AdMobMetricsCopyWithImpl<$Res>
    implements _$AdMobMetricsCopyWith<$Res> {
  __$AdMobMetricsCopyWithImpl(this._self, this._then);

  final _AdMobMetrics _self;
  final $Res Function(_AdMobMetrics) _then;

/// Create a copy of AdMobMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? earnings = null,Object? impressions = null,Object? ecpm = null,Object? matchRate = null,Object? requests = null,Object? date = null,}) {
  return _then(_AdMobMetrics(
earnings: null == earnings ? _self.earnings : earnings // ignore: cast_nullable_to_non_nullable
as double,impressions: null == impressions ? _self.impressions : impressions // ignore: cast_nullable_to_non_nullable
as int,ecpm: null == ecpm ? _self.ecpm : ecpm // ignore: cast_nullable_to_non_nullable
as double,matchRate: null == matchRate ? _self.matchRate : matchRate // ignore: cast_nullable_to_non_nullable
as double,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$PlayConsoleMetrics {

 double get revenue; int get installs; int get activeDevices; double get averageRating; double get crashRate; double get anrRate; DateTime get date;
/// Create a copy of PlayConsoleMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayConsoleMetricsCopyWith<PlayConsoleMetrics> get copyWith => _$PlayConsoleMetricsCopyWithImpl<PlayConsoleMetrics>(this as PlayConsoleMetrics, _$identity);

  /// Serializes this PlayConsoleMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayConsoleMetrics&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.installs, installs) || other.installs == installs)&&(identical(other.activeDevices, activeDevices) || other.activeDevices == activeDevices)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.crashRate, crashRate) || other.crashRate == crashRate)&&(identical(other.anrRate, anrRate) || other.anrRate == anrRate)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revenue,installs,activeDevices,averageRating,crashRate,anrRate,date);

@override
String toString() {
  return 'PlayConsoleMetrics(revenue: $revenue, installs: $installs, activeDevices: $activeDevices, averageRating: $averageRating, crashRate: $crashRate, anrRate: $anrRate, date: $date)';
}


}

/// @nodoc
abstract mixin class $PlayConsoleMetricsCopyWith<$Res>  {
  factory $PlayConsoleMetricsCopyWith(PlayConsoleMetrics value, $Res Function(PlayConsoleMetrics) _then) = _$PlayConsoleMetricsCopyWithImpl;
@useResult
$Res call({
 double revenue, int installs, int activeDevices, double averageRating, double crashRate, double anrRate, DateTime date
});




}
/// @nodoc
class _$PlayConsoleMetricsCopyWithImpl<$Res>
    implements $PlayConsoleMetricsCopyWith<$Res> {
  _$PlayConsoleMetricsCopyWithImpl(this._self, this._then);

  final PlayConsoleMetrics _self;
  final $Res Function(PlayConsoleMetrics) _then;

/// Create a copy of PlayConsoleMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revenue = null,Object? installs = null,Object? activeDevices = null,Object? averageRating = null,Object? crashRate = null,Object? anrRate = null,Object? date = null,}) {
  return _then(_self.copyWith(
revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as double,installs: null == installs ? _self.installs : installs // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,averageRating: null == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double,crashRate: null == crashRate ? _self.crashRate : crashRate // ignore: cast_nullable_to_non_nullable
as double,anrRate: null == anrRate ? _self.anrRate : anrRate // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayConsoleMetrics].
extension PlayConsoleMetricsPatterns on PlayConsoleMetrics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayConsoleMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayConsoleMetrics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayConsoleMetrics value)  $default,){
final _that = this;
switch (_that) {
case _PlayConsoleMetrics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayConsoleMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _PlayConsoleMetrics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double revenue,  int installs,  int activeDevices,  double averageRating,  double crashRate,  double anrRate,  DateTime date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayConsoleMetrics() when $default != null:
return $default(_that.revenue,_that.installs,_that.activeDevices,_that.averageRating,_that.crashRate,_that.anrRate,_that.date);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double revenue,  int installs,  int activeDevices,  double averageRating,  double crashRate,  double anrRate,  DateTime date)  $default,) {final _that = this;
switch (_that) {
case _PlayConsoleMetrics():
return $default(_that.revenue,_that.installs,_that.activeDevices,_that.averageRating,_that.crashRate,_that.anrRate,_that.date);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double revenue,  int installs,  int activeDevices,  double averageRating,  double crashRate,  double anrRate,  DateTime date)?  $default,) {final _that = this;
switch (_that) {
case _PlayConsoleMetrics() when $default != null:
return $default(_that.revenue,_that.installs,_that.activeDevices,_that.averageRating,_that.crashRate,_that.anrRate,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayConsoleMetrics implements PlayConsoleMetrics {
  const _PlayConsoleMetrics({required this.revenue, required this.installs, required this.activeDevices, required this.averageRating, required this.crashRate, required this.anrRate, required this.date});
  factory _PlayConsoleMetrics.fromJson(Map<String, dynamic> json) => _$PlayConsoleMetricsFromJson(json);

@override final  double revenue;
@override final  int installs;
@override final  int activeDevices;
@override final  double averageRating;
@override final  double crashRate;
@override final  double anrRate;
@override final  DateTime date;

/// Create a copy of PlayConsoleMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayConsoleMetricsCopyWith<_PlayConsoleMetrics> get copyWith => __$PlayConsoleMetricsCopyWithImpl<_PlayConsoleMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayConsoleMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayConsoleMetrics&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.installs, installs) || other.installs == installs)&&(identical(other.activeDevices, activeDevices) || other.activeDevices == activeDevices)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.crashRate, crashRate) || other.crashRate == crashRate)&&(identical(other.anrRate, anrRate) || other.anrRate == anrRate)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revenue,installs,activeDevices,averageRating,crashRate,anrRate,date);

@override
String toString() {
  return 'PlayConsoleMetrics(revenue: $revenue, installs: $installs, activeDevices: $activeDevices, averageRating: $averageRating, crashRate: $crashRate, anrRate: $anrRate, date: $date)';
}


}

/// @nodoc
abstract mixin class _$PlayConsoleMetricsCopyWith<$Res> implements $PlayConsoleMetricsCopyWith<$Res> {
  factory _$PlayConsoleMetricsCopyWith(_PlayConsoleMetrics value, $Res Function(_PlayConsoleMetrics) _then) = __$PlayConsoleMetricsCopyWithImpl;
@override @useResult
$Res call({
 double revenue, int installs, int activeDevices, double averageRating, double crashRate, double anrRate, DateTime date
});




}
/// @nodoc
class __$PlayConsoleMetricsCopyWithImpl<$Res>
    implements _$PlayConsoleMetricsCopyWith<$Res> {
  __$PlayConsoleMetricsCopyWithImpl(this._self, this._then);

  final _PlayConsoleMetrics _self;
  final $Res Function(_PlayConsoleMetrics) _then;

/// Create a copy of PlayConsoleMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revenue = null,Object? installs = null,Object? activeDevices = null,Object? averageRating = null,Object? crashRate = null,Object? anrRate = null,Object? date = null,}) {
  return _then(_PlayConsoleMetrics(
revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as double,installs: null == installs ? _self.installs : installs // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,averageRating: null == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double,crashRate: null == crashRate ? _self.crashRate : crashRate // ignore: cast_nullable_to_non_nullable
as double,anrRate: null == anrRate ? _self.anrRate : anrRate // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$CombinedAnalytics {

 AdMobMetrics? get admob; PlayConsoleMetrics? get play; DateTime get lastRefreshed;
/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CombinedAnalyticsCopyWith<CombinedAnalytics> get copyWith => _$CombinedAnalyticsCopyWithImpl<CombinedAnalytics>(this as CombinedAnalytics, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CombinedAnalytics&&(identical(other.admob, admob) || other.admob == admob)&&(identical(other.play, play) || other.play == play)&&(identical(other.lastRefreshed, lastRefreshed) || other.lastRefreshed == lastRefreshed));
}


@override
int get hashCode => Object.hash(runtimeType,admob,play,lastRefreshed);

@override
String toString() {
  return 'CombinedAnalytics(admob: $admob, play: $play, lastRefreshed: $lastRefreshed)';
}


}

/// @nodoc
abstract mixin class $CombinedAnalyticsCopyWith<$Res>  {
  factory $CombinedAnalyticsCopyWith(CombinedAnalytics value, $Res Function(CombinedAnalytics) _then) = _$CombinedAnalyticsCopyWithImpl;
@useResult
$Res call({
 AdMobMetrics? admob, PlayConsoleMetrics? play, DateTime lastRefreshed
});


$AdMobMetricsCopyWith<$Res>? get admob;$PlayConsoleMetricsCopyWith<$Res>? get play;

}
/// @nodoc
class _$CombinedAnalyticsCopyWithImpl<$Res>
    implements $CombinedAnalyticsCopyWith<$Res> {
  _$CombinedAnalyticsCopyWithImpl(this._self, this._then);

  final CombinedAnalytics _self;
  final $Res Function(CombinedAnalytics) _then;

/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? admob = freezed,Object? play = freezed,Object? lastRefreshed = null,}) {
  return _then(_self.copyWith(
admob: freezed == admob ? _self.admob : admob // ignore: cast_nullable_to_non_nullable
as AdMobMetrics?,play: freezed == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as PlayConsoleMetrics?,lastRefreshed: null == lastRefreshed ? _self.lastRefreshed : lastRefreshed // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdMobMetricsCopyWith<$Res>? get admob {
    if (_self.admob == null) {
    return null;
  }

  return $AdMobMetricsCopyWith<$Res>(_self.admob!, (value) {
    return _then(_self.copyWith(admob: value));
  });
}/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayConsoleMetricsCopyWith<$Res>? get play {
    if (_self.play == null) {
    return null;
  }

  return $PlayConsoleMetricsCopyWith<$Res>(_self.play!, (value) {
    return _then(_self.copyWith(play: value));
  });
}
}


/// Adds pattern-matching-related methods to [CombinedAnalytics].
extension CombinedAnalyticsPatterns on CombinedAnalytics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CombinedAnalytics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CombinedAnalytics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CombinedAnalytics value)  $default,){
final _that = this;
switch (_that) {
case _CombinedAnalytics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CombinedAnalytics value)?  $default,){
final _that = this;
switch (_that) {
case _CombinedAnalytics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdMobMetrics? admob,  PlayConsoleMetrics? play,  DateTime lastRefreshed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CombinedAnalytics() when $default != null:
return $default(_that.admob,_that.play,_that.lastRefreshed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdMobMetrics? admob,  PlayConsoleMetrics? play,  DateTime lastRefreshed)  $default,) {final _that = this;
switch (_that) {
case _CombinedAnalytics():
return $default(_that.admob,_that.play,_that.lastRefreshed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdMobMetrics? admob,  PlayConsoleMetrics? play,  DateTime lastRefreshed)?  $default,) {final _that = this;
switch (_that) {
case _CombinedAnalytics() when $default != null:
return $default(_that.admob,_that.play,_that.lastRefreshed);case _:
  return null;

}
}

}

/// @nodoc


class _CombinedAnalytics implements CombinedAnalytics {
  const _CombinedAnalytics({this.admob, this.play, required this.lastRefreshed});
  

@override final  AdMobMetrics? admob;
@override final  PlayConsoleMetrics? play;
@override final  DateTime lastRefreshed;

/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CombinedAnalyticsCopyWith<_CombinedAnalytics> get copyWith => __$CombinedAnalyticsCopyWithImpl<_CombinedAnalytics>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CombinedAnalytics&&(identical(other.admob, admob) || other.admob == admob)&&(identical(other.play, play) || other.play == play)&&(identical(other.lastRefreshed, lastRefreshed) || other.lastRefreshed == lastRefreshed));
}


@override
int get hashCode => Object.hash(runtimeType,admob,play,lastRefreshed);

@override
String toString() {
  return 'CombinedAnalytics(admob: $admob, play: $play, lastRefreshed: $lastRefreshed)';
}


}

/// @nodoc
abstract mixin class _$CombinedAnalyticsCopyWith<$Res> implements $CombinedAnalyticsCopyWith<$Res> {
  factory _$CombinedAnalyticsCopyWith(_CombinedAnalytics value, $Res Function(_CombinedAnalytics) _then) = __$CombinedAnalyticsCopyWithImpl;
@override @useResult
$Res call({
 AdMobMetrics? admob, PlayConsoleMetrics? play, DateTime lastRefreshed
});


@override $AdMobMetricsCopyWith<$Res>? get admob;@override $PlayConsoleMetricsCopyWith<$Res>? get play;

}
/// @nodoc
class __$CombinedAnalyticsCopyWithImpl<$Res>
    implements _$CombinedAnalyticsCopyWith<$Res> {
  __$CombinedAnalyticsCopyWithImpl(this._self, this._then);

  final _CombinedAnalytics _self;
  final $Res Function(_CombinedAnalytics) _then;

/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? admob = freezed,Object? play = freezed,Object? lastRefreshed = null,}) {
  return _then(_CombinedAnalytics(
admob: freezed == admob ? _self.admob : admob // ignore: cast_nullable_to_non_nullable
as AdMobMetrics?,play: freezed == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as PlayConsoleMetrics?,lastRefreshed: null == lastRefreshed ? _self.lastRefreshed : lastRefreshed // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdMobMetricsCopyWith<$Res>? get admob {
    if (_self.admob == null) {
    return null;
  }

  return $AdMobMetricsCopyWith<$Res>(_self.admob!, (value) {
    return _then(_self.copyWith(admob: value));
  });
}/// Create a copy of CombinedAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayConsoleMetricsCopyWith<$Res>? get play {
    if (_self.play == null) {
    return null;
  }

  return $PlayConsoleMetricsCopyWith<$Res>(_self.play!, (value) {
    return _then(_self.copyWith(play: value));
  });
}
}

// dart format on
