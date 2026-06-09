# Development Rules: Strict Enforcement

These are non-negotiable rules for all code in this project. Violations should be caught in code review.

## Color System Rules

### Rule 1: Never Hardcode Colors
**Violation Level**: CRITICAL

```dart
// ❌ FORBIDDEN - All variations
Container(color: Color(0xFF16111F))
Container(color: const Color.fromARGB(255, 22, 17, 31))
Container(color: Colors.black87)
Container(color: Color(0xFF9B5CFF))
ElevatedButton(backgroundColor: Colors.purple)

// ✅ CORRECT
Container(color: AppColors.darkSurface0)
Container(color: context.appColors.surface)
ElevatedButton(backgroundColor: AppColors.purplePrimary)
```

**Enforcement**:
- Code review catches all hardcoded hex values
- Grep: `Color(0x` → Find violations
- No exceptions for any reason

---

## Architecture Rules

### Rule 2: Maintain Layer Separation
**Violation Level**: CRITICAL

```dart
// ❌ WRONG: Presentation calling data layer directly
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpapers = ref.watch(wallpaperRepositoryProvider);  // Direct data access
  }
}

// ✅ CORRECT: Presentation → Domain → Data
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpapers = ref.watch(wallpaperProvider);  // Provider handles layers
  }
}

// ❌ WRONG: Data layer calling presentation
class WallpaperRepository {
  void showSnackBar() { ... }  // Data shouldn't know about UI
}

// ✅ CORRECT: Data throws exception, UI handles it
class WallpaperRepository {
  Future<List<Wallpaper>> fetch() async {
    throw NetworkException('No internet');
  }
}
```

**Enforcement**:
- Review file structure: no cross-layer imports except upward
- Check imports in data/ — should never import presentation/
- Repositories return data or throw exceptions, never UI calls

---

### Rule 3: No Cross-App Imports (Except Core)
**Violation Level**: CRITICAL

```dart
// ❌ FORBIDDEN: Theme Editor accessing Image Utility
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/pages/wallpaper_detail_page.dart';

// ✅ ALLOWED: Theme Editor using core
import 'package:miui_icon_generator/core/theme/app_colors.dart';

// ✅ ALLOWED: Internal feature imports within same app
import '../other_feature/presentation/pages/settings_page.dart';
```

**Enforcement**:
- Each app is independent
- Only `lib/core/` and `lib/widgets/` are shared
- No app-to-app imports allowed
- Use messaging or state if apps must communicate (future: Firebase, EventBus, etc.)

---

## State Management Rules

### Rule 4: Riverpod Only
**Violation Level**: CRITICAL

```dart
// ❌ FORBIDDEN: Any other state management
class MyWidget extends StatefulWidget { ... }  // Use Riverpod instead
class MyBloc extends Bloc { ... }              // No BLoC pattern
class MyController extends GetxController { } // No GetX
class MyViewModel extends ChangeNotifier { }  // No ChangeNotifier

// ✅ CORRECT: Riverpod exclusively
final myStateProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(initialState);
});

final myDataProvider = FutureProvider<Data>((ref) async {
  return fetchData();
});
```

**Enforcement**:
- No StatefulWidget in new code (migrating old widgets is OK)
- All state goes through Riverpod
- Code review rejects any state pattern except Riverpod

---

### Rule 5: Provider Organization
**Violation Level**: HIGH

```dart
// ❌ WRONG: Provider in wrong location
lib/image_utility/features/wallpapers/pages/home_page.dart
  final wallpaperProvider = FutureProvider(...);  // Should be in providers/

// ✅ CORRECT: Provider in dedicated file
lib/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart
  final wallpaperProvider = FutureProvider(...);
```

**Enforcement**:
- All providers live in `presentation/providers/[feature]_providers.dart`
- Never inline providers in pages/widgets
- Shared providers go in `lib/core/theme/theme_provider.dart`

---

## Navigation Rules

### Rule 6: Follow App's Navigation Pattern
**Violation Level**: MEDIUM

```dart
// Image Utility & WallRio: Use GoRouter
// ✅ CORRECT
final routerProvider = Provider((ref) {
  return GoRouter(routes: [...]);
});

// ❌ WRONG: Using Navigator
Navigator.of(context).push(MaterialPageRoute(...));

// Theme Editor & others: Use Navigator
// ✅ CORRECT
Navigator.of(context).push(PageRouteBuilder(...));

// ❌ WRONG: Using GoRouter in non-router apps
GoRouter(routes: [...])
```

**Enforcement**:
- Image Utility + WallRio: GoRouter only
- Others: Navigator only
- Don't mix patterns in same app

---

## Widget & Component Rules

### Rule 7: No Widget Duplication
**Violation Level**: HIGH

