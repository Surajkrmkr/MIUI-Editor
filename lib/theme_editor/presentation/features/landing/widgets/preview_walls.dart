import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/directory_provider.dart';

class PreviewWallsPanel extends ConsumerWidget {
  const PreviewWallsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dirState = ref.watch(directoryProvider);

    return SizedBox(
      height: 600,
      width: 350,
      child: Column(
        children: [
          Text('Previews', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: dirState.isLoadingWalls
                ? const Center(child: CircularProgressIndicator())
                : dirState.previewWallPaths.isEmpty
                    ? const Center(child: Text('No walls found'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.5,
                          ),
                          itemCount: dirState.previewWallPaths.length,
                          itemBuilder: (_, i) => _WallTile(
                              path: dirState.previewWallPaths[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _WallTile extends StatelessWidget {
  const _WallTile({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final name = path.split(Platform.pathSeparator).last;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: FileImage(File(path)),
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Text(name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
      ),
    );
  }
}
