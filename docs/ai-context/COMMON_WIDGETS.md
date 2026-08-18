# Common Widgets & Reusable Components

All reusable widgets live in `lib/widgets/`. **Always check this directory before creating new widgets.**

## Existing Reusable Widgets

### 1. GlassCard
**Location**: `lib/widgets/glass_card.dart`  
**Purpose**: Frosted glass effect container (glassmorphism)  
**Usage**:
```dart
GlassCard(
  child: Text('Glass effect content'),
);
```
**When to Use**: Modern UI cards, overlay containers, semi-transparent backgrounds

### 2. AppIconButton
**Location**: `lib/widgets/app_icon_button.dart`  
**Purpose**: Consistent icon button with theme styling  
**Usage**:
```dart
AppIconButton(
  icon: Icons.close,
  onPressed: () {},
);
```
**When to Use**: Action buttons, close buttons, navigation buttons

### 3. IPhoneFrame
**Location**: `lib/widgets/iphone_frame.dart`  
**Purpose**: iPhone device frame mockup for previews  
**Usage**:
```dart
IPhoneFrame(
  child: PreviewScreen(),
);
```
**When to Use**: Theme editor previews, mockup displays

## Common Patterns by App

### Theme Editor Patterns
Check `lib/theme_editor/presentation/features/*/widgets/` for:
- Color picker components
- Theme preview panels
- Icon grid displays
- Lock screen simulators

### Image Utility Patterns
Check `lib/image_utility/features/wallpapers/presentation/widgets/` for:
- Wallpaper card
- Source selector
- Download progress indicator
- Image grid layout

### WallRio CMS Patterns
Check `lib/wall_rio/presentation/widgets/` for:
- Wallpaper manager components
- Analytics charts
- Git integration widgets

## Widget Naming Conventions

| Pattern | Example | Usage |
|---------|---------|-------|
| `[Feature]Card` | `WallpaperCard`, `ThemeCard` | Card-style component |
| `[Feature]List` | `WallpaperList`, `IconList` | Scrollable list |
| `[Feature]Dialog` | `ExportDialog`, `SettingsDialog` | Dialog overlay |
| `[Feature]Picker` | `ColorPicker`, `FontPicker` | Selection widget |
| `[Feature]Panel` | `ElementInfoPanel`, `InspectorPanel` | Info/detail panel |
| `[Action]Button` | `ExportButton`, `RefreshButton` | Action button |
| `[State]Indicator` | `LoadingIndicator`, `ProgressIndicator` | State display |

## Component Structure Template

When creating a new reusable widget, follow this structure:

```dart
// lib/widgets/my_component.dart
import 'package:flutter/material.dart';
import '../core/theme/theme_extensions.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';

/// MyComponent description
/// 
/// Usage:
/// ```dart
/// MyComponent(
///   title: 'Title',
///   onAction: () {},
/// )
/// ```
class MyComponent extends StatelessWidget {
  const MyComponent({
    super.key,
    required this.title,
    required this.onAction,
  });

  final String title;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: onAction,
            child: const Text('Action'),
          ),
        ],
      ),
    );
  }
}
```

## Module-Specific Widgets

### Theme Editor Widgets
- **Location**: `lib/theme_editor/presentation/features/[feature]/widgets/`
- **Examples**: FontListPanel, ElementInfoPanel, ProWorkspaceShell
- **Pattern**: Feature-scoped, not for reuse across apps

### Image Utility Widgets
- **Location**: `lib/image_utility/features/[feature]/presentation/widgets/`
- **Examples**: WallpaperCard, SourceSelector, DownloadButton
- **Pattern**: Can be reused within Image Utility

### WallRio CMS Widgets
- **Location**: `lib/wall_rio/presentation/widgets/`
- **Examples**: WallpaperGrid, AnalyticsChart, GitStatusBar
- **Pattern**: WallRio-specific, not shared

### BuffyWalls CMS Widgets
- **Location**: `lib/buffy_walls/presentation/widgets/`
- **Examples**: CategoryManager, WallpaperUploader, GitPushPanel
- **Pattern**: BuffyWalls-specific


## Dialog & BottomSheet Components

### Standard Dialog Pattern
```dart
// In any screen
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirm Action'),
    content: Text('Are you sure?'),
    shape: const RoundedRectangleBorder(
      borderRadius: AppRadius.radiusXl,
    ),
    backgroundColor: context.appColors.surface,
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { /* action */ Navigator.pop(context); }, child: const Text('Confirm')),
    ],
  ),
);
```

### Standard BottomSheet Pattern
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: context.appColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
  ),
  builder: (context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Options', style: Theme.of(context).textTheme.titleLarge),
        // Options here
      ],
    ),
  ),
);
```

