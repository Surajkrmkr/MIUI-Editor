// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AIAnalysisResult {
  String get name;
  List<String> get tags;
  List<String> get colors;
  String? get category;

  /// Create a copy of AIAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AIAnalysisResultCopyWith<AIAnalysisResult> get copyWith =>
      _$AIAnalysisResultCopyWithImpl<AIAnalysisResult>(
          this as AIAnalysisResult, _$identity);

  /// Serializes this AIAnalysisResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AIAnalysisResult &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality().equals(other.colors, colors) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      const DeepCollectionEquality().hash(tags),
      const DeepCollectionEquality().hash(colors),
      category);

  @override
  String toString() {
    return 'AIAnalysisResult(name: $name, tags: $tags, colors: $colors, category: $category)';
  }
}

/// @nodoc
abstract mixin class $AIAnalysisResultCopyWith<$Res> {
  factory $AIAnalysisResultCopyWith(
          AIAnalysisResult value, $Res Function(AIAnalysisResult) _then) =
      _$AIAnalysisResultCopyWithImpl;
  @useResult
  $Res call(
      {String name, List<String> tags, List<String> colors, String? category});
}

/// @nodoc
class _$AIAnalysisResultCopyWithImpl<$Res>
    implements $AIAnalysisResultCopyWith<$Res> {
  _$AIAnalysisResultCopyWithImpl(this._self, this._then);

  final AIAnalysisResult _self;
  final $Res Function(AIAnalysisResult) _then;

  /// Create a copy of AIAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? tags = null,
    Object? colors = null,
    Object? category = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      colors: null == colors
          ? _self.colors
          : colors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AIAnalysisResult].
extension AIAnalysisResultPatterns on AIAnalysisResult {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AIAnalysisResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AIAnalysisResult() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AIAnalysisResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIAnalysisResult():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AIAnalysisResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIAnalysisResult() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String name, List<String> tags, List<String> colors,
            String? category)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AIAnalysisResult() when $default != null:
        return $default(_that.name, _that.tags, _that.colors, _that.category);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String name, List<String> tags, List<String> colors,
            String? category)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIAnalysisResult():
        return $default(_that.name, _that.tags, _that.colors, _that.category);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String name, List<String> tags, List<String> colors,
            String? category)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIAnalysisResult() when $default != null:
        return $default(_that.name, _that.tags, _that.colors, _that.category);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AIAnalysisResult implements AIAnalysisResult {
  const _AIAnalysisResult(
      {required this.name,
      required final List<String> tags,
      required final List<String> colors,
      this.category})
      : _tags = tags,
        _colors = colors;
  factory _AIAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AIAnalysisResultFromJson(json);

  @override
  final String name;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<String> _colors;
  @override
  List<String> get colors {
    if (_colors is EqualUnmodifiableListView) return _colors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_colors);
  }

  @override
  final String? category;

  /// Create a copy of AIAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AIAnalysisResultCopyWith<_AIAnalysisResult> get copyWith =>
      __$AIAnalysisResultCopyWithImpl<_AIAnalysisResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AIAnalysisResultToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AIAnalysisResult &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._colors, _colors) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_colors),
      category);

  @override
  String toString() {
    return 'AIAnalysisResult(name: $name, tags: $tags, colors: $colors, category: $category)';
  }
}

/// @nodoc
abstract mixin class _$AIAnalysisResultCopyWith<$Res>
    implements $AIAnalysisResultCopyWith<$Res> {
  factory _$AIAnalysisResultCopyWith(
          _AIAnalysisResult value, $Res Function(_AIAnalysisResult) _then) =
      __$AIAnalysisResultCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name, List<String> tags, List<String> colors, String? category});
}

