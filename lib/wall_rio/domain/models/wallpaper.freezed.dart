// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallpaper.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Wallpaper {

 dynamic get id;// Flexible ID (int or string)
 String get name; String get author; String get url; String get thumbnail; List<String> get tags; String get category; List<String> get color; bool get isPremium; String get subjectId;// Live Wallpaper specific fields
@JsonKey(includeIfNull: false) String? get videoUrl;@JsonKey(includeIfNull: false) String? get previewVideo;@JsonKey(includeIfNull: false) String? get type;
/// Create a copy of Wallpaper
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WallpaperCopyWith<Wallpaper> get copyWith => _$WallpaperCopyWithImpl<Wallpaper>(this as Wallpaper, _$identity);

  /// Serializes this Wallpaper to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Wallpaper&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.name, name) || other.name == name)&&(identical(other.author, author) || other.author == author)&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.color, color)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.previewVideo, previewVideo) || other.previewVideo == previewVideo)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),name,author,url,thumbnail,const DeepCollectionEquality().hash(tags),category,const DeepCollectionEquality().hash(color),isPremium,subjectId,videoUrl,previewVideo,type);

@override
String toString() {
  return 'Wallpaper(id: $id, name: $name, author: $author, url: $url, thumbnail: $thumbnail, tags: $tags, category: $category, color: $color, isPremium: $isPremium, subjectId: $subjectId, videoUrl: $videoUrl, previewVideo: $previewVideo, type: $type)';
}


}

