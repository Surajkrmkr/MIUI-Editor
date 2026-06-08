// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'git_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitStatus {
  bool get isRepository;
  List<String> get modifiedFiles;
  List<String> get untrackedFiles;
  List<String> get stagedFiles;
  String? get currentBranch;
  int get ahead;
  int get behind;

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GitStatusCopyWith<GitStatus> get copyWith =>
      _$GitStatusCopyWithImpl<GitStatus>(this as GitStatus, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GitStatus &&
            (identical(other.isRepository, isRepository) ||
                other.isRepository == isRepository) &&
            const DeepCollectionEquality()
                .equals(other.modifiedFiles, modifiedFiles) &&
            const DeepCollectionEquality()
                .equals(other.untrackedFiles, untrackedFiles) &&
            const DeepCollectionEquality()
                .equals(other.stagedFiles, stagedFiles) &&
            (identical(other.currentBranch, currentBranch) ||
                other.currentBranch == currentBranch) &&
            (identical(other.ahead, ahead) || other.ahead == ahead) &&
            (identical(other.behind, behind) || other.behind == behind));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isRepository,
      const DeepCollectionEquality().hash(modifiedFiles),
      const DeepCollectionEquality().hash(untrackedFiles),
      const DeepCollectionEquality().hash(stagedFiles),
      currentBranch,
      ahead,
      behind);

  @override
  String toString() {
    return 'GitStatus(isRepository: $isRepository, modifiedFiles: $modifiedFiles, untrackedFiles: $untrackedFiles, stagedFiles: $stagedFiles, currentBranch: $currentBranch, ahead: $ahead, behind: $behind)';
  }
}

/// @nodoc
abstract mixin class $GitStatusCopyWith<$Res> {
  factory $GitStatusCopyWith(GitStatus value, $Res Function(GitStatus) _then) =
      _$GitStatusCopyWithImpl;
  @useResult
  $Res call(
      {bool isRepository,
      List<String> modifiedFiles,
      List<String> untrackedFiles,
      List<String> stagedFiles,
      String? currentBranch,
      int ahead,
      int behind});
}

/// @nodoc
class _$GitStatusCopyWithImpl<$Res> implements $GitStatusCopyWith<$Res> {
  _$GitStatusCopyWithImpl(this._self, this._then);

