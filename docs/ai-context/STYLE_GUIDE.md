# Style Guide: Design System & Theme

## Overview

Team Shadow Tools uses an **AMOLED Purple** design system with Material 3 compatibility. The theme provides light and dark modes with consistent color tokens, typography, spacing, and visual hierarchy.

### Core Design Principle
**All colors must come from design tokens. No hardcoded hex values or Colors.* in widgets.**

## Color System

### Dark Mode (AMOLED Purple)

#### Background Layers
| Token | Hex | Usage |
|-------|-----|-------|
| `darkBg0` | `#000000` | True AMOLED black - base background |
| `darkBg1` | `#0D0B15` | Near-black with violet hint - input backgrounds |
| `darkBg2` | `#110E1A` | Subtle violet lift - subtle backgrounds |

#### Surface Layers (Elevation)
| Token | Hex | Usage |
|-------|-----|-------|
| `darkSurface0` | `#16111F` | Base surface - cards, panels |
| `darkSurface1` | `#1F1A2D` | Elevated surface - floating containers |
| `darkSurface2` | `#29253C` | Overlay surface - modals, dialogs |

#### Borders
| Token | Hex | Usage |
|-------|-----|-------|
| `darkBorder0` | `#352F4A` | Purple-toned borders - primary borders |
| `darkBorder1` | `#433D5A` | Elevated borders - secondary borders |

#### Text
| Token | Hex | Usage |
|-------|-----|-------|
| `darkTextPrimary` | `#FFFFFF` | Primary text - headings, body text |
| `darkTextSecondary` | `#A1A1AA` | Secondary text - captions, hints |
| `darkTextDisabled` | `#71717A` | Disabled text - inactive states |

### Light Mode (Violet & White)

#### Background Layers
| Token | Hex | Usage |
|-------|-----|-------|
| `lightBg0` | `#FFFFFF` | Pure white - base background |
| `lightBg1` | `#FAFAFA` | Off-white - subtle backgrounds |

#### Surface Layers
| Token | Hex | Usage |
|-------|-----|-------|
| `lightSurface0` | `#F4F4F5` | Base surface - cards |
| `lightSurface1` | `#E4E4E7` | Elevated surface - containers |

#### Borders
| Token | Hex | Usage |
|-------|-----|-------|
| `lightBorder` | `#D4D4D8` | Light borders |

#### Text
| Token | Hex | Usage |
|-------|-----|-------|
| `lightTextPrimary` | `#18181B` | Primary text - headings |
| `lightTextSecondary` | `#52525B` | Secondary text - captions |

### Purple Accent Palette (Shared)

| Token | Hex | Usage |
|-------|-----|-------|
| `purplePrimary` | `#9B5CFF` | Primary action - buttons, active states |
| `purpleHover` | `#B388FF` | Hover state - interactive hover |
| `purplePressed` | `#7C3AED` | Pressed state - active selection |
| `purpleSelection` | `#C084FC` | Selection highlight - selection states |
| `purpleDark` | `#6D28D9` | Dark purple - alternative accent |

### Light Mode Purple (Deeper for Contrast)

| Token | Hex | Usage |
|-------|-----|-------|
| `purplePrimaryLight` | `#7C3AED` | Primary on light - buttons |
| `purpleHoverLight` | `#8B5CF6` | Hover on light |
| `purpleSelectionLight` | `#A78BFA` | Selection on light |

### Semantic Colors

#### Success
- **Dark**: `#22C55E` (Green - success state)
- **Light**: `#16A34A` (Darker green)

#### Warning
- **Dark**: `#F59E0B` (Amber - warning state)
- **Light**: `#D97706` (Darker amber)

#### Error
- **Dark**: `#EF4444` (Red - error state)
- **Light**: `#DC2626` (Darker red)

### Alpha Helper Functions

