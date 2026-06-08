import 'package:freezed_annotation/freezed_annotation.dart';

part 'credential_models.freezed.dart';

@freezed
abstract class CredentialStatus with _$CredentialStatus {
  const factory CredentialStatus({
    required bool isSignedIn,
    String? clientId,
    String? clientSecret,
    String? firebaseProjectId,
    String? userEmail,
  }) = _CredentialStatus;

  const CredentialStatus._();
  bool get hasGoogleCloud => isSignedIn;
}