  final GitStatus _self;
  final $Res Function(GitStatus) _then;

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRepository = null,
    Object? modifiedFiles = null,
    Object? untrackedFiles = null,
    Object? stagedFiles = null,
    Object? currentBranch = freezed,
    Object? ahead = null,
    Object? behind = null,
  }) {
    return _then(_self.copyWith(
      isRepository: null == isRepository
          ? _self.isRepository
          : isRepository // ignore: cast_nullable_to_non_nullable
              as bool,
      modifiedFiles: null == modifiedFiles
          ? _self.modifiedFiles
          : modifiedFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      untrackedFiles: null == untrackedFiles
          ? _self.untrackedFiles
          : untrackedFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      stagedFiles: null == stagedFiles
          ? _self.stagedFiles
          : stagedFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentBranch: freezed == currentBranch
          ? _self.currentBranch
          : currentBranch // ignore: cast_nullable_to_non_nullable
              as String?,
      ahead: null == ahead
          ? _self.ahead
          : ahead // ignore: cast_nullable_to_non_nullable
              as int,
      behind: null == behind
          ? _self.behind
          : behind // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [GitStatus].
extension GitStatusPatterns on GitStatus {
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
    TResult Function(_GitStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GitStatus() when $default != null:
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
    TResult Function(_GitStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitStatus():
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
    TResult? Function(_GitStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitStatus() when $default != null:
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
    TResult Function(
            bool isRepository,
            List<String> modifiedFiles,
            List<String> untrackedFiles,
            List<String> stagedFiles,
            String? currentBranch,
            int ahead,
            int behind)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GitStatus() when $default != null:
        return $default(
            _that.isRepository,
            _that.modifiedFiles,
            _that.untrackedFiles,
            _that.stagedFiles,
            _that.currentBranch,
            _that.ahead,
            _that.behind);
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
    TResult Function(
            bool isRepository,
            List<String> modifiedFiles,
            List<String> untrackedFiles,
            List<String> stagedFiles,
            String? currentBranch,
            int ahead,
            int behind)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitStatus():
        return $default(
            _that.isRepository,
            _that.modifiedFiles,
            _that.untrackedFiles,
            _that.stagedFiles,
            _that.currentBranch,
            _that.ahead,
            _that.behind);
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
    TResult? Function(
            bool isRepository,
            List<String> modifiedFiles,
            List<String> untrackedFiles,
            List<String> stagedFiles,
            String? currentBranch,
            int ahead,
            int behind)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitStatus() when $default != null:
        return $default(
            _that.isRepository,
            _that.modifiedFiles,
            _that.untrackedFiles,
            _that.stagedFiles,
            _that.currentBranch,
            _that.ahead,
            _that.behind);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _GitStatus implements GitStatus {
  const _GitStatus(
      {required this.isRepository,
      required final List<String> modifiedFiles,
      required final List<String> untrackedFiles,
      required final List<String> stagedFiles,
      this.currentBranch,
      this.ahead = 0,
      this.behind = 0})
      : _modifiedFiles = modifiedFiles,
        _untrackedFiles = untrackedFiles,
        _stagedFiles = stagedFiles;

  @override
  final bool isRepository;
  final List<String> _modifiedFiles;
  @override
  List<String> get modifiedFiles {
    if (_modifiedFiles is EqualUnmodifiableListView) return _modifiedFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiedFiles);
  }

  final List<String> _untrackedFiles;
  @override
  List<String> get untrackedFiles {
    if (_untrackedFiles is EqualUnmodifiableListView) return _untrackedFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_untrackedFiles);
  }

  final List<String> _stagedFiles;
  @override
  List<String> get stagedFiles {
    if (_stagedFiles is EqualUnmodifiableListView) return _stagedFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stagedFiles);
  }

  @override
  final String? currentBranch;
  @override
  @JsonKey()
  final int ahead;
  @override
  @JsonKey()
  final int behind;

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GitStatusCopyWith<_GitStatus> get copyWith =>
      __$GitStatusCopyWithImpl<_GitStatus>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GitStatus &&
            (identical(other.isRepository, isRepository) ||
                other.isRepository == isRepository) &&
            const DeepCollectionEquality()
                .equals(other._modifiedFiles, _modifiedFiles) &&
            const DeepCollectionEquality()
                .equals(other._untrackedFiles, _untrackedFiles) &&
            const DeepCollectionEquality()
                .equals(other._stagedFiles, _stagedFiles) &&
            (identical(other.currentBranch, currentBranch) ||
                other.currentBranch == currentBranch) &&
            (identical(other.ahead, ahead) || other.ahead == ahead) &&
            (identical(other.behind, behind) || other.behind == behind));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isRepository,
      const DeepCollectionEquality().hash(_modifiedFiles),
      const DeepCollectionEquality().hash(_untrackedFiles),
      const DeepCollectionEquality().hash(_stagedFiles),
      currentBranch,
      ahead,
      behind);

  @override
  String toString() {
    return 'GitStatus(isRepository: $isRepository, modifiedFiles: $modifiedFiles, untrackedFiles: $untrackedFiles, stagedFiles: $stagedFiles, currentBranch: $currentBranch, ahead: $ahead, behind: $behind)';
  }
}

/// @nodoc
abstract mixin class _$GitStatusCopyWith<$Res>
    implements $GitStatusCopyWith<$Res> {
  factory _$GitStatusCopyWith(
          _GitStatus value, $Res Function(_GitStatus) _then) =
      __$GitStatusCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isRepository,
      List<String> modifiedFiles,
      List<String> untrackedFiles,
      List<String> stagedFiles,
      String? currentBranch,
      int ahead,
      int behind});
}

/// @nodoc
class __$GitStatusCopyWithImpl<$Res> implements _$GitStatusCopyWith<$Res> {
  __$GitStatusCopyWithImpl(this._self, this._then);

