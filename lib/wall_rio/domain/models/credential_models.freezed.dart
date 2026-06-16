// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credential_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CredentialStatus {

 bool get isSignedIn; String? get clientId; String? get clientSecret; String? get firebaseProjectId; String? get userEmail;
/// Create a copy of CredentialStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialStatusCopyWith<CredentialStatus> get copyWith => _$CredentialStatusCopyWithImpl<CredentialStatus>(this as CredentialStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialStatus&&(identical(other.isSignedIn, isSignedIn) || other.isSignedIn == isSignedIn)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.firebaseProjectId, firebaseProjectId) || other.firebaseProjectId == firebaseProjectId)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail));
}


@override
int get hashCode => Object.hash(runtimeType,isSignedIn,clientId,clientSecret,firebaseProjectId,userEmail);

@override
String toString() {
  return 'CredentialStatus(isSignedIn: $isSignedIn, clientId: $clientId, clientSecret: $clientSecret, firebaseProjectId: $firebaseProjectId, userEmail: $userEmail)';
}


}

/// @nodoc
abstract mixin class $CredentialStatusCopyWith<$Res>  {
  factory $CredentialStatusCopyWith(CredentialStatus value, $Res Function(CredentialStatus) _then) = _$CredentialStatusCopyWithImpl;
@useResult
$Res call({
 bool isSignedIn, String? clientId, String? clientSecret, String? firebaseProjectId, String? userEmail
});




}
/// @nodoc
class _$CredentialStatusCopyWithImpl<$Res>
    implements $CredentialStatusCopyWith<$Res> {
  _$CredentialStatusCopyWithImpl(this._self, this._then);

  final CredentialStatus _self;
  final $Res Function(CredentialStatus) _then;

/// Create a copy of CredentialStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSignedIn = null,Object? clientId = freezed,Object? clientSecret = freezed,Object? firebaseProjectId = freezed,Object? userEmail = freezed,}) {
  return _then(_self.copyWith(
isSignedIn: null == isSignedIn ? _self.isSignedIn : isSignedIn // ignore: cast_nullable_to_non_nullable
as bool,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,clientSecret: freezed == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String?,firebaseProjectId: freezed == firebaseProjectId ? _self.firebaseProjectId : firebaseProjectId // ignore: cast_nullable_to_non_nullable
as String?,userEmail: freezed == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CredentialStatus].
extension CredentialStatusPatterns on CredentialStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CredentialStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CredentialStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CredentialStatus value)  $default,){
final _that = this;
switch (_that) {
case _CredentialStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CredentialStatus value)?  $default,){
final _that = this;
switch (_that) {
case _CredentialStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSignedIn,  String? clientId,  String? clientSecret,  String? firebaseProjectId,  String? userEmail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CredentialStatus() when $default != null:
return $default(_that.isSignedIn,_that.clientId,_that.clientSecret,_that.firebaseProjectId,_that.userEmail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSignedIn,  String? clientId,  String? clientSecret,  String? firebaseProjectId,  String? userEmail)  $default,) {final _that = this;
switch (_that) {
case _CredentialStatus():
return $default(_that.isSignedIn,_that.clientId,_that.clientSecret,_that.firebaseProjectId,_that.userEmail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSignedIn,  String? clientId,  String? clientSecret,  String? firebaseProjectId,  String? userEmail)?  $default,) {final _that = this;
switch (_that) {
case _CredentialStatus() when $default != null:
return $default(_that.isSignedIn,_that.clientId,_that.clientSecret,_that.firebaseProjectId,_that.userEmail);case _:
  return null;

}
}

}

/// @nodoc


class _CredentialStatus extends CredentialStatus {
  const _CredentialStatus({required this.isSignedIn, this.clientId, this.clientSecret, this.firebaseProjectId, this.userEmail}): super._();
  

@override final  bool isSignedIn;
@override final  String? clientId;
@override final  String? clientSecret;
@override final  String? firebaseProjectId;
@override final  String? userEmail;

/// Create a copy of CredentialStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialStatusCopyWith<_CredentialStatus> get copyWith => __$CredentialStatusCopyWithImpl<_CredentialStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CredentialStatus&&(identical(other.isSignedIn, isSignedIn) || other.isSignedIn == isSignedIn)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.firebaseProjectId, firebaseProjectId) || other.firebaseProjectId == firebaseProjectId)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail));
}


@override
int get hashCode => Object.hash(runtimeType,isSignedIn,clientId,clientSecret,firebaseProjectId,userEmail);

@override
String toString() {
  return 'CredentialStatus(isSignedIn: $isSignedIn, clientId: $clientId, clientSecret: $clientSecret, firebaseProjectId: $firebaseProjectId, userEmail: $userEmail)';
}


}

/// @nodoc
abstract mixin class _$CredentialStatusCopyWith<$Res> implements $CredentialStatusCopyWith<$Res> {
  factory _$CredentialStatusCopyWith(_CredentialStatus value, $Res Function(_CredentialStatus) _then) = __$CredentialStatusCopyWithImpl;
@override @useResult
$Res call({
 bool isSignedIn, String? clientId, String? clientSecret, String? firebaseProjectId, String? userEmail
});




}
/// @nodoc
class __$CredentialStatusCopyWithImpl<$Res>
    implements _$CredentialStatusCopyWith<$Res> {
  __$CredentialStatusCopyWithImpl(this._self, this._then);

  final _CredentialStatus _self;
  final $Res Function(_CredentialStatus) _then;

/// Create a copy of CredentialStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSignedIn = null,Object? clientId = freezed,Object? clientSecret = freezed,Object? firebaseProjectId = freezed,Object? userEmail = freezed,}) {
  return _then(_CredentialStatus(
isSignedIn: null == isSignedIn ? _self.isSignedIn : isSignedIn // ignore: cast_nullable_to_non_nullable
as bool,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,clientSecret: freezed == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String?,firebaseProjectId: freezed == firebaseProjectId ? _self.firebaseProjectId : firebaseProjectId // ignore: cast_nullable_to_non_nullable
as String?,userEmail: freezed == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
