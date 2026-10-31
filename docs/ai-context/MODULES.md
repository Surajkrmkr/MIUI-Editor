# Modules & Features Directory

This document maps all modules in the project and their purposes.

## Module Dependency Map

```
RootApp (Launcher)
├── Theme Editor (MaterialApp)
├── Image Utility (MaterialApp.router - GoRouter)
├── Themes Deployment (MaterialApp)
├── WallRio CMS (MaterialApp.router - GoRouter)
│   └── Firebase Storage catalogs
├── BuffyWalls CMS (MaterialApp)

Core Shared
├── Theme System
├── Color Tokens
├── Typography
├── Spacing & Radius
└── Reusable Widgets
```

## Core Module: `/lib/core/`

### Purpose

Global shared components used by all sub-apps.

### Structure

```
core/
├── theme/
│   ├── app_colors.dart              # Color tokens (AMOLED Purple)
│   ├── app_theme.dart               # ThemeData light/dark
│   ├── app_radius.dart              # Border radius tokens
│   ├── app_spacing.dart             # Spacing constants
│   ├── theme_extensions.dart        # AppColorScheme extension
│   └── theme_provider.dart          # Riverpod theme mode provider
└── [other core utilities]
```

### Key Exports

- `AppColors.*` — All color tokens
- `AppTheme.light()`, `AppTheme.dark()` — Theme definitions
- `AppRadius.*` — Border radius constants
- `AppSpacing.*` — Spacing constants
- `context.appColors` — Theme extension access

### No Modifications

This directory should remain stable. Only add new design tokens here if introducing a new color/spacing/radius system-wide.

---

## App Module 1: `/lib/theme_editor/`

### Purpose

MIUI Theme Editor for creating and editing MIUI themes (lockscreens, icons, modules, MTZ files).

### Structure

```
theme_editor/
├── core/
│   └── services/
│       └── window_service.dart      # Desktop window init
├── data/                            # Data layer (unused - mostly local editing)
├── domain/                          # Domain layer
├── presentation/
│   ├── features/
│   │   ├── splash/
│   │   │   └── user_profile_screen.dart  # Entry point
│   │   ├── font_picker/
│   │   │   └── font_list_panel.dart
│   │   ├── lockscreen/
│   │   │   └── widgets/element_info_panel.dart
│   │   ├── pro_workspace/
│   │   │   ├── pro_workspace_shell.dart
│   │   │   └── widgets/right_inspector.dart
│   │   └── [other features]
│   └── providers/
│       └── service_providers.dart   # Riverpod setup
└── resources/                       # Static assets
```

### Entry Point

`UserProfileScreen` → Launch from `lib/main.dart`

### Features

- **Lockscreen Editor**: Edit lockscreen themes
- **Icon Pack Manager**: Create and manage icon sets
- **Module Theme Editor**: Customize theme modules
- **MTZ Export/Import**: Package themes for distribution
- **Font Picker**: Select and customize fonts

### State Management

- Riverpod for UI state
- Local state only (no remote API)

### Navigation Pattern

Simple Navigator (no GoRouter)

### Key Files to Update When Adding Features

- `presentation/features/` — Add new feature directory
- `presentation/providers/service_providers.dart` — Register new providers

---

## App Module 2: `/lib/image_utility/`

### Purpose

Image manipulation and wallpaper management (resize, crop, convert, export, download).

### Structure

```
image_utility/
├── core/
│   ├── config/app_config.dart
│   ├── providers/
│   │   ├── image_source_provider.dart
│   │   └── image_source_registry.dart
│   ├── router/app_router.dart       # GoRouter setup
│   ├── services/
│   │   ├── image_processing_service.dart
│   │   ├── ai_service.dart
│   │   └── tags_service.dart
│   └── utils/windows.dart
├── features/
│   ├── image_generation/
│   │   ├── data/
│   │   │   └── generators/
│   │   │       ├── image_generator.dart
│   │   │       ├── gemini_imagen_generator.dart
│   │   │       ├── firefly_generator.dart
│   │   │       └── upscayl_service.dart
│   │   └── presentation/
│   │       ├── providers/generation_provider.dart
│   │       └── pages/image_generation_page.dart
│   └── wallpapers/
│       ├── data/
│       │   ├── models/
│       │   │   └── wallpaper_model.dart
│       │   ├── providers/
│       │   │   ├── unsplash_provider.dart
│       │   │   ├── pexels_provider.dart
│       │   │   └── pixabay_provider.dart
│       │   └── repositories/wallpaper_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── wallpaper.dart
│       │   │   └── search_params.dart
│       │   └── repositories/wallpaper_repository.dart (interface)
│       └── presentation/
│           ├── pages/
│           │   ├── home_page.dart
│           │   ├── wallpaper_detail_page.dart
│           │   ├── bulk_download_page.dart
│           │   └── settings_page.dart
│           ├── providers/
│           │   ├── wallpaper_providers.dart
│           │   ├── download_provider.dart
│           │   └── bulk_download_provider.dart
│           └── widgets/source_selector.dart
└── resources/
```

