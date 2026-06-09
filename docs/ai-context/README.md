# AI Context Documentation

This directory contains comprehensive project knowledge files designed to guide AI-assisted development and ensure consistency across the Team Shadow Tools ecosystem.

## Purpose

These documents serve as a persistent knowledge base for:
- **Consistent Architecture**: Maintain the multi-app launcher architecture
- **Design System**: Enforce AMOLED Purple theme tokens and color system
- **Coding Standards**: Follow established naming conventions and patterns
- **Module Organization**: Keep features organized using clean architecture
- **Future Development**: Enable AI assistants to implement features without re-analyzing the codebase

## Which Files to Read Before Development

### Quick Start (Read First)
1. **README.md** (this file) — Overview
2. **PROJECT_ARCHITECTURE.md** — Understand the overall structure
3. **STYLE_GUIDE.md** — Learn the theme and design system

### For Feature Implementation
4. **MODULES.md** — See existing modules and their purposes
5. **COMMON_WIDGETS.md** — Reuse existing components
6. **CODING_STANDARDS.md** — Follow naming conventions

### For Advanced Development
7. **DEVELOPMENT_RULES.md** — Strict rules that must be followed
8. **AI_INSTRUCTIONS.md** — Explicit AI assistant guidelines
9. **FEATURE_TEMPLATE.md** — Template for new modules

## Key Principles

### Never Hardcode Colors
All colors **must** come from `AppColors` in `lib/core/theme/app_colors.dart`. No direct hex values or `Colors.*` constants in widgets.

### Reuse Everything
- Check `COMMON_WIDGETS.md` before creating new widgets
- Check `MODULES.md` before adding new features
- Extend existing services instead of creating duplicates

### Follow Architecture
- **Data Layer**: API calls, repositories, local storage
- **Domain Layer**: Entities, use cases, business logic
- **Presentation Layer**: UI screens, widgets, controllers
- Separate concerns strictly

### State Management
Use **Flutter Riverpod** exclusively:
- `final provider = StateNotifierProvider<T, S>(...)`
- `final provider = FutureProvider<T>(...)`
- Providers go in `presentation/providers/` directory

### Navigation
Use **GoRouter** with named routes:
- Define routes in feature-specific files
- Combine routes at app level
- Keep routes organized by feature

## File Organization

```
lib/
├── core/                           # Shared across all apps
│   └── theme/                      # Design system
├── [app_name]/                     # Each app is self-contained
│   ├── core/                       # App-specific services
│   ├── data/                       # API calls, repositories
│   ├── domain/                     # Entities, business logic
│   └── presentation/               # UI, screens, providers
└── widgets/                        # Reusable widgets
```

## Using This Documentation

### For Developers
Reference these files when:
- Creating new features
- Adding new widgets
- Modifying existing code
- Setting up dependencies

### For AI Assistants
Before implementing any feature:
1. Read `PROJECT_ARCHITECTURE.md` for structure
2. Read `STYLE_GUIDE.md` for design tokens
3. Read `MODULES.md` to understand existing features
4. Read `DEVELOPMENT_RULES.md` to avoid violations
5. Reference `FEATURE_TEMPLATE.md` for module structure

## Maintenance

These files should be updated when:
- New architectural patterns are introduced
- New design tokens are added
- New reusable widgets are created
- New modules/features are added
- Coding standards change

See `DEVELOPMENT_RULES.md` for the complete list of enforceable rules.

---

**Last Updated**: 2026-06-09  
**Team**: Shadow Tools Development
