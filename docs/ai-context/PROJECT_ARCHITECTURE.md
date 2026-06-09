# Project Architecture

## Overview

**Team Shadow Tools** is a multi-app Flutter desktop/mobile application with a central launcher that hosts 7 independent sub-applications. Each sub-app is a fully self-contained Flutter application with its own MaterialApp, routing, and state management.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Team Shadow Tools Launcher                  │
│                      (main.dart, AppLauncherScreen)            │
│                                                                 │
│  ┌─────────────────────┐ ┌──────────────────┐ ┌─────────────┐ │
│  │  Theme Editor App   │ │ Image Utility    │ │   WallRio   │ │
│  │  (MaterialApp)      │ │ (MaterialApp.    │ │   CMS       │ │
│  │                     │ │  router)         │ │ (Router)    │ │
│  └─────────────────────┘ └──────────────────┘ └─────────────┘ │
│                                                                 │
│  ┌──────────────────┐ ┌──────────────┐ ┌─────────────────────┐│
│  │ Themes           │ │ SVG          │ │ BuffyWalls CMS      ││
│  │ Deployment       │ │ Converter    │ │                     ││
│  │                  │ │              │ │                     ││
│  └──────────────────┘ └──────────────┘ └─────────────────────┘│
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                    AI Upscaler                           │ │
│  │                                                          │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Uses
                              ▼
                    ┌──────────────────┐
                    │   Core Shared    │
                    │   Components     │
                    ├──────────────────┤
                    │ • Theme System   │
                    │ • Colors         │
                    │ • Typography     │
                    │ • Spacing        │
                    │ • Riverpod Setup │
                    └──────────────────┘
```

## 7 Sub-Applications

### 1. Theme Editor
**Location**: `lib/theme_editor/`  
**Purpose**: MIUI Theme Editor for lockscreens, icons, module themes, MTZ files  
**Entry**: `UserProfileScreen` from `theme_editor/presentation/features/splash/`  
**Features**:
- Lockscreen customization
- Icon pack management
- Theme module editing
- MTZ file export/import

### 2. Image Utility
**Location**: `lib/image_utility/`  
**Purpose**: Image manipulation (resize, crop, convert, export)  
**Entry**: GoRouter-based (file: `image_utility/core/router/app_router.dart`)  
**Features**:
- Image resizing and cropping
- Format conversion
- Batch operations
- Wallpaper downloads from multiple sources

### 3. Themes Deployment
**Location**: `lib/theme_deployment/`  
**Purpose**: Upload themes, manage designer portal, automation  
**Entry**: `DeploymentPage`  
**Features**:
- Theme upload workflows
- Designer portal integration
- Automation scripting

### 4. WallRio CMS
**Location**: `lib/wall_rio/`  
**Purpose**: Wallpaper CMS with Git integration and analytics  
**Entry**: GoRouter-based (file: `wall_rio/application/providers/router_provider.dart`)  
**Storage**: Hive local database (registered adapters: `SavedFilePathImplAdapter`, `LocalVersionImplAdapter`)  
**Features**:
- Wallpaper management
- Git version control
- Analytics dashboard
- Push notifications

### 5. SVG Converter
**Location**: `lib/tools/svg_converter/`  
**Purpose**: Image to SVG conversion with VTracer integration  
**Entry**: `HomeScreen` in `tools/svg_converter/ui/screens/`  
**Features**:
- Single image SVG conversion
- Batch conversion
- VTracer integration

### 6. BuffyWalls CMS
**Location**: `lib/buffy_walls/`  
**Purpose**: Wallpaper management with categories and GitLab push  
**Entry**: `BuffyDashboardScreen`  
**Features**:
- Wallpaper categorization
- GitLab integration
- Dashboard management

### 7. AI Upscaler
**Location**: `lib/tools/ai_upscaler/`  
**Purpose**: AI-powered image enhancement (wallpapers, icons, batch)  
**Entry**: `AiUpscalerScreen`  
**Features**:
- Image upscaling with AI
- Batch processing
- Wallpaper and icon support

## Core Shared Structure

### `/lib/core/` — Global Shared Components

#### Theme System (`/lib/core/theme/`)
```
theme/
├── app_colors.dart       # All color tokens (AMOLED Purple palette)
├── app_theme.dart        # ThemeData for light/dark modes
├── app_radius.dart       # Border radius tokens
├── app_spacing.dart      # Spacing/padding constants
├── theme_extensions.dart # AppColorScheme extension
└── theme_provider.dart   # Riverpod theme mode provider
```

**Key Design Token Files**:
- `AppColors`: Central color registry (no hardcoded colors allowed)
- `AppRadius`: Border radius constants (xs, sm, md, lg, xl, xxl)
- `AppSpacing`: Margin/padding constants
- `AppColorScheme`: ThemeExtension for `context.appColors` access

### Initialization Flow

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Platform-specific init
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await WindowService.init();
  }
  
  if (Platform.isAndroid) {
    await requestPermissions();
  }
  
  // Hive for WallRio
  await Hive.initFlutter();
  Hive.registerAdapter(...);
  
  // Video player
  VideoPlayerMediaKit.ensureInitialized(...);
  
  // Run app
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const RootApp(),
    ),
  );
}
```

## State Management: Flutter Riverpod

All sub-apps use **Flutter Riverpod 3.3.1** for state management.

### Provider Types Used

```dart
// Simple value provider
final appNameProvider = Provider((ref) => 'Theme Editor');

// State notifier for mutable state
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(...);

// Future provider for async data
final fetchWallpapersProvider = FutureProvider<List<Wallpaper>>(...);

// Stream provider for real-time data
final downloadProgressProvider = StreamProvider<double>(...);
```

