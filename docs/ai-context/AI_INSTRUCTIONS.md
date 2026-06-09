# AI Assistant Instructions

**This document is written for AI assistants implementing features in Team Shadow Tools.**

## Before Implementing Anything

**MANDATORY READING ORDER** (in this order):

1. **README.md** — Project overview (2 min read)
2. **PROJECT_ARCHITECTURE.md** — Understand structure (5 min read)
3. **STYLE_GUIDE.md** — Learn design tokens (5 min read)
4. **MODULES.md** — Find existing modules (5 min read)
5. **COMMON_WIDGETS.md** — Check for reusable components (3 min read)
6. **CODING_STANDARDS.md** — Follow naming conventions (5 min read)
7. **DEVELOPMENT_RULES.md** — Understand strict rules (5 min read)
8. **FEATURE_TEMPLATE.md** — Use template for new features (2 min read)

**Total: ~32 minutes to understand the entire project.**

If you skip any of these, you will violate project standards and your changes will be rejected.

---

## Feature Implementation Checklist

### Phase 1: Analysis (Before Writing Code)

- [ ] **Read all docs** above (especially DEVELOPMENT_RULES.md)
- [ ] **Find similar features** in MODULES.md
- [ ] **Check COMMON_WIDGETS.md** for reusable components
- [ ] **Verify app type**:
  - [ ] GoRouter app? (Image Utility, WallRio)
  - [ ] Navigator app? (Others)
- [ ] **Identify layer needs**:
  - [ ] Is this presentation-only? (New screen)
  - [ ] Needs API? (Requires data layer + repository)
  - [ ] Needs state? (Requires provider)
- [ ] **Plan file structure** using FEATURE_TEMPLATE.md

### Phase 2: Implementation

- [ ] **Follow FEATURE_TEMPLATE.md** exactly
- [ ] **Respect layer boundaries** (no presentation → data imports)
- [ ] **Use only Riverpod** for state (no StatefulWidget, BLoC, etc.)
- [ ] **All colors from AppColors** (never hardcode hex)
- [ ] **All spacing from AppSpacing**
- [ ] **All radius from AppRadius**
- [ ] **Text styles from Theme.of(context).textTheme**
- [ ] **Use descriptive naming** (CODING_STANDARDS.md)
- [ ] **Organize imports** properly
- [ ] **Add docstrings** for public APIs
- [ ] **Handle errors explicitly** (no silent failures)

### Phase 3: Quality Checks

- [ ] **No cross-app imports** (except core/widgets)
- [ ] **No hardcoded values** (colors, spacing, sizes)
- [ ] **No widget duplication** (used existing widgets)
- [ ] **Tested in both light and dark mode**
- [ ] **No commented-out code** (delete or use TODOs)
- [ ] **No unused imports**
- [ ] **Follows DEVELOPMENT_RULES.md** (all 18 rules)
- [ ] **Code is formatted** (`dart format`)

### Phase 4: Documentation

- [ ] **Updated MODULES.md** if adding new module
- [ ] **Updated COMMON_WIDGETS.md** if creating reusable widget
- [ ] **Added docstrings** to all public methods
- [ ] **Documented complex logic** (WHY comments)
- [ ] **No TODO/FIXME** left in code (or added to issue)

---

## Key Rules (Cannot Break These)

### 1. No Hardcoded Colors
```dart
// ❌ FORBIDDEN
Container(color: Color(0xFF16111F))
Text(style: TextStyle(color: Colors.white))

// ✅ CORRECT
Container(color: AppColors.darkSurface0)
Text(style: TextStyle(color: context.appColors.textPrimary))
```

### 2. Riverpod Only
```dart
// ❌ FORBIDDEN
class MyWidget extends StatefulWidget { ... }
class MyBloc extends Bloc { ... }

// ✅ CORRECT
final myProvider = StateNotifierProvider<MyNotifier, MyState>(...);
class MyWidget extends ConsumerWidget { ... }
```

### 3. Follow Architecture Layers
```dart
// ❌ FORBIDDEN: Presentation → Data
class MyPage extends ConsumerWidget {
  final repo = WallpaperRepository(...);  // Data access in UI
}

// ✅ CORRECT: Presentation → Providers → Repository → API
final wallpaperProvider = FutureProvider((ref) async {
  final repo = ref.watch(wallpaperRepositoryProvider);
  return repo.fetch();
});
```

### 4. No Cross-App Imports
```dart
// ❌ FORBIDDEN
import 'package:miui_icon_generator/image_utility/features/...';

// ✅ ALLOWED
import 'package:miui_icon_generator/core/theme/app_colors.dart';
```

### 5. Use Design Tokens
```dart
// ❌ FORBIDDEN: Magic numbers
Padding(padding: const EdgeInsets.all(16))
BorderRadius.circular(12)

// ✅ CORRECT
Padding(padding: const EdgeInsets.all(AppSpacing.lg))
BorderRadius.circular(AppRadius.radiusMd)
```

---

## Implementation Patterns

### New Screen (Presentation-Only)

Use template from FEATURE_TEMPLATE.md:

