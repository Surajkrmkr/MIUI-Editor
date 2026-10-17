/// Exit codes shared by every command.
abstract final class ExitCodes {
  /// Succeeded (warnings allowed unless `--strict`).
  static const ok = 0;

  /// The spec has errors.
  static const invalid = 1;

  /// Wrong command line.
  static const usage = 2;

  /// A file couldn't be read.
  static const io = 3;

  /// A valid spec failed while building.
  static const buildFailed = 4;

  /// The render process couldn't run (Flutter or the project not found, or it
  /// crashed before reporting).
  static const sidecar = 5;
}