## Loading & Error States

### Loading Indicator
Use Flutter's built-in:
```dart
const CircularProgressIndicator()  // Uses theme primary color
```

### Shimmer Loading
```dart
Shimmer.fromColors(
  baseColor: context.appColors.surface,
  highlightColor: context.appColors.surfaceElevated,
  child: Container(
    height: 100,
    color: context.appColors.surface,
  ),
)
```

### Error Display
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline, color: context.appColors.error),
      const SizedBox(height: AppSpacing.md),
      Text('Error loading data'),
      const SizedBox(height: AppSpacing.md),
      ElevatedButton(
        onPressed: () { /* retry */ },
        child: const Text('Retry'),
      ),
    ],
  ),
)
```

## List Item Patterns

### Standard ListTile
```dart
ListTile(
  leading: Icon(Icons.wallpaper),
  title: Text('Wallpaper'),
  subtitle: Text('1920x1080'),
  trailing: Icon(Icons.arrow_forward),
  onTap: () {},
)
```

### Custom Card List Item
```dart
GestureDetector(
  onTap: () {},
  child: Container(
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: AppRadius.radiusMd,
      border: Border.all(color: context.appColors.border),
    ),
    child: Row(
      children: [
        // Icon
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title', style: Theme.of(context).textTheme.titleSmall),
              Text('Subtitle', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Icon(Icons.arrow_forward),
      ],
    ),
  ),
)
```

## Grid Patterns

### Wallpaper Grid
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
    childAspectRatio: 9 / 16,
  ),
  itemBuilder: (context, index) => WallpaperCard(
    wallpaper: wallpapers[index],
    onTap: () {},
  ),
)
```

### Icon Grid
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 6,
    crossAxisSpacing: AppSpacing.sm,
    mainAxisSpacing: AppSpacing.sm,
    childAspectRatio: 1,
  ),
  itemBuilder: (context, index) => IconCard(icon: icons[index]),
)
```

## Form Components

### Input Field
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter value',
    border: OutlineInputBorder(
      borderRadius: AppRadius.radiusMd,
    ),
    contentPadding: const EdgeInsets.all(AppSpacing.md),
  ),
)
```

### Dropdown
```dart
DropdownMenu<String>(
  initialSelection: selected,
  onSelected: (value) {},
  dropdownMenuEntries: items.map((item) {
    return DropdownMenuEntry<String>(value: item, label: item);
  }).toList(),
)
```

### Checkbox
```dart
CheckboxListTile(
  title: const Text('Enable feature'),
  value: isEnabled,
  onChanged: (value) {},
)
```

### Switch
```dart
SwitchListTile(
  title: const Text('Dark mode'),
  value: isDark,
  onChanged: (value) {},
)
```

## Animation Patterns

### Fade Transition
```dart
FadeTransition(
  opacity: AnimationController(...),
  child: Child(),
)
```

### Scale Animation
```dart
ScaleTransition(
  scale: AnimationController(...),
  child: Child(),
)
```

### Slide Animation
```dart
SlideTransition(
  position: Tween<Offset>(
    begin: const Offset(-1, 0),
    end: Offset.zero,
  ).animate(AnimationController(...)),
  child: Child(),
)
```

## SnackBar Pattern

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Action completed'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {},
    ),
  ),
);
```

## Checklist: Before Creating a New Widget

- [ ] Searched `lib/widgets/` for existing component
- [ ] Checked app-specific widgets directory
- [ ] Component is genuinely reusable (used in 2+ places)
- [ ] Follows naming convention
- [ ] Uses `context.appColors` for colors
- [ ] Uses `AppRadius` for borders
- [ ] Uses `AppSpacing` for padding/margin
- [ ] Uses `Theme.of(context).textTheme` for text
- [ ] Documented with usage example
- [ ] Accepts parameters for customization
- [ ] Tested in both light and dark mode

---

**Reusable Widgets**: 3 in `lib/widgets/`  
**App-Specific Widgets**: 50+ across modules  
**Pattern**: Feature-scoped unless generic reuse case exists