/// @nodoc
class __$AIAnalysisResultCopyWithImpl<$Res>
    implements _$AIAnalysisResultCopyWith<$Res> {
  __$AIAnalysisResultCopyWithImpl(this._self, this._then);

  final _AIAnalysisResult _self;
  final $Res Function(_AIAnalysisResult) _then;

  /// Create a copy of AIAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? tags = null,
    Object? colors = null,
    Object? category = freezed,
  }) {
    return _then(_AIAnalysisResult(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      colors: null == colors
          ? _self._colors
          : colors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$AITask {
  String get id;
  String get filePath;
  AITaskStatus get status;
  AIAnalysisResult? get result;
  String? get errorMessage;

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AITaskCopyWith<AITask> get copyWith =>
      _$AITaskCopyWithImpl<AITask>(this as AITask, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AITask &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, filePath, status, result, errorMessage);

  @override
  String toString() {
    return 'AITask(id: $id, filePath: $filePath, status: $status, result: $result, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $AITaskCopyWith<$Res> {
  factory $AITaskCopyWith(AITask value, $Res Function(AITask) _then) =
      _$AITaskCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String filePath,
      AITaskStatus status,
      AIAnalysisResult? result,
      String? errorMessage});

  $AIAnalysisResultCopyWith<$Res>? get result;
}

/// @nodoc
class _$AITaskCopyWithImpl<$Res> implements $AITaskCopyWith<$Res> {
  _$AITaskCopyWithImpl(this._self, this._then);

  final AITask _self;
  final $Res Function(AITask) _then;

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? filePath = null,
    Object? status = null,
    Object? result = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AITaskStatus,
      result: freezed == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as AIAnalysisResult?,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AIAnalysisResultCopyWith<$Res>? get result {
    if (_self.result == null) {
      return null;
    }

    return $AIAnalysisResultCopyWith<$Res>(_self.result!, (value) {
      return _then(_self.copyWith(result: value));
    });
  }
}

/// Adds pattern-matching-related methods to [AITask].
extension AITaskPatterns on AITask {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AITask value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AITask() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AITask value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AITask():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AITask value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AITask() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String id, String filePath, AITaskStatus status,
            AIAnalysisResult? result, String? errorMessage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AITask() when $default != null:
        return $default(_that.id, _that.filePath, _that.status, _that.result,
            _that.errorMessage);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String id, String filePath, AITaskStatus status,
            AIAnalysisResult? result, String? errorMessage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AITask():
        return $default(_that.id, _that.filePath, _that.status, _that.result,
            _that.errorMessage);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String id, String filePath, AITaskStatus status,
            AIAnalysisResult? result, String? errorMessage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AITask() when $default != null:
        return $default(_that.id, _that.filePath, _that.status, _that.result,
            _that.errorMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AITask implements AITask {
  const _AITask(
      {required this.id,
      required this.filePath,
      required this.status,
      this.result,
      this.errorMessage});

  @override
  final String id;
  @override
  final String filePath;
  @override
  final AITaskStatus status;
  @override
  final AIAnalysisResult? result;
  @override
  final String? errorMessage;

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AITaskCopyWith<_AITask> get copyWith =>
      __$AITaskCopyWithImpl<_AITask>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AITask &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, filePath, status, result, errorMessage);

  @override
  String toString() {
    return 'AITask(id: $id, filePath: $filePath, status: $status, result: $result, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$AITaskCopyWith<$Res> implements $AITaskCopyWith<$Res> {
  factory _$AITaskCopyWith(_AITask value, $Res Function(_AITask) _then) =
      __$AITaskCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String filePath,
      AITaskStatus status,
      AIAnalysisResult? result,
      String? errorMessage});

  @override
  $AIAnalysisResultCopyWith<$Res>? get result;
}

/// @nodoc
class __$AITaskCopyWithImpl<$Res> implements _$AITaskCopyWith<$Res> {
  __$AITaskCopyWithImpl(this._self, this._then);

  final _AITask _self;
  final $Res Function(_AITask) _then;

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? filePath = null,
    Object? status = null,
    Object? result = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_AITask(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AITaskStatus,
      result: freezed == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as AIAnalysisResult?,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AIAnalysisResultCopyWith<$Res>? get result {
    if (_self.result == null) {
      return null;
    }

    return $AIAnalysisResultCopyWith<$Res>(_self.result!, (value) {
      return _then(_self.copyWith(result: value));
    });
  }
}

// dart format on
