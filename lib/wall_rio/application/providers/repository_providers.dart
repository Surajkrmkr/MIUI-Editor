import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/version_repository.dart';
import '../../domain/repositories/wallpaper_repository.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/git_repository.dart';
import '../../infrastructure/repositories/cli_git_repository.dart';
import '../../infrastructure/repositories/gemini_cli_ai_repository.dart';
import '../../infrastructure/repositories/hive_settings_repository.dart';
import '../../infrastructure/repositories/hive_version_repository.dart';
import '../../infrastructure/repositories/local_json_wallpaper_repository.dart';

final wallRioAiRepositoryProvider = Provider<AIRepository>(
  (ref) => GeminiCliAIRepository(),
);

final wallRioGitRepositoryProvider = Provider<GitRepository>(
  (ref) => CliGitRepository(),
);

final wallRioSettingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(),
);

final wallRioWallpaperRepositoryProvider = Provider<WallpaperRepository>(
  (ref) => LocalJsonWallpaperRepository(),
);

final wallRioVersionRepositoryProvider = Provider<VersionRepository>(
  (ref) => HiveVersionRepository(),
);
