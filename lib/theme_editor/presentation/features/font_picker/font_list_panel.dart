import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/font_provider.dart';
import '../../../presentation/providers/element_provider.dart';

class FontListPanel extends ConsumerWidget {
  const FontListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontsAsync = ref.watch(fontListProvider);
    final elState    = ref.watch(elementProvider);

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Font Lists', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Expanded(
            child: fontsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e', style: const TextStyle(fontSize: 12))),
              data: (fonts) => ListView.builder(
                itemCount: fonts.length,
                itemBuilder: (_, i) {
                  final font = fonts[i];
                  final sel  = elState.active?.font == font.fontFamily;
                  return ListTile(
                    selected: sel,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(
                      font.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: font.name, fontSize: 22),
                    ),
                    onTap: () {
                      final type = ref.read(elementProvider).activeType;
                      ref.read(elementProvider.notifier).setFont(type, font.fontFamily);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