  final _GitStatus _self;
  final $Res Function(_GitStatus) _then;

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isRepository = null,
    Object? modifiedFiles = null,
    Object? untrackedFiles = null,
    Object? stagedFiles = null,
    Object? currentBranch = freezed,
    Object? ahead = null,
    Object? behind = null,
  }) {
    return _then(_GitStatus(
      isRepository: null == isRepository
          ? _self.isRepository
          : isRepository // ignore: cast_nullable_to_non_nullable
              as bool,
      modifiedFiles: null == modifiedFiles
          ? _self._modifiedFiles
          : modifiedFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      untrackedFiles: null == untrackedFiles
          ? _self._untrackedFiles
          : untrackedFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      stagedFiles: null == stagedFiles
          ? _self._stagedFiles
          : stagedFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentBranch: freezed == currentBranch
          ? _self.currentBranch
          : currentBranch // ignore: cast_nullable_to_non_nullable
              as String?,
      ahead: null == ahead
          ? _self.ahead
          : ahead // ignore: cast_nullable_to_non_nullable
              as int,
      behind: null == behind
          ? _self.behind
          : behind // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$GitCommitResult {
  bool get success;
  String get message;
  String? get commitHash;

  /// Create a copy of GitCommitResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GitCommitResultCopyWith<GitCommitResult> get copyWith =>
      _$GitCommitResultCopyWithImpl<GitCommitResult>(
          this as GitCommitResult, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GitCommitResult &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.commitHash, commitHash) ||
                other.commitHash == commitHash));
  }

  @override
  int get hashCode => Object.hash(runtimeType, success, message, commitHash);

  @override
  String toString() {
    return 'GitCommitResult(success: $success, message: $message, commitHash: $commitHash)';
  }
}

/// @nodoc
abstract mixin class $GitCommitResultCopyWith<$Res> {
  factory $GitCommitResultCopyWith(
          GitCommitResult value, $Res Function(GitCommitResult) _then) =
      _$GitCommitResultCopyWithImpl;
  @useResult
  $Res call({bool success, String message, String? commitHash});
}

/// @nodoc
class _$GitCommitResultCopyWithImpl<$Res>
    implements $GitCommitResultCopyWith<$Res> {
  _$GitCommitResultCopyWithImpl(this._self, this._then);

  final GitCommitResult _self;
  final $Res Function(GitCommitResult) _then;

  /// Create a copy of GitCommitResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? commitHash = freezed,
  }) {
    return _then(_self.copyWith(
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      commitHash: freezed == commitHash
          ? _self.commitHash
          : commitHash // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [GitCommitResult].
extension GitCommitResultPatterns on GitCommitResult {
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
    TResult Function(_GitCommitResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GitCommitResult() when $default != null:
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
    TResult Function(_GitCommitResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitCommitResult():
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
    TResult? Function(_GitCommitResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitCommitResult() when $default != null:
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
    TResult Function(bool success, String message, String? commitHash)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GitCommitResult() when $default != null:
        return $default(_that.success, _that.message, _that.commitHash);
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
    TResult Function(bool success, String message, String? commitHash) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitCommitResult():
        return $default(_that.success, _that.message, _that.commitHash);
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
    TResult? Function(bool success, String message, String? commitHash)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GitCommitResult() when $default != null:
        return $default(_that.success, _that.message, _that.commitHash);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _GitCommitResult implements GitCommitResult {
  const _GitCommitResult(
      {required this.success, required this.message, this.commitHash});

  @override
  final bool success;
  @override
  final String message;
  @override
  final String? commitHash;

  /// Create a copy of GitCommitResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GitCommitResultCopyWith<_GitCommitResult> get copyWith =>
      __$GitCommitResultCopyWithImpl<_GitCommitResult>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GitCommitResult &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.commitHash, commitHash) ||
                other.commitHash == commitHash));
  }

  @override
  int get hashCode => Object.hash(runtimeType, success, message, commitHash);

  @override
  String toString() {
    return 'GitCommitResult(success: $success, message: $message, commitHash: $commitHash)';
  }
}

/// @nodoc
abstract mixin class _$GitCommitResultCopyWith<$Res>
    implements $GitCommitResultCopyWith<$Res> {
  factory _$GitCommitResultCopyWith(
          _GitCommitResult value, $Res Function(_GitCommitResult) _then) =
      __$GitCommitResultCopyWithImpl;
  @override
  @useResult
  $Res call({bool success, String message, String? commitHash});
}

/// @nodoc
class __$GitCommitResultCopyWithImpl<$Res>
    implements _$GitCommitResultCopyWith<$Res> {
  __$GitCommitResultCopyWithImpl(this._self, this._then);

  final _GitCommitResult _self;
  final $Res Function(_GitCommitResult) _then;

  /// Create a copy of GitCommitResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? commitHash = freezed,
  }) {
    return _then(_GitCommitResult(
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      commitHash: freezed == commitHash
          ? _self.commitHash
          : commitHash // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
