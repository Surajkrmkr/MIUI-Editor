import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/tag.dart';

class Tags extends StatelessWidget {
  Tags({super.key});

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<TagProvider>(builder: (context, provider, _) {
      return SizedBox(
        width: 220,
        child: !provider.isLoading
            ? Column(
                children: [
                  if (Platform.isWindows)
                    Text(
                      "Tags",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  if (Platform.isWindows) const SizedBox(height: 20),
                  TextField(
                      keyboardType: TextInputType.number,
                      controller: searchController,
                      onChanged: provider.searchTags,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                              icon: Icon(provider.searchedTags!.isEmpty
                                  ? Icons.search
                                  : Icons.close),
                              onPressed: provider.searchedTags!.isEmpty
                                  ? null
                                  : () {
                                      searchController.clear();
                                      provider.searchTags("");
                                    }),
                          label: const Text("Search tags..."))),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Material(
                            type: MaterialType.transparency,
                            child: ListView.builder(
                                itemCount: provider.searchedTags!.isNotEmpty
                                    ? provider.searchedTags!.length
                                    : provider.tags!.length,
                                itemBuilder: (context, i) {
                                  return provider.searchedTags!.isNotEmpty
                                      ? ListTile(
                                          title: Text(
                                              "${provider.searchedTags!.indexOf(provider.searchedTags![i]) + 1}. ${provider.searchedTags![i]}"),
                                          onTap: () => provider.isTagSelected(
                                                  provider.searchedTags![i])
                                              ? provider.removeTag(context,
                                                  provider.searchedTags![i])
                                              : provider.addTag(context,
                                                  provider.searchedTags![i]),
                                          selected: provider.isTagSelected(
                                              provider.searchedTags![i]))
                                      : ExpansionTile(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          title: Text(
                                            provider.tags![i].name!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          children: provider.tags![i].subTags!
                                              .map((tag) => ListTile(
                                                    title: Text(
                                                        "${provider.tags![i].subTags!.indexOf(tag) + 1}. $tag"),
                                                    selected: provider
                                                        .isTagSelected(tag),
                                                    onTap: () => provider
                                                            .isTagSelected(tag)
                                                        ? provider
                                                            .removeTag(context,tag)
                                                        : provider.addTag(context,tag),
                                                  ))
                                              .toList(),
                                        );
                                }),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: provider.appliedTags
                              .map((tag) => ActionChip(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    label: Text(tag),
                                    avatar: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () => provider.removeTag(context,tag),
                                  ))
                              .toList(),
                        )
                      ],
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      );
    });
  }
}