### Riverpod Setup
- **Location**: Each app has its own `presentation/providers/` directory
- **Shared Providers**: Core providers in `core/theme/theme_provider.dart`
- **Access Pattern**: `ref.watch(provider)` in widgets, `ref.read(provider.notifier)` for mutations

## Navigation Architecture

### Two Navigation Patterns

#### Pattern 1: SimpleNavigator (Theme Editor, Theme Deployment, SVG Converter, BuffyWalls, AI Upscaler)
- Uses standard `Navigator.of(context).push()`
- Simpler, single-page flows
- MaterialApp with `home:` property

#### Pattern 2: GoRouter (Image Utility, WallRio CMS)
- Named routes with type safety
- Complex multi-page flows
- MaterialApp.router with `routerConfig:`
- Route definitions in feature-specific files

### GoRouter Example Structure
```dart
// In image_utility/core/router/app_router.dart
final routerProvider = Provider((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/home', builder: (_, __) => HomePage()),
      GoRoute(path: '/detail/:id', builder: (_, state) => DetailPage()),
    ],
  );
});
```

## Data Flow Architecture

### Layer Separation

```
┌────────────────────────────────────────┐
│     Presentation Layer (UI)            │
│  - Pages/Screens                       │
│  - Widgets                             │
│  - Controllers/Notifiers               │
│  - Providers (UI state)                │
└────────────────┬───────────────────────┘
                 │ depends on
                 ▼
┌────────────────────────────────────────┐
│     Domain Layer (Business Logic)      │
│  - Entities                            │
│  - Repository Interfaces               │
│  - Use Cases                           │
└────────────────┬───────────────────────┘
                 │ implements
                 ▼
┌────────────────────────────────────────┐
│     Data Layer (External & Storage)    │
│  - API Clients (Dio, Http)             │
│  - Local Storage (Hive, SharedPrefs)   │
│  - Repository Implementations          │
└────────────────────────────────────────┘
```

### Example: Wallpaper Fetching

```
User taps "Load Wallpapers"
    ↓
WallpaperListPage (Presentation) calls
    ↓
ref.watch(wallpaperProvider) from Providers
    ↓
FutureProvider executes WallpaperRepository.fetch()
    ↓
Repository queries UnsplashProvider/PexelsProvider/PixabayProvider (Data)
    ↓
HTTP calls via Dio return raw data
    ↓
Repository maps to Wallpaper entities (Domain)
    ↓
UI re-renders with wallpaper list
```

## Dependency Injection

### SharedPreferences Provider
```dart
// Global access to SharedPreferences
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Overridden at app startup
runApp(
  ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs)
    ],
    child: const RootApp(),
  ),
);
```

### App-Specific Providers
Each sub-app has its own `presentation/providers/service_providers.dart`:
```dart
final apiClientProvider = Provider((ref) => DioClient(...));
final repositoryProvider = Provider((ref) => MyRepository(ref.watch(apiClientProvider)));
```

## Module Structure Template

All feature modules follow this structure:

```
feature_name/
├── data/
│   ├── datasources/
│   │   └── remote_datasource.dart
│   ├── models/
│   │   └── entity_model.dart
│   ├── providers/
│   │   └── api_provider.dart
│   └── repositories/
│       └── entity_repository.dart
├── domain/
│   ├── entities/
│   │   └── entity.dart
│   └── repositories/
│       └── entity_repository.dart (interface)
└── presentation/
    ├── providers/
    │   └── entity_provider.dart
    ├── pages/
    │   └── entity_list_page.dart
    └── widgets/
        └── entity_card.dart
```

## Key Technologies

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| State | flutter_riverpod | 3.3.1 | State management |
| Navigation | go_router | 17.1.0 | Routing (Image Utility, WallRio) |
| UI | Flutter Material 3 | - | UI framework |
| Local Storage | hive_flutter | 1.1.0 | WallRio database |
| Local Storage | shared_preferences | 2.2.2 | App settings |
| HTTP | dio | 5.9.2 | API calls |
| Images | cached_network_image | 3.4.1 | Image caching |
| AI | google_generative_ai | 0.4.7 | AI features |
| Serialization | json_annotation, freezed_annotation | - | Data models |
| Fonts | google_fonts | 6.2.1 | Typography |
| Platform | window_manager | 0.5.1 | Desktop windows |

## File Picker & Desktop Drop

- **file_picker**: Cross-platform file selection
- **desktop_drop**: Drag-and-drop support
- **permission_handler**: Platform permissions
- **path_provider**: Cross-platform paths

## Error Handling

### Widget-Level Error Handling
```dart
ErrorWidget.builder = (details) => Container(
  color: AppColors.darkSurface0,
  child: Text(details.exceptionAsString()),
);
```

### Try-Catch in Providers
```dart
ref.onError((error, stackTrace) {
  // Log error, show snackbar
  ScaffoldMessenger.of(context).showSnackBar(...);
});
```

## Platform Support

- **Desktop**: Windows, macOS, Linux (WindowService for init)
- **Mobile**: Android, iOS (permission_handler for runtime permissions)
- **Web**: Not currently targeted

### Platform-Specific Init
```dart
if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
  await WindowService.init();
  await startUpWindowsUtils();
}

if (Platform.isAndroid) {
  await [Permission.storage, Permission.manageExternalStorage].request();
}
```

---

**Architectural Pattern**: Clean Architecture + Riverpod  
**Navigation Pattern**: Mixed (Simple Navigator + GoRouter)  
**State Management**: Riverpod only (no BLoC, Cubit, GetX, etc.)
