/// One problem found while reading or validating a spec.
class SpecIssue {
  const SpecIssue({
    required this.code,
    required this.path,
    required this.message,
    this.severity = IssueSeverity.error,
    this.hint,
  });

  /// Stable machine-readable id, e.g. `spec.missing`.
  final String code;

  /// JSON Pointer to the offending value, e.g. `/lockscreen/elements/2/type`.
  final String path;
  final String message;
  final IssueSeverity severity;

  /// What to do about it, when that isn't obvious from [message].
  final String? hint;

  Map<String, Object?> toJson() => {
    'code': code,
    'severity': severity.name,
    'path': path.isEmpty ? '/' : path,
    'message': message,
    if (hint != null) 'hint': hint,
  };

  @override
  String toString() => '${severity.name} $path: $message';
}

enum IssueSeverity { error, warning }
