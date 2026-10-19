import '../lockscreen/design_profile.dart';
import '../spec/spec_issue.dart';
import '../spec/theme_spec.dart';

/// Where and how to check a spec against the file system.
class ValidationOptions {
  const ValidationOptions({
    required this.baseDir,
    this.assetsRoot,
    this.checkContrast = true,
    this.checkDesign = false,
    this.similarDesigns = const [],
    this.fontsDirs = const [],
  });

  /// Relative paths in the spec resolve against this directory.
  final String baseDir;

  /// Repo root holding `assets/icons/<pack>/`; without it only the pack name
  /// is checked.
  final String? assetsRoot;

  /// Decode the wallpaper to estimate text legibility; skipped when false.
  final bool checkContrast;

  /// Warn about a lockscreen that is bare: few elements, no clock, no live
  /// information, no decoration or a single font size.
  final bool checkDesign;

  /// Earlier themes' lockscreens; with [checkDesign], a spec too close to one
  /// of them is warned about. A theme with the same title is skipped.
  final List<NamedDesign> similarDesigns;

  /// Folders searched for a font file when the spec doesn't name one.
  final List<String> fontsDirs;
}

class ValidationReport {
  const ValidationReport(this.issues, {this.spec});

  /// The parsed spec; null when parsing failed.
  final ThemeSpec? spec;
  final List<SpecIssue> issues;

  int get errorCount =>
      issues.where((i) => i.severity == IssueSeverity.error).length;
  int get warningCount =>
      issues.where((i) => i.severity == IssueSeverity.warning).length;

  bool get ok => errorCount == 0;

  Map<String, Object?> toJson() => {
    'ok': ok,
    'errors': errorCount,
    'warnings': warningCount,
    'issues': [for (final i in issues) i.toJson()],
  };
}
