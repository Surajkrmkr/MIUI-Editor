// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PushCampaign {

 String get id; String get title; String get body; String? get imageUrl; String? get deepLink; String get targetTopic; DateTime get createdAt; DateTime? get scheduledFor; String get status;// pending, sent, failed, scheduled
 int? get sentCount; String? get errorMessage;
/// Create a copy of PushCampaign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushCampaignCopyWith<PushCampaign> get copyWith => _$PushCampaignCopyWithImpl<PushCampaign>(this as PushCampaign, _$identity);

  /// Serializes this PushCampaign to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushCampaign&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&(identical(other.targetTopic, targetTopic) || other.targetTopic == targetTopic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.scheduledFor, scheduledFor) || other.scheduledFor == scheduledFor)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentCount, sentCount) || other.sentCount == sentCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,body,imageUrl,deepLink,targetTopic,createdAt,scheduledFor,status,sentCount,errorMessage);

@override
String toString() {
  return 'PushCampaign(id: $id, title: $title, body: $body, imageUrl: $imageUrl, deepLink: $deepLink, targetTopic: $targetTopic, createdAt: $createdAt, scheduledFor: $scheduledFor, status: $status, sentCount: $sentCount, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $PushCampaignCopyWith<$Res>  {
  factory $PushCampaignCopyWith(PushCampaign value, $Res Function(PushCampaign) _then) = _$PushCampaignCopyWithImpl;
@useResult
$Res call({
 String id, String title, String body, String? imageUrl, String? deepLink, String targetTopic, DateTime createdAt, DateTime? scheduledFor, String status, int? sentCount, String? errorMessage
});




}
/// @nodoc
class _$PushCampaignCopyWithImpl<$Res>
    implements $PushCampaignCopyWith<$Res> {
  _$PushCampaignCopyWithImpl(this._self, this._then);

  final PushCampaign _self;
  final $Res Function(PushCampaign) _then;

/// Create a copy of PushCampaign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? body = null,Object? imageUrl = freezed,Object? deepLink = freezed,Object? targetTopic = null,Object? createdAt = null,Object? scheduledFor = freezed,Object? status = null,Object? sentCount = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,targetTopic: null == targetTopic ? _self.targetTopic : targetTopic // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sentCount: freezed == sentCount ? _self.sentCount : sentCount // ignore: cast_nullable_to_non_nullable
as int?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushCampaign].
extension PushCampaignPatterns on PushCampaign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushCampaign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushCampaign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushCampaign value)  $default,){
final _that = this;
switch (_that) {
case _PushCampaign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushCampaign value)?  $default,){
final _that = this;
switch (_that) {
case _PushCampaign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String body,  String? imageUrl,  String? deepLink,  String targetTopic,  DateTime createdAt,  DateTime? scheduledFor,  String status,  int? sentCount,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushCampaign() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.imageUrl,_that.deepLink,_that.targetTopic,_that.createdAt,_that.scheduledFor,_that.status,_that.sentCount,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String body,  String? imageUrl,  String? deepLink,  String targetTopic,  DateTime createdAt,  DateTime? scheduledFor,  String status,  int? sentCount,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _PushCampaign():
return $default(_that.id,_that.title,_that.body,_that.imageUrl,_that.deepLink,_that.targetTopic,_that.createdAt,_that.scheduledFor,_that.status,_that.sentCount,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String body,  String? imageUrl,  String? deepLink,  String targetTopic,  DateTime createdAt,  DateTime? scheduledFor,  String status,  int? sentCount,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _PushCampaign() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.imageUrl,_that.deepLink,_that.targetTopic,_that.createdAt,_that.scheduledFor,_that.status,_that.sentCount,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushCampaign implements PushCampaign {
  const _PushCampaign({required this.id, required this.title, required this.body, this.imageUrl, this.deepLink, required this.targetTopic, required this.createdAt, this.scheduledFor, this.status = 'pending', this.sentCount, this.errorMessage});
  factory _PushCampaign.fromJson(Map<String, dynamic> json) => _$PushCampaignFromJson(json);

@override final  String id;
@override final  String title;
@override final  String body;
@override final  String? imageUrl;
@override final  String? deepLink;
@override final  String targetTopic;
@override final  DateTime createdAt;
@override final  DateTime? scheduledFor;
@override@JsonKey() final  String status;
// pending, sent, failed, scheduled
@override final  int? sentCount;
@override final  String? errorMessage;

/// Create a copy of PushCampaign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushCampaignCopyWith<_PushCampaign> get copyWith => __$PushCampaignCopyWithImpl<_PushCampaign>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushCampaignToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushCampaign&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&(identical(other.targetTopic, targetTopic) || other.targetTopic == targetTopic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.scheduledFor, scheduledFor) || other.scheduledFor == scheduledFor)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentCount, sentCount) || other.sentCount == sentCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,body,imageUrl,deepLink,targetTopic,createdAt,scheduledFor,status,sentCount,errorMessage);

@override
String toString() {
  return 'PushCampaign(id: $id, title: $title, body: $body, imageUrl: $imageUrl, deepLink: $deepLink, targetTopic: $targetTopic, createdAt: $createdAt, scheduledFor: $scheduledFor, status: $status, sentCount: $sentCount, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$PushCampaignCopyWith<$Res> implements $PushCampaignCopyWith<$Res> {
  factory _$PushCampaignCopyWith(_PushCampaign value, $Res Function(_PushCampaign) _then) = __$PushCampaignCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String body, String? imageUrl, String? deepLink, String targetTopic, DateTime createdAt, DateTime? scheduledFor, String status, int? sentCount, String? errorMessage
});




}
/// @nodoc
class __$PushCampaignCopyWithImpl<$Res>
    implements _$PushCampaignCopyWith<$Res> {
  __$PushCampaignCopyWithImpl(this._self, this._then);

  final _PushCampaign _self;
  final $Res Function(_PushCampaign) _then;

/// Create a copy of PushCampaign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? body = null,Object? imageUrl = freezed,Object? deepLink = freezed,Object? targetTopic = null,Object? createdAt = null,Object? scheduledFor = freezed,Object? status = null,Object? sentCount = freezed,Object? errorMessage = freezed,}) {
  return _then(_PushCampaign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,targetTopic: null == targetTopic ? _self.targetTopic : targetTopic // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sentCount: freezed == sentCount ? _self.sentCount : sentCount // ignore: cast_nullable_to_non_nullable
as int?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PushTemplate {

 String get id; String get name; String get title; String get body; String? get imageUrl; String? get deepLink; String? get category;
/// Create a copy of PushTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushTemplateCopyWith<PushTemplate> get copyWith => _$PushTemplateCopyWithImpl<PushTemplate>(this as PushTemplate, _$identity);

  /// Serializes this PushTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,title,body,imageUrl,deepLink,category);

@override
String toString() {
  return 'PushTemplate(id: $id, name: $name, title: $title, body: $body, imageUrl: $imageUrl, deepLink: $deepLink, category: $category)';
}


}

/// @nodoc
abstract mixin class $PushTemplateCopyWith<$Res>  {
  factory $PushTemplateCopyWith(PushTemplate value, $Res Function(PushTemplate) _then) = _$PushTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, String title, String body, String? imageUrl, String? deepLink, String? category
});




}
/// @nodoc
class _$PushTemplateCopyWithImpl<$Res>
    implements $PushTemplateCopyWith<$Res> {
  _$PushTemplateCopyWithImpl(this._self, this._then);

  final PushTemplate _self;
  final $Res Function(PushTemplate) _then;

/// Create a copy of PushTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? title = null,Object? body = null,Object? imageUrl = freezed,Object? deepLink = freezed,Object? category = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushTemplate].
extension PushTemplatePatterns on PushTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushTemplate value)  $default,){
final _that = this;
switch (_that) {
case _PushTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _PushTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String title,  String body,  String? imageUrl,  String? deepLink,  String? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushTemplate() when $default != null:
return $default(_that.id,_that.name,_that.title,_that.body,_that.imageUrl,_that.deepLink,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String title,  String body,  String? imageUrl,  String? deepLink,  String? category)  $default,) {final _that = this;
switch (_that) {
case _PushTemplate():
return $default(_that.id,_that.name,_that.title,_that.body,_that.imageUrl,_that.deepLink,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String title,  String body,  String? imageUrl,  String? deepLink,  String? category)?  $default,) {final _that = this;
switch (_that) {
case _PushTemplate() when $default != null:
return $default(_that.id,_that.name,_that.title,_that.body,_that.imageUrl,_that.deepLink,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushTemplate implements PushTemplate {
  const _PushTemplate({required this.id, required this.name, required this.title, required this.body, this.imageUrl, this.deepLink, this.category});
  factory _PushTemplate.fromJson(Map<String, dynamic> json) => _$PushTemplateFromJson(json);

@override final  String id;
@override final  String name;
@override final  String title;
@override final  String body;
@override final  String? imageUrl;
@override final  String? deepLink;
@override final  String? category;

/// Create a copy of PushTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushTemplateCopyWith<_PushTemplate> get copyWith => __$PushTemplateCopyWithImpl<_PushTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,title,body,imageUrl,deepLink,category);

@override
String toString() {
  return 'PushTemplate(id: $id, name: $name, title: $title, body: $body, imageUrl: $imageUrl, deepLink: $deepLink, category: $category)';
}


}

/// @nodoc
abstract mixin class _$PushTemplateCopyWith<$Res> implements $PushTemplateCopyWith<$Res> {
  factory _$PushTemplateCopyWith(_PushTemplate value, $Res Function(_PushTemplate) _then) = __$PushTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String title, String body, String? imageUrl, String? deepLink, String? category
});




}
/// @nodoc
class __$PushTemplateCopyWithImpl<$Res>
    implements _$PushTemplateCopyWith<$Res> {
  __$PushTemplateCopyWithImpl(this._self, this._then);

  final _PushTemplate _self;
  final $Res Function(_PushTemplate) _then;

/// Create a copy of PushTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? title = null,Object? body = null,Object? imageUrl = freezed,Object? deepLink = freezed,Object? category = freezed,}) {
  return _then(_PushTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$FCMTopic {

 String get name; int get subscriberCount; DateTime? get lastUsed;
/// Create a copy of FCMTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FCMTopicCopyWith<FCMTopic> get copyWith => _$FCMTopicCopyWithImpl<FCMTopic>(this as FCMTopic, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FCMTopic&&(identical(other.name, name) || other.name == name)&&(identical(other.subscriberCount, subscriberCount) || other.subscriberCount == subscriberCount)&&(identical(other.lastUsed, lastUsed) || other.lastUsed == lastUsed));
}


@override
int get hashCode => Object.hash(runtimeType,name,subscriberCount,lastUsed);

@override
String toString() {
  return 'FCMTopic(name: $name, subscriberCount: $subscriberCount, lastUsed: $lastUsed)';
}


}

/// @nodoc
abstract mixin class $FCMTopicCopyWith<$Res>  {
  factory $FCMTopicCopyWith(FCMTopic value, $Res Function(FCMTopic) _then) = _$FCMTopicCopyWithImpl;
@useResult
$Res call({
 String name, int subscriberCount, DateTime? lastUsed
});




}
/// @nodoc
class _$FCMTopicCopyWithImpl<$Res>
    implements $FCMTopicCopyWith<$Res> {
  _$FCMTopicCopyWithImpl(this._self, this._then);

  final FCMTopic _self;
  final $Res Function(FCMTopic) _then;

/// Create a copy of FCMTopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? subscriberCount = null,Object? lastUsed = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subscriberCount: null == subscriberCount ? _self.subscriberCount : subscriberCount // ignore: cast_nullable_to_non_nullable
as int,lastUsed: freezed == lastUsed ? _self.lastUsed : lastUsed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FCMTopic].
extension FCMTopicPatterns on FCMTopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FCMTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FCMTopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FCMTopic value)  $default,){
final _that = this;
switch (_that) {
case _FCMTopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FCMTopic value)?  $default,){
final _that = this;
switch (_that) {
case _FCMTopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int subscriberCount,  DateTime? lastUsed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FCMTopic() when $default != null:
return $default(_that.name,_that.subscriberCount,_that.lastUsed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int subscriberCount,  DateTime? lastUsed)  $default,) {final _that = this;
switch (_that) {
case _FCMTopic():
return $default(_that.name,_that.subscriberCount,_that.lastUsed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int subscriberCount,  DateTime? lastUsed)?  $default,) {final _that = this;
switch (_that) {
case _FCMTopic() when $default != null:
return $default(_that.name,_that.subscriberCount,_that.lastUsed);case _:
  return null;

}
}

}

/// @nodoc


class _FCMTopic implements FCMTopic {
  const _FCMTopic({required this.name, required this.subscriberCount, this.lastUsed});
  

@override final  String name;
@override final  int subscriberCount;
@override final  DateTime? lastUsed;

/// Create a copy of FCMTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FCMTopicCopyWith<_FCMTopic> get copyWith => __$FCMTopicCopyWithImpl<_FCMTopic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FCMTopic&&(identical(other.name, name) || other.name == name)&&(identical(other.subscriberCount, subscriberCount) || other.subscriberCount == subscriberCount)&&(identical(other.lastUsed, lastUsed) || other.lastUsed == lastUsed));
}


@override
int get hashCode => Object.hash(runtimeType,name,subscriberCount,lastUsed);

@override
String toString() {
  return 'FCMTopic(name: $name, subscriberCount: $subscriberCount, lastUsed: $lastUsed)';
}


}

/// @nodoc
abstract mixin class _$FCMTopicCopyWith<$Res> implements $FCMTopicCopyWith<$Res> {
  factory _$FCMTopicCopyWith(_FCMTopic value, $Res Function(_FCMTopic) _then) = __$FCMTopicCopyWithImpl;
@override @useResult
$Res call({
 String name, int subscriberCount, DateTime? lastUsed
});




}
/// @nodoc
class __$FCMTopicCopyWithImpl<$Res>
    implements _$FCMTopicCopyWith<$Res> {
  __$FCMTopicCopyWithImpl(this._self, this._then);

  final _FCMTopic _self;
  final $Res Function(_FCMTopic) _then;

/// Create a copy of FCMTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? subscriberCount = null,Object? lastUsed = freezed,}) {
  return _then(_FCMTopic(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subscriberCount: null == subscriberCount ? _self.subscriberCount : subscriberCount // ignore: cast_nullable_to_non_nullable
as int,lastUsed: freezed == lastUsed ? _self.lastUsed : lastUsed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