### Entry Point

GoRouter-based (multiple routes)

### Features

- **Image Operations**: Resize, crop, convert, export
- **Wallpaper Downloads**: From Unsplash, Pexels, Pixabay
- **Image Generation**: Gemini, Firefly, Upscayl integration
- **Bulk Download**: Download multiple wallpapers
- **Wallpaper Detail**: View, tag, organize wallpapers

### State Management

- Riverpod FutureProviders for async operations
- StreamProviders for download progress
- StateNotifierProviders for local state

### Navigation Pattern

**GoRouter** with named routes in `core/router/app_router.dart`

### API Integrations

- Unsplash API
- Pexels API
- Pixabay API
- Google Generative AI (Gemini)
- Firefly AI
- Upscayl (upscaling service)

### Key Files to Update When Adding Features

- `features/[feature]/data/` — Add data sources
- `features/[feature]/domain/` — Add entities and repositories
- `features/[feature]/presentation/` — Add pages and providers
- `core/router/app_router.dart` — Register new routes

---

## App Module 3: `/lib/theme_deployment/`

### Purpose

Upload themes to designer portal and manage deployment automation.

### Structure

```
theme_deployment/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   └── pages/deployment_page.dart   # Entry point
└── [other files]
```

### Entry Point

`DeploymentPage`

### Features

- **Theme Upload**: Upload MTZ files
- **Designer Portal**: Access design management tools
- **Automation**: Scripting and batch operations

### State Management

- Basic Riverpod setup

### Navigation Pattern

Simple Navigator (single page app)

### Key Integration Points

- Theme upload endpoints
- Designer portal API
- Automation scripting

---

## App Module 4: `/lib/wall_rio/`

### Purpose

CMS for the WallRio app's wallpaper catalogs in **Firebase Storage**: upload
wallpapers (with automatic thumbnails), edit/delete entries, and restore
earlier catalog versions. Also shows AdMob / Play analytics and sends FCM pushes.

### Structure

```
wall_rio/
├── application/
│   ├── providers/
│   │   ├── catalog_provider.dart    # storage settings, client, catalog per kind, history
│   │   ├── credentials_provider.dart # Google OAuth (wallRioScopes incl. devstorage.read_write)
│   │   └── router_provider.dart     # GoRouter: /, /history, /settings
│   └── services/catalog_service.dart # load / publish / update / delete / restore
├── domain/
│   ├── catalog_rules.dart           # pure rules: URLs, ids, paths, resolution, validation
│   └── models/catalog.dart          # CatalogKind, CatalogDocument, WallpaperDraft, StorageSettings
├── infrastructure/services/
│   ├── storage_client.dart          # GCS JSON API (conditional upload, copy, list)
│   └── thumbnail_engine.dart        # header-only size read, thumbnails in an isolate
└── presentation/
    ├── screens/                     # dashboard, history, settings
    └── widgets/                     # upload_dialog, entry_edit_dialog, wallpaper_fields, storage_image
```

### Catalogs

| Kind | JSON | Min upload | Generated | Media paths |
|---|---|---|---|---|
| Mobile | `rio.Json` (`walls: [...]`) | 1720 × 3728 image | 430 × 932 thumbnail | `wallrio_wall_data/<Category>/<Name>.<ext>`, `…/Thumbnails/<Name>-small.jpg` |
| Desktop | `desktop.json` (`walls: [[...]]`) | 3840 × 2160 image | 640 × 360 thumbnail | `wallrio_wall_data/Desktop/<Name>.<ext>`, `…/Thumbnail/<Name>-small.jpg` |
| Live | `live_wall.json` (`walls: [...]`) | 1080 × 1920 MP4 | preview clip (fit 1280×720, 2 Mbps) + JPEG frame at 1 s (fit 960×540), via ffmpeg like `process_videos.py` | `wallrio_live/livewalls/<Name>.mp4`, `previews/<Name>_preview.mp4`, `thumbnails/<Name>.jpg` |
| Collections | `collections.json` (`collections: [{id, productId, name, hideForIOS?, walls}]`) | 1720 × 3728 image | 430 × 932 thumbnail | `wallrio_wall_data/<Collection>/<Name>.<ext>`, `…/Thumbnails/<Name>-small.jpg` |

