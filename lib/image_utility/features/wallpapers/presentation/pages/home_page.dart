import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/pages/settings_page_updated.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/widgets/wallpaper_card.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/widgets/source_selector.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/widgets/shimmer_widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Load more when scrolled to 90%
      ref.read(wallpaperNotifierProvider.notifier).loadMore();
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      ref.read(wallpaperNotifierProvider.notifier).loadCurated();
    } else {
      ref.read(wallpaperNotifierProvider.notifier).searchWallpapers(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallpaperState = ref.watch(wallpaperNotifierProvider);
    final selectedSource = ref.watch(selectedSourceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miui Tools'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Launcher',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark),
            tooltip: 'Bulk Download',
            onPressed: () => context.push('/bulk-download'),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate Wallpaper',
            onPressed: () => context.push('/generate'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showImageUtilitySettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search wallpapers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: _performSearch,
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Source Selector
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SourceSelector(),
          ),

          const SizedBox(height: 16),

          // Wallpaper Grid
          Expanded(
            child: wallpaperState.when(
              data: (wallpapers) {
                if (wallpapers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedSource == null
                              ? 'Please configure API keys in Settings'
                              : 'No wallpapers found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        (constraints.maxWidth / 280).clamp(2, 6).round();
                    return MasonryGridView.count(
                      controller: _scrollController,
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      padding: const EdgeInsets.all(16),
                      itemCount: wallpapers.length,
                      itemBuilder: (context, index) {
                        return WallpaperCard(wallpaper: wallpapers[index]);
                      },
                    );
                  },
                );
              },
              loading: () => const WallpaperGridShimmer(
                  itemCount: 9), // Changed to shimmer
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${error.toString()}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(wallpaperNotifierProvider.notifier)
                            .loadCurated();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(wallpaperNotifierProvider.notifier).loadCurated();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
