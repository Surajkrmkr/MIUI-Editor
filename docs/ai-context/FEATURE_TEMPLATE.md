# Feature Template: Implementation Blueprint

Use this template when implementing a new feature. Follow the structure exactly.

## Template Overview

This template covers:
1. **Feature-specific structure** for new features
2. **File templates** for each layer
3. **Provider setup** patterns
4. **Route registration** patterns
5. **Integration checklist**

---

## Directory Structure Template

### For Simple Features (Presentation Only)

```
lib/[app]/features/[feature]/
├── presentation/
│   ├── pages/
│   │   └── [feature]_page.dart
│   ├── widgets/
│   │   └── [feature]_card.dart  (optional, if reusable)
│   └── providers/
│       └── [feature]_providers.dart
└── resources/
    └── assets/  (if needed)
```

### For Complex Features (Full Stack)

```
lib/[app]/features/[feature]/
├── data/
│   ├── datasources/
│   │   └── [feature]_datasource.dart
│   ├── models/
│   │   ├── [entity]_model.dart
│   │   └── [entity]_response.dart
│   ├── providers/
│   │   └── [api_name]_provider.dart
│   └── repositories/
│       └── [feature]_repository.dart
├── domain/
│   ├── entities/
│   │   └── [entity].dart
│   └── repositories/
│       └── [feature]_repository.dart  (interface)
├── presentation/
│   ├── pages/
│   │   ├── [feature]_list_page.dart
│   │   ├── [feature]_detail_page.dart
│   │   └── [feature]_create_page.dart  (if needed)
│   ├── widgets/
│   │   ├── [feature]_card.dart
│   │   └── [feature]_form.dart
│   └── providers/
│       └── [feature]_providers.dart
└── resources/
    └── assets/  (if needed)
```

---

## File Templates

### Entity Template (domain/entities/entity.dart)

```dart
/// Represents a [Entity] in the domain layer.
class Entity {
  const Entity({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  // For equality checks
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### Model Template (data/models/entity_model.dart)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/entity.dart';

part 'entity_model.freezed.dart';
part 'entity_model.g.dart';

/// Data model for [Entity].
@freezed
class EntityModel with _$EntityModel {
  const factory EntityModel({
    required String id,
    required String name,
    String? description,
  }) = _EntityModel;

  const EntityModel._();

  factory EntityModel.fromJson(Map<String, dynamic> json) =>
      _$EntityModelFromJson(json);

  /// Convert model to domain entity
  Entity toEntity() => Entity(
    id: id,
    name: name,
    description: description,
  );
}
```

### Repository Interface Template (domain/repositories/repository.dart)

```dart
import '../entities/entity.dart';

/// Interface for [Entity] repository.
/// 
/// Implementations handle data fetching, caching, and API calls.
abstract class IEntityRepository {
  /// Fetch all entities.
  Future<List<Entity>> fetchAll();

  /// Fetch single entity by ID.
  Future<Entity> fetchById(String id);

  /// Create new entity.
  Future<Entity> create(Entity entity);

  /// Update existing entity.
  Future<Entity> update(Entity entity);

  /// Delete entity by ID.
  Future<void> delete(String id);
}
```

### Repository Implementation Template (data/repositories/repository.dart)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entity.dart';
import '../../domain/repositories/entity_repository.dart';
import '../datasources/entity_datasource.dart';
import '../models/entity_model.dart';

/// Implementation of [IEntityRepository].
/// 
/// Handles data layer operations: API calls, caching, transformations.
class EntityRepository implements IEntityRepository {
  EntityRepository(this._datasource);

  final EntityDatasource _datasource;

  @override
  Future<List<Entity>> fetchAll() async {
    final models = await _datasource.fetchAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Entity> fetchById(String id) async {
    final model = await _datasource.fetchById(id);
    return model.toEntity();
  }

  @override
  Future<Entity> create(Entity entity) async {
    final model = EntityModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
    );
    final response = await _datasource.create(model);
    return response.toEntity();
  }

