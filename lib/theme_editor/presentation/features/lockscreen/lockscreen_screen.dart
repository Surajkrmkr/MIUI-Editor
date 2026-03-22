import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/element_widget.dart';
import '../../providers/element_provider.dart';
import '../../providers/wallpaper_provider.dart';
import '../home/widgets/image_stack.dart';
import '../font_picker/font_list_panel.dart';
import 'widgets/element_info_panel.dart';
import 'widgets/element_list_panel.dart';
import 'widgets/lockscreen_functions_panel.dart';

class LockscreenScreen extends ConsumerWidget {
  const LockscreenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add swipe-unlock on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(elementProvider.notifier);
      if (!ref.read(elementProvider).contains(ElementType.swipeUpUnlock)) {
        n.add(const LockElement(type: ElementType.swipeUpUnlock));
        n.setActive(ElementType.swipeUpUnlock);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 220, child: Text('Lockscreen')),
            const SizedBox(width: 20),
            // Progress
            Consumer(builder: (_, ref, __) {
              final ws = ref.watch(wallpaperProvider);
              return Text(
                ws.paths.isEmpty ? '' : '${ws.index + 1}/${ws.paths.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }),
          ],
        ),
        actions: [
          // Palette strip
          Consumer(builder: (_, ref, __) {
            final colors = ref.watch(wallpaperProvider).colorPalette;
            return SizedBox(
              height: 40,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: colors.map((c) => GestureDetector(
                    onTap: () {
                      final elState = ref.read(elementProvider);
                      ref.read(elementProvider.notifier)
                        ..setColor(elState.activeType, c)
                        ..setColorSecondary(elState.activeType, c);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: c, borderRadius: BorderRadius.circular(6)),
                    ),
                  )).toList(),
                ),
              ),
            );
          }),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Phone + ruler
            ImageStack(isLockscreen: true),
            // Panels
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElementInfoPanel(),
                ElementListPanel(),
                LockscreenFunctionsPanel(),
                FontListPanel(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