/// @nodoc
abstract mixin class $WallpaperCopyWith<$Res>  {
  factory $WallpaperCopyWith(Wallpaper value, $Res Function(Wallpaper) _then) = _$WallpaperCopyWithImpl;
@useResult
$Res call({
 dynamic id, String name, String author, String url, String thumbnail, List<String> tags, String category, List<String> color, bool isPremium, String subjectId,@JsonKey(includeIfNull: false) String? videoUrl,@JsonKey(includeIfNull: false) String? previewVideo,@JsonKey(includeIfNull: false) String? type
});




}
/// @nodoc
class _$WallpaperCopyWithImpl<$Res>
    implements $WallpaperCopyWith<$Res> {
  _$WallpaperCopyWithImpl(this._self, this._then);

  final Wallpaper _self;
  final $Res Function(Wallpaper) _then;

/// Create a copy of Wallpaper
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? author = null,Object? url = null,Object? thumbnail = null,Object? tags = null,Object? category = null,Object? color = null,Object? isPremium = null,Object? subjectId = null,Object? videoUrl = freezed,Object? previewVideo = freezed,Object? type = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as dynamic,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as List<String>,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,previewVideo: freezed == previewVideo ? _self.previewVideo : previewVideo // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Wallpaper].
extension WallpaperPatterns on Wallpaper {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Wallpaper value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Wallpaper() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Wallpaper value)  $default,){
final _that = this;
switch (_that) {
case _Wallpaper():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Wallpaper value)?  $default,){
final _that = this;
switch (_that) {
case _Wallpaper() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( dynamic id,  String name,  String author,  String url,  String thumbnail,  List<String> tags,  String category,  List<String> color,  bool isPremium,  String subjectId, @JsonKey(includeIfNull: false)  String? videoUrl, @JsonKey(includeIfNull: false)  String? previewVideo, @JsonKey(includeIfNull: false)  String? type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Wallpaper() when $default != null:
return $default(_that.id,_that.name,_that.author,_that.url,_that.thumbnail,_that.tags,_that.category,_that.color,_that.isPremium,_that.subjectId,_that.videoUrl,_that.previewVideo,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( dynamic id,  String name,  String author,  String url,  String thumbnail,  List<String> tags,  String category,  List<String> color,  bool isPremium,  String subjectId, @JsonKey(includeIfNull: false)  String? videoUrl, @JsonKey(includeIfNull: false)  String? previewVideo, @JsonKey(includeIfNull: false)  String? type)  $default,) {final _that = this;
switch (_that) {
case _Wallpaper():
return $default(_that.id,_that.name,_that.author,_that.url,_that.thumbnail,_that.tags,_that.category,_that.color,_that.isPremium,_that.subjectId,_that.videoUrl,_that.previewVideo,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( dynamic id,  String name,  String author,  String url,  String thumbnail,  List<String> tags,  String category,  List<String> color,  bool isPremium,  String subjectId, @JsonKey(includeIfNull: false)  String? videoUrl, @JsonKey(includeIfNull: false)  String? previewVideo, @JsonKey(includeIfNull: false)  String? type)?  $default,) {final _that = this;
switch (_that) {
case _Wallpaper() when $default != null:
return $default(_that.id,_that.name,_that.author,_that.url,_that.thumbnail,_that.tags,_that.category,_that.color,_that.isPremium,_that.subjectId,_that.videoUrl,_that.previewVideo,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Wallpaper implements Wallpaper {
  const _Wallpaper({required this.id, required this.name, this.author = 'WallRio', this.url = '', this.thumbnail = '', final  List<String> tags = const [], this.category = '', final  List<String> color = const [], this.isPremium = false, this.subjectId = '', @JsonKey(includeIfNull: false) this.videoUrl, @JsonKey(includeIfNull: false) this.previewVideo, @JsonKey(includeIfNull: false) this.type}): _tags = tags,_color = color;
  factory _Wallpaper.fromJson(Map<String, dynamic> json) => _$WallpaperFromJson(json);

@override final  dynamic id;
// Flexible ID (int or string)
@override final  String name;
@override@JsonKey() final  String author;
@override@JsonKey() final  String url;
@override@JsonKey() final  String thumbnail;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  String category;
 final  List<String> _color;
@override@JsonKey() List<String> get color {
  if (_color is EqualUnmodifiableListView) return _color;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_color);
}

@override@JsonKey() final  bool isPremium;
@override@JsonKey() final  String subjectId;
// Live Wallpaper specific fields
@override@JsonKey(includeIfNull: false) final  String? videoUrl;
@override@JsonKey(includeIfNull: false) final  String? previewVideo;
@override@JsonKey(includeIfNull: false) final  String? type;

/// Create a copy of Wallpaper
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WallpaperCopyWith<_Wallpaper> get copyWith => __$WallpaperCopyWithImpl<_Wallpaper>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WallpaperToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Wallpaper&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.name, name) || other.name == name)&&(identical(other.author, author) || other.author == author)&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._color, _color)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.previewVideo, previewVideo) || other.previewVideo == previewVideo)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),name,author,url,thumbnail,const DeepCollectionEquality().hash(_tags),category,const DeepCollectionEquality().hash(_color),isPremium,subjectId,videoUrl,previewVideo,type);

@override
String toString() {
  return 'Wallpaper(id: $id, name: $name, author: $author, url: $url, thumbnail: $thumbnail, tags: $tags, category: $category, color: $color, isPremium: $isPremium, subjectId: $subjectId, videoUrl: $videoUrl, previewVideo: $previewVideo, type: $type)';
}


}

