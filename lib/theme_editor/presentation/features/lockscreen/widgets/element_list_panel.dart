import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';

class ElementListPanel extends ConsumerWidget {
  const ElementListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(elementProvider);
    final notifier = ref.read(elementProvider.notifier);

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Widget Lists', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: kElementGroups.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ExpansionTile(
                    title: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white24, width: 1.5),
                        borderRadius: BorderRadius.circular(20)),
                    collapsedShape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white24, width: 1.5),
                        borderRadius: BorderRadius.circular(20)),
                    children: entry.value.map((type) {
                      final added = state.contains(type);
                      return ListTile(
                        selected: added,
                        title: Text(type.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          if (!added) {
                            notifier.add(LockElement(
                              type: type,
                              colorSecondary: type == ElementType.notification
                                  ? Colors.white24 : Colors.white,
                            ));
                          } else {
                            notifier.remove(type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
