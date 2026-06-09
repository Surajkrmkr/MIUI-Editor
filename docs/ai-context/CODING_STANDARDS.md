# Coding Standards

All code in this project must follow these standards to maintain consistency and quality.

## File & Folder Naming

### Dart Files
```
✅ CORRECT
lib/theme_editor/presentation/pages/user_profile_page.dart
lib/image_utility/features/wallpapers/data/models/wallpaper_model.dart
lib/widgets/glass_card.dart

❌ INCORRECT
lib/ThemeEditor/presentation/pages/UserProfilePage.dart  (PascalCase folders)
lib/image_utility/presentation/pages/userProfilePage.dart (camelCase)
lib/Widgets/GlassCard.dart (PascalCase folders)
```

### Rules
- **Folders**: snake_case
- **Files**: snake_case.dart
- **Directories**: Feature names as snake_case
- **No spaces**: Use underscores

### Consistent Paths
```
/lib/[module]/
├── core/
├── data/
├── domain/
├── presentation/
├── features/        (only in some modules)
└── resources/
```

## Class & Type Naming

### Classes
```dart
// ✅ Screens/Pages
class UserProfileScreen extends StatelessWidget {}
class WallpaperDetailPage extends ConsumerWidget {}

// ✅ Widgets
class WallpaperCard extends StatelessWidget {}
class AppIconButton extends StatelessWidget {}

// ✅ Controllers/Notifiers
class ThemeNotifier extends StateNotifier<ThemeState> {}
class WallpaperController extends StateNotifier<List<Wallpaper>> {}

// ✅ Services
class ImageProcessingService {}
class WallpaperRepository {}

// ✅ Models
class WallpaperModel {}
class UserProfileModel {}

// ✅ Entities
class Wallpaper {}
class UserProfile {}

// ❌ INCORRECT
class userProfile {}          (lowercase)
class UserProfileWidget {}    (redundant Widget suffix)
class UserProfileBloc {}      (no BLoC pattern)
class MyWidget {}             (generic names)
```

### Rules
- **Screens**: `[Feature]Screen` or `[Feature]Page`
- **Widgets**: `[Feature][Component]` or `[Action]Button`
- **Notifiers**: `[Feature]Notifier`
- **Services**: `[Purpose]Service`
- **Repositories**: `[Entity]Repository`
- **Models**: `[Entity]Model`
- **Entities**: `[Entity]` (no suffix)
- **Use PascalCase** for all classes

## Variable & Property Naming

### Local Variables
```dart
// ✅ Clear names
final wallpaperList = ref.watch(wallpaperProvider);
final isLoading = state.isLoading;
final selectedColor = AppColors.purplePrimary;
var scrollController = ScrollController();

// ❌ Generic/cryptic names
final data = ref.watch(provider);
final x = Colors.purple;
final a = 5;
```

### Private Variables
```dart
// ✅ Prefix with underscore
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final AnimationController _animationCtrl;
  final _formKey = GlobalKey<FormState>();
}

// ❌ No private members without underscore
class MyWidget {
  final private = 'value';  // Should be _private
}
```

### Rules
- **Local**: camelCase, descriptive
- **Private**: `_prefix`
- **Constants**: `const` values in UPPER_CASE only when truly constant
- **Booleans**: `is`, `has`, `can` prefix (`isLoading`, `hasError`, `canSave`)

## Method & Function Naming

### Methods
```dart
// ✅ Action-based
void saveProfile() {}
Future<void> fetchWallpapers() {}
List<Wallpaper> filterByResolution(int width, int height) {}
void onWallpaperTap(Wallpaper wallpaper) {}

// ✅ Getter-like (no side effects)
bool isValidEmail(String email) {}
Color getColorByBrightness(bool isDark) {}
String formatFileSize(int bytes) {}

// ❌ Vague
void process() {}
void do_something() {}
void execute() {}
```

### Rules
- **Action**: Verb + object (`saveProfile`, `fetchData`, `deleteItem`)
- **Boolean**: `is`, `has`, `can` prefix (`isValid`, `hasError`, `canDelete`)
- **Getter**: Descriptive name starting with verb (`getColor`, `formatDate`)
- **Event handlers**: `on` + event (`onTap`, `onLongPress`, `onChanged`)
- **camelCase** for all methods