/// @nodoc
abstract mixin class _$WallpaperCopyWith<$Res> implements $WallpaperCopyWith<$Res> {
  factory _$WallpaperCopyWith(_Wallpaper value, $Res Function(_Wallpaper) _then) = __$WallpaperCopyWithImpl;
@override @useResult
$Res call({
 dynamic id, String name, String author, String url, String thumbnail, List<String> tags, String category, List<String> color, bool isPremium, String subjectId,@JsonKey(includeIfNull: false) String? videoUrl,@JsonKey(includeIfNull: false) String? previewVideo,@JsonKey(includeIfNull: false) String? type
});




}
/// @nodoc
class __$WallpaperCopyWithImpl<$Res>
    implements _$WallpaperCopyWith<$Res> {
  __$WallpaperCopyWithImpl(this._self, this._then);

  final _Wallpaper _self;
  final $Res Function(_Wallpaper) _then;

/// Create a copy of Wallpaper
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? author = null,Object? url = null,Object? thumbnail = null,Object? tags = null,Object? category = null,Object? color = null,Object? isPremium = null,Object? subjectId = null,Object? videoUrl = freezed,Object? previewVideo = freezed,Object? type = freezed,}) {
  return _then(_Wallpaper(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as dynamic,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self._color : color // ignore: cast_nullable_to_non_nullable
as List<String>,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,previewVideo: freezed == previewVideo ? _self.previewVideo : previewVideo // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RioData {

 List<Map<String, dynamic>> get subscription; List<Map<String, dynamic>> get banners; Map<String, dynamic> get search; List<Wallpaper> get walls;// Support for collections-based structure
 List<Map<String, dynamic>>? get collections;
/// Create a copy of RioData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RioDataCopyWith<RioData> get copyWith => _$RioDataCopyWithImpl<RioData>(this as RioData, _$identity);

  /// Serializes this RioData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RioData&&const DeepCollectionEquality().equals(other.subscription, subscription)&&const DeepCollectionEquality().equals(other.banners, banners)&&const DeepCollectionEquality().equals(other.search, search)&&const DeepCollectionEquality().equals(other.walls, walls)&&const DeepCollectionEquality().equals(other.collections, collections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(subscription),const DeepCollectionEquality().hash(banners),const DeepCollectionEquality().hash(search),const DeepCollectionEquality().hash(walls),const DeepCollectionEquality().hash(collections));

@override
String toString() {
  return 'RioData(subscription: $subscription, banners: $banners, search: $search, walls: $walls, collections: $collections)';
}


}

/// @nodoc
abstract mixin class $RioDataCopyWith<$Res>  {
  factory $RioDataCopyWith(RioData value, $Res Function(RioData) _then) = _$RioDataCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> subscription, List<Map<String, dynamic>> banners, Map<String, dynamic> search, List<Wallpaper> walls, List<Map<String, dynamic>>? collections
});




}
/// @nodoc
class _$RioDataCopyWithImpl<$Res>
    implements $RioDataCopyWith<$Res> {
  _$RioDataCopyWithImpl(this._self, this._then);

  final RioData _self;
  final $Res Function(RioData) _then;

/// Create a copy of RioData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subscription = null,Object? banners = null,Object? search = null,Object? walls = null,Object? collections = freezed,}) {
  return _then(_self.copyWith(
subscription: null == subscription ? _self.subscription : subscription // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,banners: null == banners ? _self.banners : banners // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,walls: null == walls ? _self.walls : walls // ignore: cast_nullable_to_non_nullable
as List<Wallpaper>,collections: freezed == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,
  ));
}

}