```dart
// ❌ WRONG: Creating duplicate button
class CustomButton extends StatelessWidget {
  // Already exists as AppIconButton
}

// ✅ CORRECT: Reuse existing
import '../../../widgets/app_icon_button.dart';
AppIconButton(icon: Icons.edit, onPressed: () {})

// Before creating: Check lib/widgets/ and app-specific widgets/
```

**Enforcement**:
- Search `lib/widgets/` before creating
- Search app's `presentation/widgets/` before creating
- If similar exists, extend or parameterize instead of duplicating

---

### Rule 8: Use Theme Tokens for Everything Visual
**Violation Level**: CRITICAL

```dart
// ❌ WRONG: Hardcoded spacing
Padding(padding: const EdgeInsets.all(16), child: child)
Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: child)

// ✅ CORRECT
Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child)
Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: child)

// ❌ WRONG: Hardcoded radius
BorderRadius.circular(12)

// ✅ CORRECT
AppRadius.radiusMd

// ❌ WRONG: Hardcoded text styles
TextStyle(fontSize: 16, fontWeight: FontWeight.w600)

// ✅ CORRECT
Theme.of(context).textTheme.titleMedium
```

**Enforcement**:
- No magic numbers in UI code
- All visual decisions use design tokens
- Code review rejects any hardcoded values

---

## Module Structure Rules

### Rule 9: Follow Consistent Module Structure
**Violation Level**: HIGH

```dart
// ✅ REQUIRED structure for every feature
feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   ├── providers/
│   └── repositories/
├── domain/
│   ├── entities/
│   └── repositories/
└── presentation/
    ├── pages/
    ├── widgets/
    └── providers/

// ❌ WRONG: Random structure
feature/
├── models/
├── screens/
└── services/
```

**Enforcement**:
- New features must follow structure exactly
- No shortcuts or custom layouts
- Code review verifies folder structure

---

### Rule 10: File Organization Within Modules
**Violation Level**: MEDIUM

```dart
// ❌ WRONG: Too much in one file
lib/image_utility/features/wallpapers/data/repositories.dart
  // Contains 5 different repository classes
  // Contains model definitions
  // Contains API client logic

// ✅ CORRECT: Organized
lib/image_utility/features/wallpapers/data/
├── datasources/
│   ├── unsplash_datasource.dart
│   ├── pexels_datasource.dart
│   └── pixabay_datasource.dart
├── models/
│   ├── wallpaper_model.dart
│   ├── search_params_model.dart
│   └── download_model.dart
└── repositories/
    └── wallpaper_repository.dart
```

**Enforcement**:
- One class per file (with rare exceptions for related models)
- Clear file naming that matches class name
- Related classes grouped in folders

---

## API & Data Rules

### Rule 11: No Direct API Calls in UI
**Violation Level**: CRITICAL

```dart
// ❌ FORBIDDEN: Direct API in UI
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpapers = await Dio().get('/wallpapers');  // ❌ WRONG
  }
}

// ✅ CORRECT: Through repository
final wallpaperProvider = FutureProvider((ref) async {
  final repo = ref.watch(wallpaperRepositoryProvider);
  return repo.fetchWallpapers();
});

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpapers = ref.watch(wallpaperProvider);  // ✅ CORRECT
  }
}
```

**Enforcement**:
- All HTTP calls in data/datasources/
- Repositories orchestrate datasource calls
- UI only uses providers

---

### Rule 12: Repository Pattern
**Violation Level**: HIGH

```dart
// ✅ CORRECT: Repository interface in domain
// lib/image_utility/features/wallpapers/domain/repositories/wallpaper_repository.dart
abstract class IWallpaperRepository {
  Future<List<Wallpaper>> fetchWallpapers({required String resolution});
  Future<void> saveWallpaper(Wallpaper wallpaper);
}

// Implementation in data
// lib/image_utility/features/wallpapers/data/repositories/wallpaper_repository.dart
class WallpaperRepository implements IWallpaperRepository {
  final _unsplashSource = UnsplashDatasource();
  
  @override
  Future<List<Wallpaper>> fetchWallpapers({required String resolution}) async {
    final models = await _unsplashSource.search(resolution);
    return models.map((m) => Wallpaper.fromModel(m)).toList();
  }
}
```

**Enforcement**:
- Repositories defined as interfaces in domain/
- Implementations in data/
- Providers inject repositories

---

## Testing & Quality Rules

### Rule 13: Error Handling
**Violation Level**: HIGH

```dart
// ❌ WRONG: Silent failures
try {
  await fetchWallpapers();
} catch (e) {
  // Ignore error
}

// ✅ CORRECT: Specific handling
try {
  final wallpapers = await repo.fetch();
} on NetworkException {
  state = AsyncError(NetworkException(...));
} on ParseException {
  state = AsyncError(ParseException(...));
} catch (e) {
  state = AsyncError(UnknownException(...));
}

// UI handles async errors
ref.watch(provider).whenData((data) {
  // Show data
}).onError((error, st) {
  // Show error UI
});
```

