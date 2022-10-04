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
      return SizedBox(
        width: 200,
        child: !provider.isLoading!
            ? Column(
                children: [
                  Text(
                    "Font Lists",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: ListView.builder(
                        itemCount: provider.fonts.length,
                        itemBuilder: (context, i) {
                          final font = provider.fonts[i];
                          return ListTile(
                            title: Text(
                              font.name!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: font.name,
                                fontSize: 25,
                              ),
                            ),
                            trailing: const Icon(Icons.check),
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

class FontPreview extends StatelessWidget {
  const FontPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FontProvider>(builder: (context, provider, _) {
      return SizedBox(
        width: 200,
        child: Column(
          children: [
            Text(
              "Font Preview",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: () {},
              child: SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Text(
                      "02",
                      style: TextStyle(
                          fontFamily: provider.fontFamily,
                          fontSize: 60,
                          height: 1),
                    ),
                    Text(
                      "36",
                      style: TextStyle(
                          fontFamily: provider.fontFamily,
                          fontSize: 60,
                          height: 1),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Wednesday",
                      style: TextStyle(
                          fontFamily: provider.fontFamily, fontSize: 25),
                    ),
                    Text(
                      "February",
                      style: TextStyle(
                          fontFamily: provider.fontFamily, fontSize: 25),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
