import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/ai_remote_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/preset_repository_impl.dart';
import '../../data/repositories/tag_repository_impl.dart';
import 'package:miui_icon_generator/theme_editor/domain/repositories/wallpaper_download_repository_impl.dart';

import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/preset_repository.dart';
import '../../domain/repositories/tag_repository.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/wallpaper_download_repository.dart';

import '../../domain/usecases/download_wallpaper_usecase.dart';
import '../../domain/usecases/export_lockscreen_pngs_usecase.dart';
import '../../domain/usecases/export_mtz_usecase.dart';
import '../../domain/usecases/generate_ai_lockscreen_usecase.dart';
import '../../domain/usecases/load_preset_usecase.dart';
import '../../domain/usecases/load_tag_file_usecase.dart';
import '../../domain/usecases/save_preset_usecase.dart';
import '../../domain/usecases/save_tag_file_usecase.dart';

import 'service_providers.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final presetRepositoryProvider = Provider<PresetRepository>(
  (_) => PresetRepositoryImpl(),
);

final tagRepositoryProvider = Provider<TagRepository>(
  (_) => TagRepositoryImpl(),
);

final wallpaperDownloadRepositoryProvider =
    Provider<WallpaperDownloadRepository>(
  (_) => WallpaperDownloadRepositoryImpl(),
);

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final key = ref.watch(geminiApiKeyProvider);
  return AiRepositoryImpl(AiRemoteDataSource(key));
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final exportLockscreenPngsUseCaseProvider =
    Provider<ExportLockscreenPngsUseCase>(
  (_) => const ExportLockscreenPngsUseCase(),
);

final exportMtzUseCaseProvider = Provider<ExportMtzUseCase>(
  (_) => const ExportMtzUseCase(),
);

final downloadWallpaperUseCaseProvider =
    Provider<DownloadWallpaperUseCase>((ref) => DownloadWallpaperUseCase(
          ref.read(wallpaperDownloadRepositoryProvider),
        ));

final generateAiLockscreenUseCaseProvider =
    Provider<GenerateAiLockscreenUseCase>(
        (ref) => GenerateAiLockscreenUseCase(ref.read(aiRepositoryProvider)));

final savePresetUseCaseProvider = Provider<SavePresetUseCase>(
    (ref) => SavePresetUseCase(ref.read(presetRepositoryProvider)));

final loadPresetUseCaseProvider = Provider<LoadPresetUseCase>(
    (ref) => LoadPresetUseCase(ref.read(presetRepositoryProvider)));

final saveTagFileUseCaseProvider = Provider<SaveTagFileUseCase>(
    (ref) => SaveTagFileUseCase(ref.read(tagRepositoryProvider)));

final loadTagFileUseCaseProvider = Provider<LoadTagFileUseCase>(
    (ref) => LoadTagFileUseCase(ref.read(tagRepositoryProvider)));