```dart
// 1. Create page
lib/[app]/presentation/pages/my_new_page.dart
  → Extends ConsumerWidget
  → Uses ref.watch(providers)
  → No business logic

// 2. Create provider (if needed)
lib/[app]/presentation/providers/my_providers.dart
  → StateNotifierProvider for UI state
  → No domain logic

// 3. Register route (if router app)
lib/[app]/core/router/app_router.dart
  → Add GoRoute
```

### New Feature (Full Stack)

Use template from FEATURE_TEMPLATE.md:

```dart
// 1. Create entity
lib/[app]/features/[feature]/domain/entities/entity.dart

// 2. Create repository interface
lib/[app]/features/[feature]/domain/repositories/repository.dart

// 3. Create data layer
lib/[app]/features/[feature]/data/
  ├── datasources/
  ├── models/
  └── repositories/

// 4. Create providers
lib/[app]/features/[feature]/presentation/providers/feature_providers.dart

// 5. Create pages/widgets
lib/[app]/features/[feature]/presentation/
  ├── pages/
  └── widgets/

// 6. Register in app (if new app)
lib/main.dart → Add to _apps list
```

### New Reusable Widget

```dart
// 1. Create in lib/widgets/
lib/widgets/my_component.dart

// 2. Use theme tokens
  → context.appColors for colors
  → AppSpacing for padding
  → AppRadius for borders
  → Theme.of(context).textTheme for text

// 3. Add docstring with usage example

// 4. Update COMMON_WIDGETS.md

// 5. Make it optional
  → All properties should have sensible defaults
  → Extensive customization via parameters
```

---

## Common Implementation Mistakes (Avoid These)

### ❌ Mistake 1: StatefulWidget Instead of Riverpod
```dart
// WRONG
class MyWidget extends StatefulWidget { ... }

// CORRECT
final myStateProvider = StateNotifierProvider<MyNotifier, MyState>(...);
class MyWidget extends ConsumerWidget { ... }
```

### ❌ Mistake 2: Hardcoded Colors
```dart
// WRONG
Container(color: Color(0xFF9B5CFF))

// CORRECT
Container(color: AppColors.purplePrimary)
```

### ❌ Mistake 3: Presentation Accessing Data
```dart
// WRONG
class MyPage extends ConsumerWidget {
  final repo = WallpaperRepository();
  final data = await repo.fetch();
}

// CORRECT
final wallpaperProvider = FutureProvider((ref) async {
  return ref.watch(wallpaperRepositoryProvider).fetch();
});

class MyPage extends ConsumerWidget {
  final data = ref.watch(wallpaperProvider);
}
```

### ❌ Mistake 4: Duplicating Widgets
```dart
// WRONG - before checking COMMON_WIDGETS.md
class MyCustomButton extends StatelessWidget { ... }

// CORRECT - found AppIconButton already exists
AppIconButton(icon: Icons.add, onPressed: () {})
```

### ❌ Mistake 5: Mixing Navigation Patterns
```dart
// WRONG - GoRouter app using Navigator
Navigator.of(context).push(MaterialPageRoute(...))

// CORRECT - GoRouter app using GoRouter
context.go('/detail/$id');
```

### ❌ Mistake 6: Hardcoded Spacing
```dart
// WRONG
Padding(padding: const EdgeInsets.all(16))

// CORRECT
Padding(padding: const EdgeInsets.all(AppSpacing.lg))
```

### ❌ Mistake 7: Cross-App Imports
```dart
// WRONG
import 'package:miui_icon_generator/wall_rio/presentation/screens/home.dart';

// CORRECT - apps are independent
// Share only via core/theme or lib/widgets
```

### ❌ Mistake 8: Silent Error Handling
```dart
// WRONG
try {
  await fetchWallpapers();
} catch (e) {
  // Ignore
}

// CORRECT
try {
  final wallpapers = await repo.fetch();
} on NetworkException catch (e) {
  state = AsyncError(NetworkException(...));
} catch (e, st) {
  state = AsyncError(UnknownException(...));
}
```

### ❌ Mistake 9: Unused Imports
```dart
// WRONG
import 'package:something/unused.dart';

// CORRECT
// Only import what you use
```

### ❌ Mistake 10: Inconsistent Naming
```dart
// WRONG - Random naming
class getUserProfile { }  // Lowercase class
void getUser(data) { }    // Vague parameter
final x = 5;              // Cryptic variable

// CORRECT
class UserProfile { }     // PascalCase
void fetchUser(String id) { }  // Verb + object
final maxRetries = 5;     // Clear name
```

---

## Riverpod Patterns

### FutureProvider (For Async Data)
```dart
final wallpaperProvider = FutureProvider<List<Wallpaper>>((ref) async {
  final repo = ref.watch(wallpaperRepositoryProvider);
  return repo.fetchWallpapers();
});

// Use in UI
ref.watch(wallpaperProvider).when(
  data: (wallpapers) => WallpaperGrid(items: wallpapers),
  loading: () => const LoadingIndicator(),
  error: (error, st) => ErrorWidget(error: error),
);
```