/// Adds pattern-matching-related methods to [RioData].
extension RioDataPatterns on RioData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RioData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RioData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RioData value)  $default,){
final _that = this;
switch (_that) {
case _RioData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RioData value)?  $default,){
final _that = this;
switch (_that) {
case _RioData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Map<String, dynamic>> subscription,  List<Map<String, dynamic>> banners,  Map<String, dynamic> search,  List<Wallpaper> walls,  List<Map<String, dynamic>>? collections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RioData() when $default != null:
return $default(_that.subscription,_that.banners,_that.search,_that.walls,_that.collections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Map<String, dynamic>> subscription,  List<Map<String, dynamic>> banners,  Map<String, dynamic> search,  List<Wallpaper> walls,  List<Map<String, dynamic>>? collections)  $default,) {final _that = this;
switch (_that) {
case _RioData():
return $default(_that.subscription,_that.banners,_that.search,_that.walls,_that.collections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Map<String, dynamic>> subscription,  List<Map<String, dynamic>> banners,  Map<String, dynamic> search,  List<Wallpaper> walls,  List<Map<String, dynamic>>? collections)?  $default,) {final _that = this;
switch (_that) {
case _RioData() when $default != null:
return $default(_that.subscription,_that.banners,_that.search,_that.walls,_that.collections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RioData implements RioData {
  const _RioData({final  List<Map<String, dynamic>> subscription = const [], final  List<Map<String, dynamic>> banners = const [], final  Map<String, dynamic> search = const {}, final  List<Wallpaper> walls = const [], final  List<Map<String, dynamic>>? collections}): _subscription = subscription,_banners = banners,_search = search,_walls = walls,_collections = collections;
  factory _RioData.fromJson(Map<String, dynamic> json) => _$RioDataFromJson(json);

 final  List<Map<String, dynamic>> _subscription;
@override@JsonKey() List<Map<String, dynamic>> get subscription {
  if (_subscription is EqualUnmodifiableListView) return _subscription;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subscription);
}

 final  List<Map<String, dynamic>> _banners;
@override@JsonKey() List<Map<String, dynamic>> get banners {
  if (_banners is EqualUnmodifiableListView) return _banners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_banners);
}

 final  Map<String, dynamic> _search;
@override@JsonKey() Map<String, dynamic> get search {
  if (_search is EqualUnmodifiableMapView) return _search;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_search);
}

 final  List<Wallpaper> _walls;
@override@JsonKey() List<Wallpaper> get walls {
  if (_walls is EqualUnmodifiableListView) return _walls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_walls);
}

// Support for collections-based structure
 final  List<Map<String, dynamic>>? _collections;
// Support for collections-based structure
@override List<Map<String, dynamic>>? get collections {
  final value = _collections;
  if (value == null) return null;
  if (_collections is EqualUnmodifiableListView) return _collections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of RioData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RioDataCopyWith<_RioData> get copyWith => __$RioDataCopyWithImpl<_RioData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RioDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RioData&&const DeepCollectionEquality().equals(other._subscription, _subscription)&&const DeepCollectionEquality().equals(other._banners, _banners)&&const DeepCollectionEquality().equals(other._search, _search)&&const DeepCollectionEquality().equals(other._walls, _walls)&&const DeepCollectionEquality().equals(other._collections, _collections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_subscription),const DeepCollectionEquality().hash(_banners),const DeepCollectionEquality().hash(_search),const DeepCollectionEquality().hash(_walls),const DeepCollectionEquality().hash(_collections));

@override
String toString() {
  return 'RioData(subscription: $subscription, banners: $banners, search: $search, walls: $walls, collections: $collections)';
}


}

/// @nodoc
abstract mixin class _$RioDataCopyWith<$Res> implements $RioDataCopyWith<$Res> {
  factory _$RioDataCopyWith(_RioData value, $Res Function(_RioData) _then) = __$RioDataCopyWithImpl;
@override @useResult
$Res call({
 List<Map<String, dynamic>> subscription, List<Map<String, dynamic>> banners, Map<String, dynamic> search, List<Wallpaper> walls, List<Map<String, dynamic>>? collections
});




}
/// @nodoc
class __$RioDataCopyWithImpl<$Res>
    implements _$RioDataCopyWith<$Res> {
  __$RioDataCopyWithImpl(this._self, this._then);

  final _RioData _self;
  final $Res Function(_RioData) _then;

/// Create a copy of RioData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subscription = null,Object? banners = null,Object? search = null,Object? walls = null,Object? collections = freezed,}) {
  return _then(_RioData(
subscription: null == subscription ? _self._subscription : subscription // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,banners: null == banners ? _self._banners : banners // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,search: null == search ? _self._search : search // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,walls: null == walls ? _self._walls : walls // ignore: cast_nullable_to_non_nullable
as List<Wallpaper>,collections: freezed == collections ? _self._collections : collections // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,
  ));
}


}

// dart format on
