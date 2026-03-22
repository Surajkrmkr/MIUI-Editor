import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/tag_provider.dart';

class TagsPanel extends ConsumerStatefulWidget {
  const TagsPanel({super.key, required this.themeName});
  final String? themeName;

  @override
  ConsumerState<TagsPanel> createState() => _TagsPanelState();
}

class _TagsPanelState extends ConsumerState<TagsPanel> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(tagProvider);
    final notifier = ref.read(tagProvider.notifier);

    if (!state.isLoaded) return const SizedBox(width: 220, child: Center(child: CircularProgressIndicator()));

    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Text('Tags', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          // Search field
          TextField(
            controller: _searchCtrl,
            onChanged: notifier.setSearch,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Search tags...',
              suffixIcon: IconButton(
                icon: Icon(state.searchQuery.isEmpty ? Icons.search : Icons.close),
                onPressed: () {
                  if (state.searchQuery.isNotEmpty) {
                    _searchCtrl.clear();
                    notifier.clearSearch();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tag list
          Expanded(
            child: state.searchResults.isNotEmpty
                ? _TagList(
                    items: state.searchResults,
                    isSelected: (t) => state.appliedTags.contains(t),
                    onTap: (t) => state.appliedTags.contains(t)
                        ? notifier.removeTag(t)
                        : notifier.addTag(t),
                  )
                : ListView(
                    children: state.data!.categories.map((cat) {
                      return ExpansionTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        children: cat.subTags.map((tag) => ListTile(
                          dense: true,
                          selected: state.appliedTags.contains(tag),
                          title: Text(tag),
                          onTap: () => state.appliedTags.contains(tag)
                              ? notifier.removeTag(tag)
                              : notifier.addTag(tag),
                        )).toList(),
                      );
                    }).toList(),
                  ),
          ),
          // Applied chips
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: state.appliedTags.map((tag) => ActionChip(
              backgroundColor: Theme.of(context).colorScheme.primary,
              label: Text(tag, style: const TextStyle(color: Colors.white)),
              avatar: const Icon(Icons.close, color: Colors.white, size: 14),
              onPressed: () => notifier.removeTag(tag),
            )).toList(),
          ),
          if (!state.canAddMore)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Max 6 tags',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _TagList extends StatelessWidget {
  const _TagList({required this.items, required this.isSelected, required this.onTap});
  final List<String> items;
  final bool Function(String) isSelected;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (_, i) => ListTile(
      dense: true,
      selected: isSelected(items[i]),
      title: Text(items[i]),
      onTap: () => onTap(items[i]),
    ),
  );
}