### StateNotifierProvider (For Mutable State)
```dart
final selectedColorProvider = StateNotifierProvider<SelectedColorNotifier, Color>((ref) {
  return SelectedColorNotifier(AppColors.purplePrimary);
});

class SelectedColorNotifier extends StateNotifier<Color> {
  SelectedColorNotifier(super.state);
  
  void selectColor(Color color) => state = color;
}

// Use in UI
final color = ref.watch(selectedColorProvider);
ElevatedButton(
  onPressed: () => ref.read(selectedColorProvider.notifier).selectColor(newColor),
  child: Text('Change Color'),
);
```

### StreamProvider (For Real-Time Data)
```dart
final downloadProgressProvider = StreamProvider<double>((ref) async* {
  // Yield progress updates
  yield 0.0;
  await Future.delayed(Duration(milliseconds: 100));
  yield 0.5;
  await Future.delayed(Duration(milliseconds: 100));
  yield 1.0;
});

// Use in UI
ref.watch(downloadProgressProvider).when(
  data: (progress) => LinearProgressIndicator(value: progress),
  loading: () => const CircularProgressIndicator(),
  error: (error, st) => Text('Error: $error'),
);
```

---

## Testing Approach

### Before Marking Done:
- [ ] Tested UI in light mode
- [ ] Tested UI in dark mode
- [ ] Tested on desktop (Windows/macOS/Linux)
- [ ] Tested on mobile (Android/iOS if applicable)
- [ ] Tested error states (network error, invalid input)
- [ ] Tested loading states
- [ ] Tested with real data (not mocked)
- [ ] No console errors or warnings
- [ ] Performance is acceptable (no jank)

---

## Code Review Prep

Before submitting for review, verify:

1. **Architecture**: Layers properly separated
2. **Style**: All design tokens used
3. **Names**: Consistent naming conventions
4. **Imports**: Organized, no circular deps
5. **Format**: `dart format` applied
6. **Docs**: Public APIs documented
7. **Tests**: Manual testing passed
8. **Rules**: All 18 DEVELOPMENT_RULES followed

---

## Troubleshooting

### Problem: "I can't find where X widget is"
**Solution**: Check:
1. `lib/widgets/` for global reusable
2. App's `presentation/widgets/` for feature-specific
3. COMMON_WIDGETS.md for documentation

### Problem: "Which app should this go in?"
**Solution**: Check MODULES.md:
- Theme Editor: Theme-related features
- Image Utility: Image processing, wallpapers
- WallRio CMS: Wallpaper management
- Theme Deployment: Upload/deploy features
- SVG Converter: SVG-related
- BuffyWalls: Different CMS system
- AI Upscaler: Image enhancement

### Problem: "Should I use GoRouter or Navigator?"
**Solution**: Check app type in MODULES.md:
- Image Utility → GoRouter
- WallRio CMS → GoRouter
- All others → Navigator

### Problem: "How do I share data between apps?"
**Solution**: You generally shouldn't. Apps are independent. If needed, discuss architecture.

### Problem: "Can I use GetX / BLoC / ChangeNotifier?"
**Solution**: No. Use Riverpod exclusively. No exceptions.

---

## When Stuck

1. **Check similar existing feature** in MODULES.md
2. **Read FEATURE_TEMPLATE.md** for structure
3. **Grep for examples** in codebase
4. **Review DEVELOPMENT_RULES.md** for violations
5. **Check STYLE_GUIDE.md** for design questions

---

## Final Checklist Before Committing

```
Architecture:
  ☐ Layer separation maintained
  ☐ No presentation → data imports
  ☐ Repositories used for data access
  ☐ Providers handle all state

Style:
  ☐ No hardcoded colors
  ☐ No hardcoded spacing
  ☐ No hardcoded radius
  ☐ Theme text styles used
  ☐ context.appColors used

Naming:
  ☐ Files are snake_case
  ☐ Classes are PascalCase
  ☐ Methods/variables are camelCase
  ☐ Providers end with "Provider"

Code Quality:
  ☐ No unused imports
  ☐ No console.logs or debug code
  ☐ Errors handled explicitly
  ☐ Code formatted (dart format)
  ☐ Docstrings added

Tests:
  ☐ Light mode tested
  ☐ Dark mode tested
  ☐ Error states tested
  ☐ Loading states tested

Rules:
  ☐ All 18 DEVELOPMENT_RULES followed
  ☐ No cross-app imports
  ☐ Riverpod used exclusively
  ☐ No duplicated widgets
```

---

**Remember**: Quality over speed. It's better to build once correctly than to rebuild multiple times due to violations.

**Questions?** Reference the documentation files in order:
1. DEVELOPMENT_RULES.md — What you can/cannot do
2. CODING_STANDARDS.md — How to name and structure
3. STYLE_GUIDE.md — How to style UI
4. PROJECT_ARCHITECTURE.md — How the app is structured

---

**For AI Assistants**: This file is your north star. Follow it and you'll implement features that fit perfectly into Team Shadow Tools.

**Last Updated**: 2026-06-09