## Provider Naming (Riverpod)

### Provider Variables
```dart
// ✅ Suffixes indicate type
final wallpaperProvider = FutureProvider<List<Wallpaper>>(...);
final downloadProgressProvider = StreamProvider<double>(...);
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(...);
final apiConfigProvider = Provider<ApiConfig>(...);

// ❌ Generic
final data = FutureProvider(...)
final notifier = StateNotifierProvider(...)
```

### Rules
- **FutureProvider**: `[entity]Provider`
- **StreamProvider**: `[entity]StreamProvider` or `[entity]ProgressProvider`
- **StateNotifierProvider**: `[feature]NotifierProvider`
- **Provider**: `[entity]Provider` or `[config]Provider`
- Always end with `Provider`
- Suffixes: `Notifier`, `Stream`, `Config` when needed

## Constant Naming

### Design Tokens
```dart
// ✅ Already in core/theme
AppColors.purplePrimary         // Color
AppRadius.radiusMd              // Border radius
AppSpacing.lg                   // Spacing

// ✅ Exported constants
const double kAnimationDuration = 300;
const Duration kDefaultDelay = Duration(milliseconds: 300);
```

### Rules
- **Design Tokens**: Already centralized in `core/theme/`
- **Local Constants**: `k` prefix + UPPER_CASE (`kDefaultPadding`)
- **Never hardcode** magic numbers without extraction

## Import Organization

### Import Groups
```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Package imports
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

// 4. Relative imports
import '../theme/app_colors.dart';
import '../../domain/entities/wallpaper.dart';

// 5. Export (if needed)
export 'models/wallpaper_model.dart';
```

### Rules
- **Group by type**: dart, flutter, packages, relative
- **Within groups**: Alphabetically sorted
- **Relative paths**: Use `../` for cross-module, `./` within module
- **Avoid circular imports**: Strictly maintain layer separation

## Comment Guidelines

### AVOID Comments (Prefer Clear Code)
```dart
// ❌ Obvious comments
class User {
  String name;  // The user's name
  int age;      // The age of the user
}

// ✅ Self-documenting
class UserProfile {
  final String displayName;
  final int ageInYears;
}
```

### When to Comment

1. **Non-obvious WHY** (not WHAT)
```dart
// ✅ Explains architectural decision
// Hive adapter must be registered after Flutter init
// due to platform channel communication requirements
await Hive.initFlutter();
Hive.registerAdapter(WallpaperAdapter());

// ❌ Obvious from code
// Increment counter
count++;
```

2. **Complex Algorithm**
```dart
// ✅ Algorithm explanation
// Floyd-Warshall: compute transitive closure
// This finds all shortest paths between wallpaper categories
for (int k = 0; k < n; k++) {
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j]);
    }
  }
}
```

3. **Workarounds/Hacks**
```dart
// ✅ Explains non-obvious workaround
// Delay required because ImageCache loads asynchronously
// on first access. Direct access returns null.
await Future.delayed(Duration(milliseconds: 100));
final image = imageCache.singleton.get(ImageFileConfiguration(...));
```

4. **TODO/FIXME**
```dart
// ✅ Clear improvement path
// TODO: Migrate to go_router when available
// FIXME: Memory leak if widget disposed during download
```

### No Comments For
- Variable definitions (use clear names)
- Method purpose (use clear method names)
- Loop iterations (extract to method if complex)
- Obvious null checks

## Error Handling

### Try-Catch
```dart
// ✅ Specific errors
try {
  final wallpapers = await wallpaperRepository.fetch();
  state = wallpapers;
} on SocketException catch (e) {
  state = AsyncError(NetworkException('No internet'), st);
} on FormatException catch (e) {
  state = AsyncError(ParseException('Invalid response'), st);
} catch (e, st) {
  state = AsyncError(UnknownException('Failed to fetch'), st);
}

// ❌ Catch-all
try {
  fetchWallpapers();
} catch (e) {
  print('Error occurred');  // Too vague
}
```