- Live uploads need **ffmpeg/ffprobe** (`brew install ffmpeg`); `VideoEngine` looks in
  `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin` and `PATH`.
- Collection ids and wallpaper ids inside collections are strings; each collection keeps
  its own order (some are oldest first), and new wallpapers follow it.
- New collections are created from the Collections tab (name, in-app product id,
  hide on iOS). The app lists a collection as soon as it's saved, even when empty; the
  in-app product must be created in Play Console / App Store Connect separately.

### Rules the service enforces

- Images upload before the JSON, with `ifGenerationMatch=0`: **existing files are never
  overwritten** (the app caches images for a year), so a taken name must be renamed.
- Images: `Cache-Control: public, max-age=31536000, immutable`. JSON: gzipped,
  `Content-Encoding: gzip`, `Cache-Control: public, max-age=300`.
- Every JSON save first copies the live version to `wallriojson/history/<kind>/<timestamp>.json`
  and is conditional on the generation it was read at; on a conflict the edit is
  re-applied to the latest copy (up to 3 tries).
- New entries go to the top (newest first), id = max id + 1, author defaults to the newest entry's.
- Entries are matched by `url` (`videoUrl` for live; ids are not unique in the existing data).
- Bulk metadata: Upload → **Fill from JSON** (`domain/bulk_details.dart`); schema and example in
  `docs/wallrio_bulk_details.schema.json`. Entries match dropped files by name.

### Auth

The signed-in Google account (OAuth client in Settings → Credentials) calls the GCS
JSON API directly, so Firebase Storage rules don't apply to the CMS. Accounts signed
in before Storage was added must click **Switch** to grant the new scope.

### Tests

- `test/wall_rio/catalog_rules_test.dart` — pure rules.
- `test/wall_rio/catalog_service_storage_test.dart` — real bucket, throwaway folder;
  skipped unless `WALLRIO_TEST_TOKEN=$(gcloud auth print-access-token)` is set.

### Key Files to Update When Adding Features

- New catalog — add a `CatalogKind`, its paths (`CatalogRules.objectPaths`) and entry shape (`buildEntry`).
- `presentation/screens/` — Add new screens
- `application/providers/router_provider.dart` — Register routes

> The git classes (`git_models`, `git_repository`, `cli_git_repository`) and
> `ThumbnailEngine.generateThumbnail` remain only because BuffyWalls imports them.

---

## App Module 5: `/lib/buffy_walls/`

### Purpose

Wallpaper CMS with categorization and GitLab push integration.

### Structure

```
buffy_walls/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── screens/buffy_dashboard_screen.dart  # Entry point
│   └── widgets/
└── [data layer]
```

### Entry Point

`BuffyDashboardScreen`

### Features

- **Dashboard**: Overview of wallpapers
- **Category Manager**: Organize by category
- **Uploader**: Upload wallpapers with metadata
- **GitLab Integration**: Push to GitLab repository

### State Management

- Riverpod for state

### Navigation Pattern

Simple Navigator

### External Integration

- GitLab API

### Key Files to Update When Adding Features

- `presentation/screens/` — Add new screens
- `presentation/widgets/` — Add reusable components

---

## Reusable Widgets Module: `/lib/widgets/`

### Purpose

Shared components used across multiple apps.

### Contents

```
widgets/
├── glass_card.dart          # Glassmorphism container
├── app_icon_button.dart     # Themed icon button
└── iphone_frame.dart        # Device mockup frame
```

### Usage

Import from any app and use directly:

```dart
import 'package:miui_icon_generator/widgets/glass_card.dart';
```

---

## Module Integration Matrix

| Module            | Uses Image Utility | Uses Theme Editor | Uses WallRio | Uses AI |
| ----------------- | ------------------ | ----------------- | ------------ | ------- |
| Theme Editor      | ❌                 | —                 | ❌           | ❌      |
| Image Utility     | —                  | ❌                | ❌           | ✅      |
| Themes Deployment | ❌                 | ✅                | ❌           | ❌      |
| WallRio CMS       | ✅                 | ❌                | —            | ❌      |
| BuffyWalls CMS    | ✅                 | ❌                | ❌           | ❌      |

**Note**: Each app is independent. Cross-app communication should go through shared core only.

---

## Adding a New Module

### Steps

1. **Create module directory** in appropriate location:

   ```bash
   lib/[app_name]/
   # or
   lib/tools/[tool_name]/
   ```

