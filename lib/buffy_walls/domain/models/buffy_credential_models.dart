class BuffyCredentialStatus {
  final bool isSignedIn;
  final String? clientId;
  final String? clientSecret;
  final String? firebaseProjectId;
  final String? userEmail;

  const BuffyCredentialStatus({
    required this.isSignedIn,
    this.clientId,
    this.clientSecret,
    this.firebaseProjectId,
    this.userEmail,
  });

  BuffyCredentialStatus copyWith({
    bool? isSignedIn,
    String? clientId,
    String? clientSecret,
    String? firebaseProjectId,
    String? userEmail,
  }) {
    return BuffyCredentialStatus(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  bool get hasGoogleCloud => isSignedIn;
}