### Riverpod Error Handling
```dart
// ✅ Handle async errors
ref.watch(wallpaperProvider).when(
  data: (wallpapers) => WallpaperGrid(items: wallpapers),
  loading: () => const LoadingIndicator(),
  error: (error, st) => ErrorWidget(message: error.toString()),
);

// ✅ Provider error callback
ref.listen(wallpaperProvider, (previous, next) {
  next.whenData((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallpapers loaded')),
    );
  }).onError((error, st) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  });
});
```

### Custom Exceptions
```dart
// ✅ Domain layer exceptions
abstract class CustomException implements Exception {
  final String message;
  CustomException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException extends CustomException {
  NetworkException(String message) : super('Network: $message');
}

class ParseException extends CustomException {
  ParseException(String message) : super('Parse: $message');
}
```

## Formatting & Style

### Dart Format
```bash
# Format entire project
dart format lib/

# Check format
dart format --set-exit-if-changed lib/
```

### Line Length
- **Max 100 characters** (Effective Dart recommendation)
- **Exceptions**: Long strings, URLs, comments

### Indentation
- **2 spaces** (Flutter standard)
- **Never tabs**

### Blank Lines
```dart
// ✅ Between sections
class UserRepository {
  // Public methods
  
  Future<User> fetchUser(String id) async {
    return _apiClient.get('/users/$id');
  }

  // Private helpers
  
  String _buildUrl(String endpoint) => '$_baseUrl/$endpoint';
}
```

## Code Organization Within Files

### File Structure
```dart
// 1. Imports
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// 2. Constants (if file-scoped)
const Duration _kAnimationDuration = Duration(milliseconds: 300);

// 3. Main class
class MyWidget extends StatelessWidget {
  // Public properties
  // Private properties
  
  // Constructor
  const MyWidget({required this.title});
  
  // Build method
  @override
  Widget build(BuildContext context) { ... }
  
  // Private methods
}

// 4. Supporting classes (if needed)
class _MyWidgetState extends State<MyWidget> { ... }
```

### Within Class
1. Public/final properties
2. Private properties
3. Constructor
4. Lifecycle methods (initState, dispose)
5. Build/main method
6. Public methods
7. Private methods

## Null Safety

### Nullable vs Non-nullable
```dart
// ✅ Clear intent
String email;           // Required
String? nickname;       // Optional

List<Wallpaper> items;  // Non-nullable list
List<Wallpaper>? items; // Nullable list (rare)

// ❌ Unclear
var name;               // Type inference doesn't make intent clear
String? email = '';     // Contradicts null safety
```

### Null Checks
```dart
// ✅ Null coalescing
final name = user.nickname ?? 'Anonymous';

// ✅ Null-aware operators
final upperName = user.name?.toUpperCase();

// ✅ Late initialization
late final database = Hive.box<Wallpaper>('wallpapers');

// ❌ Redundant null checks
if (value != null) {
  value = value;  // Does nothing
}
```

## Testing & Documentation

### Docstring Format
```dart
/// Brief description of what this does.
///
/// Extended description if needed. Explain the [parameter] names
/// and what the method returns.
///
/// Example:
/// ```dart
/// final wallpapers = await repository.fetch(resolution: '1920x1080');
/// ```
///
/// See also:
/// * [RelatedClass] for similar functionality
/// * [anotherMethod] for alternatives
void fetchWallpapers({required String resolution}) async { ... }
```

### When to Add Docstrings
- **Public methods**: Always
- **Public classes**: Always
- **Public properties**: Always
- **Private methods**: Only if complex
- **Parameters**: If non-obvious

---

## Quick Checklist

Before committing:
- [ ] File names are snake_case
- [ ] Classes are PascalCase
- [ ] Variables/methods are camelCase
- [ ] No hardcoded colors (use AppColors)
- [ ] No hardcoded spacing (use AppSpacing)
- [ ] All imports organized and sorted
- [ ] No unused imports
- [ ] Errors handled specifically
- [ ] Code formatted (`dart format`)
- [ ] No TODO/FIXME left behind
- [ ] Tests pass
- [ ] Follows layer architecture

---

**Standard**: Effective Dart  
**Format**: dart format (2-space indent)  
**Null Safety**: Strict  
**Line Length**: 100 characters  
**Last Updated**: 2026-06-09
