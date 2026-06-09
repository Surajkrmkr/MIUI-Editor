# Modules & Features Directory

This document maps all modules in the project and their purposes.

## Module Dependency Map

```
RootApp (Launcher)
├── Theme Editor (MaterialApp)
├── Image Utility (MaterialApp.router - GoRouter)
├── Themes Deployment (MaterialApp)
├── WallRio CMS (MaterialApp.router - GoRouter)
│   └── Hive Database
├── SVG Converter (MaterialApp)
├── BuffyWalls CMS (MaterialApp)
└── AI Upscaler (MaterialApp)

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
CMS for wallpaper management with Git version control and analytics.

### Structure
```
wall_rio/
├── application/
│   └── providers/
│       └── router_provider.dart     # GoRouter setup
├── domain/
│   ├── entities/
│   ├── models/cms_models.dart       # Hive models
│   └── repositories/
├── presentation/
│   ├── screens/
│   ├── pages/
│   └── widgets/
└── [data layer]
```

### Entry Point
GoRouter-based routing

### Storage
**Hive** local database for:
- Saved file paths (`SavedFilePathImplAdapter`)
- Local versions (`LocalVersionImplAdapter`)

### Features
- **Wallpaper Management**: Organize, categorize wallpapers
- **Git Integration**: Version control for wallpapers
- **Analytics**: Tracking and insights
- **Push Notifications**: Update notifications

### State Management
- Riverpod for UI state
- Hive for persistent data

### Navigation Pattern
**GoRouter** with routes in `application/providers/router_provider.dart`

### Database Adapters
Register in `main.dart`:
```dart
Hive.registerAdapter(SavedFilePathImplAdapter());
Hive.registerAdapter(LocalVersionImplAdapter());
```

### Key Files to Update When Adding Features
- `domain/models/cms_models.dart` — Add Hive model classes
- `presentation/screens/` — Add new screens
- `application/providers/router_provider.dart` — Register routes

---

## App Module 5: `/lib/tools/svg_converter/`

### Purpose
Convert images to SVG format with batch processing and VTracer integration.

### Structure
```
tools/svg_converter/
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart         # Entry point
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── task_list.dart
│       └── stats_panel.dart
└── [data/domain layers]
```

### Entry Point
`HomeScreen`

### Features
- **Single Conversion**: Convert one image to SVG
- **Batch Conversion**: Process multiple images
- **VTracer Integration**: Advanced vectorization
- **Settings**: Quality and processing options

### State Management
- Basic Riverpod

### Navigation Pattern
Simple Navigator (single-feature app)

### External Integration
- VTracer (image vectorization engine)

---

## App Module 6: `/lib/buffy_walls/`

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

## App Module 7: `/lib/tools/ai_upscaler/`

### Purpose
AI-powered image enhancement for wallpapers, icons, and batch processing.

### Structure
```
tools/ai_upscaler/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── screens/ai_upscaler_screen.dart  # Entry point
│   └── widgets/
└── [data layer]
```

### Entry Point
`AiUpscalerScreen`

### Features
- **Upscale Images**: AI enhancement (4x, 2x)
- **Batch Processing**: Process multiple files
- **Format Support**: Wallpapers, icons, general images
- **Quality Settings**: Control upscaling parameters

### State Management
- Riverpod with StreamProviders for progress

### Navigation Pattern
Simple Navigator

### AI Services
- Upscayl API integration
- Local AI model support

### Key Files to Update When Adding Features
- `domain/entities/` — Add upscaling parameters
- `presentation/screens/` — Add new upscale workflows

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

| Module | Uses Image Utility | Uses Theme Editor | Uses WallRio | Uses AI |
|--------|-------------------|------------------|------------|---------|
| Theme Editor | ❌ | — | ❌ | ❌ |
| Image Utility | — | ❌ | ❌ | ✅ |
| Themes Deployment | ❌ | ✅ | ❌ | ❌ |
| WallRio CMS | ✅ | ❌ | — | ❌ |
| SVG Converter | ❌ | ❌ | ❌ | ❌ |
| BuffyWalls CMS | ✅ | ❌ | ❌ | ❌ |
| AI Upscaler | ❌ | ❌ | ❌ | — |

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
