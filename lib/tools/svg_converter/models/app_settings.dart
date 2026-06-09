class AppSettings {
  final String mode;
  final int colorPrecision;
  final int filterSpeckle;
  final String? lastUsedFolder;
  final bool darkMode;

  AppSettings({
    this.mode = 'spline',
    this.colorPrecision = 6,
    this.filterSpeckle = 8,
    this.lastUsedFolder,
    this.darkMode = true,
  });

  AppSettings copyWith({
    String? mode,
    int? colorPrecision,
    int? filterSpeckle,
    String? lastUsedFolder,
    bool? darkMode,
  }) {
    return AppSettings(
      mode: mode ?? this.mode,
      colorPrecision: colorPrecision ?? this.colorPrecision,
      filterSpeckle: filterSpeckle ?? this.filterSpeckle,
      lastUsedFolder: lastUsedFolder ?? this.lastUsedFolder,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}