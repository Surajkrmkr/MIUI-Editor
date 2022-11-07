import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/element.dart';
import '../provider/font.dart';

class FontListWidget extends StatelessWidget {
  const FontListWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FontProvider>(builder: (context, provider, _) {
      if (!provider.isLoading!) {
        provider.fonts.sort(((a, b) => b.id!.compareTo(a.id!)));
      }
      return SizedBox(
        width: 200,
        child: !provider.isLoading!
            ? Column(
                children: [
                  if (Platform.isWindows)
                    Text(
                      "Font Lists",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  if (Platform.isWindows)
                    const SizedBox(
                      height: 20,
                    ),
                  Expanded(
                    child: ListView.builder(
                        itemCount: provider.fonts.length,
                        itemBuilder: (context, i) {
                          final eleProvider = Provider.of<ElementProvider>(
                              context,
                              listen: true);
                          final font = provider.fonts[i];
                          final bool isSelected = eleProvider
                                  .getElementFromList(eleProvider.activeType!)
                                  .font ==
                              font.dynamicCachedFonts!.fontFamily;
                          return ListTile(
                            selected: isSelected,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            title: Text(
                              font.name!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: font.name,
                                fontSize: 25,
                              ),
                            ),
                            onTap: () {
                              provider.setFontFamily =
                                  font.dynamicCachedFonts!.fontFamily;
                              final eleProvider = Provider.of<ElementProvider>(
                                  context,
                                  listen: false);
                              eleProvider.updateElementFontInList(
                                  eleProvider.activeType!,
                                  font.dynamicCachedFonts!.fontFamily);
                            },
                          );
                        }),
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
