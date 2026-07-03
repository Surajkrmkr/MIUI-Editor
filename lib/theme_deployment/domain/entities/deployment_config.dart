enum DeploymentMode { upload, update }

class DeploymentConfig {
  const DeploymentConfig({
    this.scriptsDir = '',
    this.basePath = '',
    this.v2Path = '',
    this.maxTab = 9,
    this.email = '',
    this.password = '',
    this.description = '',
  });

  final String scriptsDir;
  final String basePath;
  final String v2Path;
  final int maxTab;
  final String email;
  final String password;
  final String description;

  DeploymentConfig copyWith({
    String? scriptsDir,
    String? basePath,
    String? v2Path,
    int? maxTab,
    String? email,
    String? password,
    String? description,
  }) =>
      DeploymentConfig(
        scriptsDir: scriptsDir ?? this.scriptsDir,
        basePath: basePath ?? this.basePath,
        v2Path: v2Path ?? this.v2Path,
        maxTab: maxTab ?? this.maxTab,
        email: email ?? this.email,
        password: password ?? this.password,
        description: description ?? this.description,
      );
}