```dart
// Create alpha variants of colors
AppColors.whiteAlpha(int alpha)      // White with alpha
AppColors.blackAlpha(int alpha)      // Black with alpha
AppColors.purpleAlpha(int alpha)     // Purple primary with alpha
```

## Accessing Colors in Widgets

### ✅ Correct Way
```dart
// In widgets, use context extension
final colors = context.appColors;
Container(
  color: colors.bg,
  child: Text('Hello', style: TextStyle(color: colors.textPrimary)),
);

// Or direct access from AppColors
Container(
  color: AppColors.darkSurface0,
  child: Text('Hello', style: TextStyle(color: AppColors.darkTextPrimary)),
);

// With alpha
Container(
  color: AppColors.purpleAlpha(100),
);
```

### ❌ Incorrect (Forbidden)
```dart
// NEVER hardcode colors
Container(
  color: Color(0xFF16111F),  // ❌ NOT ALLOWED
  child: Text('Hello', style: TextStyle(color: Colors.white)),  // ❌ NOT ALLOWED
);

// NEVER use Colors.*
FloatingActionButton(
  backgroundColor: Colors.blue,  // ❌ NOT ALLOWED
);
```

## Typography System

### Font Family
**Primary**: Plus Jakarta Sans (Google Fonts)

### Text Styles

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayLarge` | 57 | bold | Hero headlines |
| `displayMedium` | 45 | bold | Large headlines |
| `displaySmall` | 36 | bold | Prominent headlines |
| `headlineLarge` | 32 | 600 | Section headers |
| `headlineMedium` | 28 | 600 | Subsection headers |
| `headlineSmall` | 24 | 600 | Card headers |
| `titleLarge` | 22 | 600 | Dialog titles |
| `titleMedium` | 16 | 500 | List item titles |
| `titleSmall` | 14 | 500 | Small titles |
| `bodyLarge` | 16 | 400 | Body text |
| `bodyMedium` | 14 | 400 | Standard body |
| `bodySmall` | 12 | 400 | Secondary text |
| `labelLarge` | 14 | 500 | Button labels |
| `labelMedium` | 12 | 500 | Captions |
| `labelSmall` | 11 | 500 | Fine print |

### Using Text Styles
```dart
// ✅ Use theme text styles
Text(
  'Welcome',
  style: Theme.of(context).textTheme.headlineLarge,
);

// ✅ Copy and modify
Text(
  'Updated',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: context.appColors.textSecondary,
    fontWeight: FontWeight.w600,
  ),
);
```

## Spacing System

Spacing follows an 8px base unit system.

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Minimal spacing |
| `sm` | 8px | Small gaps |
| `md` | 12px | Standard spacing |
| `lg` | 16px | Default padding |
| `xl` | 24px | Large spacing |
| `xxl` | 32px | Extra large spacing |

### Usage Example
```dart
// File: app_spacing.dart (core/theme)
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

// In widgets
Padding(
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Text('Padded text'),
);

Row(
  spacing: AppSpacing.md,
  children: [...],
);
```

## Border Radius System

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Minimal rounding |
| `sm` | 8px | Small buttons, inputs |
| `md` | 12px | Standard rounding |
| `lg` | 16px | Cards, containers |
| `xl` | 24px | Dialogs, large elements |
| `xxl` | 32px | Extra large rounding |

### Usage Example
```dart
// File: app_radius.dart
abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

// In widgets
Container(
  decoration: BoxDecoration(
    borderRadius: AppRadius.radiusMd,  // ✅ Correct
    color: context.appColors.surface,
  ),
);

// ❌ Never hardcode
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),  // ❌ Use AppRadius instead
  ),
);
```

## Elevation & Shadows

### Shadow Hierarchy

```dart
// Light shadow (small elements)
BoxShadow(
  color: Colors.black.withAlpha(50),
  blurRadius: 4,
  offset: const Offset(0, 2),
);

// Medium shadow (cards)
BoxShadow(
  color: Colors.black.withAlpha(80),
  blurRadius: 8,
  offset: const Offset(0, 4),
);