**Enforcement**:
- No try-catch without handling
- Specific exception types
- Propagate to UI as AsyncError

---

## Documentation Rules

### Rule 14: Documentation for Public APIs
**Violation Level**: MEDIUM

```dart
// ❌ NO DOCS
void fetchData() { ... }

class UserRepository { ... }

final userProvider = FutureProvider(...);

// ✅ WITH DOCS
/// Fetches wallpapers from all sources and returns combined list.
///
/// This method aggregates results from Unsplash, Pexels, and Pixabay
/// based on the provided [resolution] and [searchTerm].
Future<List<Wallpaper>> fetchWallpapers({
  required String resolution,
  required String searchTerm,
}) async { ... }

/// Repository for managing wallpaper data.
///
/// Handles fetching from multiple sources and caching locally.
class WallpaperRepository { ... }

/// Provides list of available wallpapers.
///
/// Cached for 5 minutes. Refetch with [ref.refresh()].
final wallpaperProvider = FutureProvider((ref) async { ... });
```

**Enforcement**:
- All public classes documented
- All public methods documented
- All public providers documented
- High-level explanations + parameters

---

## Naming Convention Rules

### Rule 15: Follow Naming Standards
**Violation Level**: MEDIUM

```dart
// ❌ WRONG
class userProfile { }              // Class lowercase
void getUser() { }                 // Method not descriptive
final User = 'John';               // Constant not uppercase
class LoadingIndicatorWidget { }   // Redundant suffix
final myData_value = 5;            // Mixed case
var x = 10;                        // Cryptic name

// ✅ CORRECT
class UserProfile { }              // Class PascalCase
UserProfile? fetchUser(String id) { }  // Method verb+noun, return type clear
const String kDefaultName = 'John'; // Constant with k prefix
class LoadingIndicator { }         // No redundant suffix
final myDataValue = 5;             // camelCase
final maxRetries = 10;             // Clear name
```

**Enforcement**:
- Enforce via Dart linter (included in analysis_options.yaml)
- Code review checks naming

---

## Platform-Specific Rules

### Rule 16: Platform Detection
**Violation Level**: MEDIUM

```dart
// ✅ CORRECT: Platform checks
if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
  await WindowService.init();
}

if (Platform.isAndroid) {
  await requestPermissions();
}

// ❌ WRONG: Feature detection inconsistent
if (kIsWeb) { }  // Platform detection in UI code without checks
```

**Enforcement**:
- Platform init happens in main.dart only
- Feature detection wrapped in platform checks
- Consistent patterns across apps

---

## Performance Rules

### Rule 17: Avoid Rebuilds
**Violation Level**: MEDIUM

```dart
// ❌ WRONG: Causes rebuilds
class MyWidget extends ConsumerWidget {
  List<String> items = [1, 2, 3];  // Recreated every build
}

// ✅ CORRECT: Extract to provider
final itemsProvider = Provider((ref) => ['1', '2', '3']);

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);  // Only rebuilds when provider changes
  }
}

// ❌ WRONG: Provider recreation
final myProvider = StateNotifierProvider((ref) {
  return MyNotifier();  // New instance every time
});

// ✅ CORRECT: Cache provider
final myProvider = StateNotifierProvider((ref) {
  return MyNotifier();  // Same instance across rebuilds
});
```

**Enforcement**:
- Use const constructors
- Extract constants to providers
- Avoid unnecessary rebuilds in code review

---

## Security Rules

### Rule 18: No Secrets in Code
**Violation Level**: CRITICAL

```dart
// ❌ FORBIDDEN
const String apiKey = 'sk_live_abc123';
const String databaseUrl = 'postgresql://user:password@host/db';

// ✅ CORRECT: Environment variables
final apiKey = const String.fromEnvironment('API_KEY');
final databaseUrl = const String.fromEnvironment('DATABASE_URL');
```

**Enforcement**:
- Pre-commit hook scans for secrets
- Code review catches hardcoded keys
- Use environment variables only

---

## Quick Violation Checklist

| Rule | Severity | Check |
|------|----------|-------|
| Hardcoded colors | CRITICAL | `Color(0x` in search |
| Cross-app imports | CRITICAL | No `lib/[app]/` in other apps |
| Riverpod only | CRITICAL | No StatefulWidget, BLoC, GetX |
| API in UI | CRITICAL | No `.get()` in presentation/ |
| Secrets in code | CRITICAL | No hardcoded keys |
| Direct data access | CRITICAL | Only providers in UI |
| Hardcoded spacing | CRITICAL | Use `AppSpacing.*` |
| Wrong architecture | HIGH | Verify layer structure |
| No widget duplication | HIGH | Check before creating |
| Theme tokens | CRITICAL | Use `AppRadius`, `AppColors` |

---

**Enforcement Level**: 0 Tolerance  
**Code Review**: All violations require fixes before merge  
**Last Updated**: 2026-06-09  
**Author**: Team Shadow (AI Context)
