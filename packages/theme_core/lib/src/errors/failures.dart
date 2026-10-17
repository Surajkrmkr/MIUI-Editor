sealed class Failure {
  const Failure(this.message);
  final String message;
  @override
  String toString() => '\$runtimeType: \$message';
}

final class FileFailure       extends Failure { const FileFailure(super.m); }
final class NetworkFailure    extends Failure { const NetworkFailure(super.m); }
final class AiFailure         extends Failure { const AiFailure(super.m); }
final class ExportFailure     extends Failure { const ExportFailure(super.m); }
final class XmlFailure        extends Failure { const XmlFailure(super.m); }
final class ValidationFailure extends Failure { const ValidationFailure(super.m); }