  @override
  Future<Entity> update(Entity entity) async {
    final model = EntityModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
    );
    final response = await _datasource.update(model);
    return response.toEntity();
  }

  @override
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }
}
```

### Datasource Template (data/datasources/entity_datasource.dart)

```dart
import 'package:dio/dio.dart';
import '../models/entity_model.dart';

/// Datasource for entity API calls.
/// 
/// Handles all HTTP communication.
class EntityDatasource {
  EntityDatasource(this._dio, {required this.baseUrl});

  final Dio _dio;
  final String baseUrl;

  Future<List<EntityModel>> fetchAll() async {
    try {
      final response = await _dio.get('$baseUrl/entities');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => EntityModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<EntityModel> fetchById(String id) async {
    try {
      final response = await _dio.get('$baseUrl/entities/$id');
      return EntityModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<EntityModel> create(EntityModel model) async {
    try {
      final response = await _dio.post(
        '$baseUrl/entities',
        data: model.toJson(),
      );
      return EntityModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<EntityModel> update(EntityModel model) async {
    try {
      final response = await _dio.put(
        '$baseUrl/entities/${model.id}',
        data: model.toJson(),
      );
      return EntityModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('$baseUrl/entities/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout) {
        return Exception('Connection timeout');
      }
      if (error.response?.statusCode == 404) {
        return Exception('Not found');
      }
      return Exception('API Error: ${error.message}');
    }
    return Exception('Unknown error: $error');
  }
}
```

### Provider Template (presentation/providers/entity_providers.dart)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/entity_datasource.dart';
import '../../data/repositories/entity_repository.dart';
import '../../domain/entities/entity.dart';
import '../../domain/repositories/entity_repository.dart' as domain;

/// Datasource provider.
final entityDatasourceProvider = Provider((ref) {
  // Inject dependencies
  // final dio = ref.watch(dioProvider);
  // return EntityDatasource(dio, baseUrl: 'https://api.example.com');
  throw UnimplementedError();
});

/// Repository provider.
final entityRepositoryProvider = Provider<domain.IEntityRepository>((ref) {
  final datasource = ref.watch(entityDatasourceProvider);
  return EntityRepository(datasource);
});

/// Fetch all entities.
final entityProvider = FutureProvider<List<Entity>>((ref) async {
  final repo = ref.watch(entityRepositoryProvider);
  return repo.fetchAll();
});

/// Fetch single entity by ID.
final entityByIdProvider = FutureProvider.family<Entity, String>((ref, id) async {
  final repo = ref.watch(entityRepositoryProvider);
  return repo.fetchById(id);
});

/// Create entity.
final createEntityProvider = FutureProvider.family<Entity, Entity>((ref, entity) async {
  final repo = ref.watch(entityRepositoryProvider);
  return repo.create(entity);
});

/// Delete entity.
final deleteEntityProvider = FutureProvider.family<void, String>((ref, id) async {
  final repo = ref.watch(entityRepositoryProvider);
  return repo.delete(id);
});
```

### Page Template (presentation/pages/entity_list_page.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/entity_providers.dart';
import '../widgets/entity_card.dart';

/// Page displaying list of entities.
class EntityListPage extends ConsumerWidget {
  const EntityListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final entities = ref.watch(entityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entities'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create page or show dialog
        },
        child: const Icon(Icons.add),
      ),
      body: entities.when(
        data: (entities) {
          if (entities.isEmpty) {
            return Center(
              child: Text(
                'No entities found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: entities.length,
            itemBuilder: (context, index) => EntityCard(
              entity: entities[index],
              onTap: () {
                // Navigate to detail page
              },
              onDelete: () {
                ref.read(deleteEntityProvider(entities[index].id));
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colors.error),
              const SizedBox(height: AppSpacing.md),
              Text(error.toString()),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.refresh(entityProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Widget Template (presentation/widgets/entity_card.dart)

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../domain/entities/entity.dart';

/// Card widget displaying an entity.
/// 
/// Shows entity information with optional actions.
class EntityCard extends StatelessWidget {
  const EntityCard({
    super.key,
    required this.entity,
    this.onTap,
    this.onDelete,
  });

  final Entity entity;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entity.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (entity.description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      entity.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
```

### Route Registration Template (core/router/app_router.dart)

**For GoRouter apps:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/entity/presentation/pages/entity_list_page.dart';
import '../../features/entity/presentation/pages/entity_detail_page.dart';

final routerProvider = Provider((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const EntityListPage(),
      ),
      GoRoute(
        path: '/entity/:id',
        name: 'entity-detail',
        builder: (context, state) => EntityDetailPage(
          id: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
```

**For Navigator apps:**

```dart
// No special registration needed
// Navigate using Navigator.of(context).push(
//   PageRouteBuilder(
//     pageBuilder: (_, __, ___) => const EntityDetailPage(),
//   ),
// );
```

---

## Integration Checklist

After creating all files:

- [ ] **data/** layer complete
  - [ ] Entity datasource created
  - [ ] Repository implementation created
  - [ ] Models with freezed annotations
  - [ ] Error handling in datasource

- [ ] **domain/** layer complete
  - [ ] Entity created
  - [ ] Repository interface created
  - [ ] No presentation imports

- [ ] **presentation/** layer complete
  - [ ] Providers created
  - [ ] Pages/widgets created
  - [ ] Uses `context.appColors` for colors
  - [ ] Uses `AppSpacing` for padding
  - [ ] Uses `AppRadius` for borders
  - [ ] Text styles from theme

- [ ] **Routing** complete
  - [ ] GoRouter: Added routes to app_router.dart
  - [ ] Navigator: Ready to use Navigator.push()

- [ ] **Naming** follows standards
  - [ ] Files are snake_case
  - [ ] Classes are PascalCase
  - [ ] Methods/variables are camelCase
  - [ ] Providers end with "Provider"

- [ ] **Documentation** complete
  - [ ] Public classes documented
  - [ ] Public methods documented
  - [ ] Updated MODULES.md
  - [ ] Updated COMMON_WIDGETS.md (if new widget)

- [ ] **Testing** done
  - [ ] Light mode tested
  - [ ] Dark mode tested
  - [ ] Error states tested
  - [ ] Loading states tested

- [ ] **Quality checks** passed
  - [ ] No hardcoded colors
  - [ ] No hardcoded spacing
  - [ ] No hardcoded radius
  - [ ] Code formatted
  - [ ] No unused imports
  - [ ] No circular dependencies

---

## Example: Adding "Download History" Feature

### 1. Create structure

```
lib/image_utility/features/download_history/
├── data/
│   ├── datasources/download_history_datasource.dart
│   ├── models/download_item_model.dart
│   └── repositories/download_history_repository.dart
├── domain/
│   ├── entities/download_item.dart
│   └── repositories/download_history_repository.dart
└── presentation/
    ├── pages/download_history_page.dart
    ├── widgets/download_item_card.dart
    └── providers/download_history_providers.dart
```

### 2. Create files using templates above

### 3. Register route

```dart
// In lib/image_utility/core/router/app_router.dart
GoRoute(
  path: '/download-history',
  name: 'download-history',
  builder: (context, state) => const DownloadHistoryPage(),
),
```

### 4. Update MODULES.md

```
### Download History Feature
Location: lib/image_utility/features/download_history/
Purpose: Track and view all downloaded wallpapers
Data Source: Local SharedPreferences
State Management: FutureProvider for list, StateNotifierProvider for filters
```

### 5. Ready to implement!

---

**Following this template ensures:**
- ✅ Consistent architecture
- ✅ Proper layer separation
- ✅ Scalable code
- ✅ No duplicated patterns
- ✅ Easy to maintain
- ✅ Easy for others to understand

---

**Remember**: Use this template exactly. Don't deviate or "optimize" the structure. Consistency is more important than personal preference.

**Last Updated**: 2026-06-09