2. **Create layer structure**:

   ```bash
   [module]/
   ├── core/              # App-specific services
   ├── data/              # API, repositories
   ├── domain/            # Entities, interfaces
   └── presentation/      # UI, pages, providers
   ```

3. **Create entry page** in `presentation/pages/`

4. **Register in launcher** (if new app):
   - Add to `_apps` list in `main.dart`
   - Create `_ModuleNameApp` wrapper class
   - Add to launcher screen grid

5. **Set up routing**:
   - Simple Navigator: Create entry screen
   - GoRouter: Create provider in `core/router/`

6. **Update MODULES.md** with module description

---

## Theme Editor: Widget Styles and Layers

- `WidgetStyle` and `WidgetStyleSet` are immutable domain entities. Styles contain validated appearance properties, not position, scale, layer identity, visibility, locking, or animation behavior. Rotation is appearance so diagonal controls remain reusable.
- `WidgetStyleRepository` defines persistence; `ManageWidgetStylesUseCase` captures styles and appends them to named collections. The data implementation owns JSON encoding, validation, PNG embedding, and library files under `<basePath>/WidgetStyles`.
- Portable files use `format: miui-editor.widget-style-set` and `version: 1`. Each style has an ID, name, element type, and appearance map. Custom icons are embedded as base64 `iconPng`, never external paths. Imports validate supported properties, finite numeric ranges, ARGB integer colors, PNG decoding and dimensions, safe IDs, unique styles, and file-size limits.
- Starter sets are read-only. Imported IDs are renamed on collision; built-in IDs are reserved. Removing a collection retains its materialized PNG assets because existing designs can reference them.
- `widget_style_provider.dart` wires the repository/use case and async library. `WidgetStylesPanel` handles selection and library commands. `UnlockControlPreview` is shared by the canvas and thumbnails; native unlock layout remains in `LockscreenNotifier`.
- Initial supported widgets are Tap to Unlock and Slide to Unlock. To add another widget, extend the domain-supported types and appearance schema, provide its thumbnail renderer in the presentation layer, and add corresponding preview/native-export tests. Repository transport and collection commands remain unchanged. Incompatible changes to the portable contract require a new version and explicit migration.
- `ElementNotifier.applyStyle` applies one undoable change to the active unlocked layer. Floating layers show frontmost first; drag indices are translated into the underlying back-to-front element list used by native export. Delete, visibility, and lock actions target element IDs.
- The fingerprint starter is a visual Tap unlock style, not a biometric-authentication implementation.
- Preset thumbnails use the canvas unlock, shortcut, analog, and calendar renderers. Custom unlock icon/target images are bundled under the preset's `assets/` directory and resolved by the preset repository, including for card previews. Legacy absolute paths remain readable.
- Native slider paths use a screen-width tolerance to avoid canceling fast overshooting gestures; zero anchors and endpoint-constrained movement must remain unchanged.
- Apply to Device > Theme push path selects either `/sdcard/Download/auto/temp.mtz` (default) or `/sdcard/Android/data/com.android.thememanager/files/temp.mtz`. The persisted selection controls push, verification, and every apply intent, and is disabled during device operations.
- Calendar widgets and styles support Use Wallpaper Colors for their text, selected date, panel, and strip/circle palette. Outline Width is shown only for renderers that consume it: non-classic unlock skins, Classic/Ring/Crimson Glass/Frosted Glass analog styles, and adjustable-border shortcut panels. Calendar and borderless styles do not expose the slider.
- Shortcut styles must not substitute another app's identity. Native launches share one builder: system intents resolve phone, SMS, contacts, calendar, and settings; named apps resolve their package's launcher instead of a fixed activity class. Flashlight remains a broadcast without unlocking.
- Focused regression coverage: `test/theme_editor/lockscreen_regressions_test.dart` and `test/theme_editor/preset_favorites_test.dart`.

## Maintenance: Module Health Check

For each module, verify:

- [ ] Clean layer separation (data/domain/presentation)
- [ ] No cross-app imports (except core and widgets)
- [ ] Uses Riverpod exclusively
- [ ] All colors from `AppColors`
- [ ] All spacing from `AppSpacing`
- [ ] All radius from `AppRadius`
- [ ] Documentation in MODULES.md
- [ ] Follows naming conventions
- [ ] Entry point is clear

---

**Total Modules**: 7 apps + 1 core + 1 widgets = 9  
**Navigation Patterns**: 2 (Simple Navigator, GoRouter)  
**State Management**: Riverpod only  
**Last Updated**: 2026-06-09
