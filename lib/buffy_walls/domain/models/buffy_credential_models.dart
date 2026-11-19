class BuffyCredentialStatus {
  final bool isSignedIn;
  final String? clientId;
  final String? clientSecret;
  final String? firebaseProjectId;
  final String? userEmail;

  /// Cloudflare R2 S3 API keys; empty strings when not set.
  final Map<String, String> r2;

  const BuffyCredentialStatus({
    required this.isSignedIn,
    this.clientId,
    this.clientSecret,
    this.firebaseProjectId,
    this.userEmail,
    this.r2 = const {},
  });

  BuffyCredentialStatus copyWith({
    bool? isSignedIn,
    String? clientId,
    String? clientSecret,
    String? firebaseProjectId,
    String? userEmail,
    Map<String, String>? r2,
  }) {
    return BuffyCredentialStatus(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      userEmail: userEmail ?? this.userEmail,
      r2: r2 ?? this.r2,
    );
  }

  bool get hasGoogleCloud => isSignedIn;

  bool get hasR2 =>
      const ['accountId', 'accessKeyId', 'secretAccessKey', 'bucket']
          .every((k) => (r2[k] ?? '').isNotEmpty);
}
