# Documentation Index

Quick reference to all AI Context files.

## Essential Reading (For Everyone)

| File | Purpose | Read Time |
|------|---------|-----------|
| [README.md](README.md) | Project overview and documentation purpose | 2 min |
| [PROJECT_ARCHITECTURE.md](PROJECT_ARCHITECTURE.md) | System structure, apps, and data flow | 5 min |
| [STYLE_GUIDE.md](STYLE_GUIDE.md) | Design tokens, colors, typography, spacing | 5 min |

## For Implementation

| File | Purpose | Read Time |
|------|---------|-----------|
| [MODULES.md](MODULES.md) | All 7 apps and their features | 5 min |
| [COMMON_WIDGETS.md](COMMON_WIDGETS.md) | Reusable components catalog | 3 min |
| [CODING_STANDARDS.md](CODING_STANDARDS.md) | Naming conventions, formatting, patterns | 5 min |
| [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) | Strict rules that cannot be broken | 5 min |

## For AI Assistants

| File | Purpose | Read Time |
|------|---------|-----------|
| [AI_INSTRUCTIONS.md](AI_INSTRUCTIONS.md) | Complete guide for AI implementation | 10 min |
| [FEATURE_TEMPLATE.md](FEATURE_TEMPLATE.md) | Template for new features | 5 min |

---

## File Purposes at a Glance

### README.md
- Project overview
- Documentation purpose
- How to use these files
- Key principles

### PROJECT_ARCHITECTURE.md
- 7 sub-apps overview
- Core shared components
- State management setup
- Navigation patterns
- Data flow architecture
- Dependency injection
- Technology stack

### STYLE_GUIDE.md
- Color system (dark & light modes)
- How to access colors
- Typography system
- Spacing system
- Border radius system
- Responsive design
- Component styling rules
- Dark mode strategy
- Consistency checklist

### MODULES.md
- 7 apps description
- Core module
- Reusable widgets
- Module dependency map
- Adding new modules
- Module health check

### COMMON_WIDGETS.md
- 3 existing reusable widgets
- Widget naming conventions
- Component structure template
- Common patterns by app
- Reusable widget index
- Common patterns (dialogs, lists, grids, forms, animations)

### CODING_STANDARDS.md
- File & folder naming
- Class & type naming
- Variable & property naming
- Method & function naming
- Provider naming (Riverpod)
- Constant naming
- Import organization
- Comments guidelines
- Error handling
- Formatting & style
- Null safety
- Quick checklist

### DEVELOPMENT_RULES.md
- 18 strict rules (must follow)
- Color system rules
- Architecture rules
- State management rules
- Navigation rules
- Widget & component rules
- Module structure rules
- API & data rules
- Testing & quality rules
- Documentation rules
- Naming convention rules
- Security rules
- Violation checklist

### AI_INSTRUCTIONS.md
- Reading order (mandatory)
- Feature implementation checklist
- Key rules (5 critical rules)
- Implementation patterns
- Common mistakes to avoid
- Riverpod patterns
- Testing approach
- Code review prep
- Troubleshooting
- Final checklist

### FEATURE_TEMPLATE.md
- Directory structure template
- File templates (entity, model, repository, datasource, provider, page, widget, route)
- Integration checklist
- Example implementation

---

## Recommended Reading by Role

### For Backend Developers (Adding API Integration)
1. PROJECT_ARCHITECTURE.md (data flow)
2. FEATURE_TEMPLATE.md (datasource & repository)
3. DEVELOPMENT_RULES.md (rule 11 & 12)

### For Frontend Developers (Creating UI)
1. STYLE_GUIDE.md (design tokens)
2. COMMON_WIDGETS.md (existing components)
3. CODING_STANDARDS.md (naming)
4. FEATURE_TEMPLATE.md (page template)

### For New Feature Developers
1. PROJECT_ARCHITECTURE.md (overview)
2. MODULES.md (find similar feature)
3. FEATURE_TEMPLATE.md (use template)
4. AI_INSTRUCTIONS.md (implementation guide)

### For AI Assistants (MANDATORY)
1. AI_INSTRUCTIONS.md (complete flow)
2. All other files as needed

---

## Quick Lookup Table

| Question | Answer In | Section |
|----------|-----------|---------|
| What colors can I use? | STYLE_GUIDE.md | Color System |
| How do I create a new screen? | FEATURE_TEMPLATE.md | Page Template |
| What is the project structure? | PROJECT_ARCHITECTURE.md | Overview |
| Should I use GoRouter or Navigator? | MODULES.md | Module Name |
| Can I hardcode colors? | DEVELOPMENT_RULES.md | Rule 1 |
| How do I name files? | CODING_STANDARDS.md | File & Folder Naming |
| Where are reusable widgets? | COMMON_WIDGETS.md | Existing Reusable Widgets |
| Can I use BLoC? | DEVELOPMENT_RULES.md | Rule 4 |
| What spacing should I use? | STYLE_GUIDE.md | Spacing System |
| How do I handle errors? | DEVELOPMENT_RULES.md | Rule 13 |
| Where is the API integration? | FEATURE_TEMPLATE.md | Datasource Template |
| Can I import from other apps? | DEVELOPMENT_RULES.md | Rule 3 |

---

## Statistics

- **Total Documentation Files**: 9
- **Total Pages** (approx): 50+
- **Rules Defined**: 18 strict rules
- **Apps Documented**: 7 sub-apps
- **Core Modules**: 1 (theme system)
- **Reusable Widgets**: 3
- **Templates**: 8 file templates

---

## Last Updated

- **Date**: 2026-06-09
- **Version**: 1.0
- **Status**: Complete

---

## Contributing to Documentation

When updating these files:
1. Keep the information current
2. Update examples with real code from project
3. Follow the existing format
4. Link between related files
5. Update this INDEX.md

---

**Start here**: Read README.md first, then PROJECT_ARCHITECTURE.md.

**For implementation**: Go to FEATURE_TEMPLATE.md and follow the template.

**For AI assistants**: Read AI_INSTRUCTIONS.md completely before implementing anything.
