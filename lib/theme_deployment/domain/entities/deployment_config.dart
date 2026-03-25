class DeploymentConfig {
  const DeploymentConfig({
    this.scriptsDir = '',
    this.basePath = '',
    this.maxTab = 9,
    this.email = '',
    this.password = '',
    this.description = '',
  });

  final String scriptsDir;
  final String basePath;
  final int maxTab;
  final String email;
  final String password;
  final String description;

  DeploymentConfig copyWith({
    String? scriptsDir,
    String? basePath,
    int? maxTab,
    String? email,
    String? password,
    String? description,
  }) =>
      DeploymentConfig(
        scriptsDir: scriptsDir ?? this.scriptsDir,
        basePath: basePath ?? this.basePath,
        maxTab: maxTab ?? this.maxTab,
        email: email ?? this.email,
        password: password ?? this.password,
        description: description ?? this.description,
      );
}