// Heavy shadow (modals, floating)
BoxShadow(
  color: Colors.black.withAlpha(120),
  blurRadius: 16,
  offset: const Offset(0, 8),
);
```

### Material Elevation
Use `elevation` property in Material components:
```dart
FloatingActionButton(
  elevation: 6,
  child: Icon(Icons.add),
);

Card(
  elevation: 2,
  child: ListTile(...),
);
```

## Responsive Design Guidelines

### Breakpoints
- **Mobile**: 0–600px
- **Tablet**: 600–1200px
- **Desktop**: 1200px+

### Responsive Widgets
```dart
// Use MediaQuery for responsive layouts
final width = MediaQuery.of(context).size.width;
final isMobile = width < 600;

// Or use LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return mobileLayout();
    }
    return desktopLayout();
  },
);
```

## Component Styling Rules

### Buttons
- **Size**: 44–48px height (touch target)
- **Padding**: `lg` (16px) horizontal
- **Border Radius**: `AppRadius.md` (12px)
- **Color**: `purplePrimary` (dark), `purplePrimaryLight` (light)

### Input Fields
- **Height**: 40–44px
- **Padding**: `md` (12px)
- **Border**: 1px solid `darkBorder0` (dark), `lightBorder` (light)
- **Border Radius**: `AppRadius.md`
- **Focus**: Highlight with `purplePrimary` on border

### Cards
- **Background**: `darkSurface0` (dark), `lightSurface0` (light)
- **Border**: 1px solid `darkBorder0` (dark), `lightBorder` (light)
- **Border Radius**: `AppRadius.lg` (16px)
- **Elevation**: 0 (use borders instead)

### Dialogs
- **Border Radius**: `AppRadius.xl` (24px)
- **Background**: `darkSurface0` (dark), `lightBg0` (light)
- **Width**: Max 600px (desktop)

## Dark Mode Strategy

Dark mode is **always enabled** for this app due to AMOLED optimization. The light mode is secondary.

### Theme Mode Selection
```dart
// Global theme mode
final themeMode = ref.watch(themeModeProvider);

// Toggle function
ref.read(themeModeProvider.notifier).toggle();
```

### Widget-Level Dark Mode Detection
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;

if (isDark) {
  // Dark mode specific UI
} else {
  // Light mode specific UI
}
```

## Color Usage Matrix

| Purpose | Dark Mode | Light Mode |
|---------|-----------|-----------|
| **Background** | `darkBg0` | `lightBg0` |
| **Primary Text** | `darkTextPrimary` | `lightTextPrimary` |
| **Secondary Text** | `darkTextSecondary` | `lightTextSecondary` |
| **Cards/Surfaces** | `darkSurface0` | `lightSurface0` |
| **Primary Action** | `purplePrimary` | `purplePrimaryLight` |
| **Hover Action** | `purpleHover` | `purpleHoverLight` |
| **Borders** | `darkBorder0` | `lightBorder` |
| **Success** | `successDark` | `successLight` |
| **Warning** | `warningDark` | `warningLight` |
| **Error** | `errorDark` | `errorLight` |

## Theme Consistency Checklist

Before creating UI components, ensure:
- [ ] No hardcoded color values (use `AppColors.*`)
- [ ] All colors accessed via `context.appColors` or `Theme.of(context)`
- [ ] Text styles use `Theme.of(context).textTheme.*`
- [ ] Spacing uses `AppSpacing.*` constants
- [ ] Border radius uses `AppRadius.*` constants
- [ ] Buttons use theme button styles
- [ ] Cards use theme card style
- [ ] Dialogs use theme dialog style
- [ ] Test in both light and dark mode

---

**Design System**: AMOLED Purple Material 3  
**Color Count**: 50+ tokens (no magic numbers)  
**Typography**: Plus Jakarta Sans (Google Fonts)  
**Responsive**: Mobile-first with desktop support
