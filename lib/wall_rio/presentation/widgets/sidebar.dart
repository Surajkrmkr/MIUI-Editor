import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers/cms_provider.dart';
import '../../application/providers/settings_provider.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentFilePathProvider);
    final savedPathsState = ref.watch(savedPathsProvider);
    
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wallpaper, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'WallRio CMS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: GoRouterState.of(context).uri.path == '/',
            onTap: () => context.go('/'),
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PROJECTS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ),
          savedPathsState.when(
            data: (paths) {
              return Column(
                children: List.generate(3, (index) {
                  final p = index < paths.length ? paths[index] : null;
                  if (p == null) {
                    return ListTile(
                      leading: const Icon(Icons.add, size: 20, color: Colors.white24),
                      title: Text('Slot ${index + 1} (Empty)', style: const TextStyle(color: Colors.white24, fontSize: 13)),
                      onTap: () => context.go('/settings'),
                    );
                  }
                  final isActive = currentPath == p.path;
                  return ListTile(
                    leading: Icon(
                      isActive ? Icons.insert_drive_file : Icons.insert_drive_file_outlined,
                      size: 20,
                      color: isActive ? Colors.deepPurpleAccent : Colors.white54,
                    ),
                    title: Text(
                      p.label,
                      style: TextStyle(
                        color: isActive ? Colors.deepPurpleAccent : Colors.white,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    selected: isActive,
                    onTap: () {
                      ref.read(currentFilePathProvider.notifier).set(p.path);
                      ref.read(cmsProvider.notifier).loadFile(p.path);
                      Navigator.pop(context); // Close drawer
                      context.go('/'); // Go to dashboard if not there
                    },
                  );
                }),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const ListTile(title: Text('Error loading projects')),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Local Versions'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.commit),
            title: const Text('Git Control'),
            selected: GoRouterState.of(context).uri.path == '/git',
            onTap: () => context.go('/git'),
          ),
          const Spacer(),
          if (currentPath != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active File:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    currentPath.split('\\').last.split('/').last,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            selected: GoRouterState.of(context).uri.path == '/settings',
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}
