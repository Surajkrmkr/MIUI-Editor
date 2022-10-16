import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/element.dart';
import '../provider/icon.dart';
import '../provider/wallpaper.dart';

Consumer<WallpaperProvider> accentColorsList({required bool? isLockscreen}) {
  return Consumer<WallpaperProvider>(builder: (context, provider, child) {
    if (provider.isLoading!) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: provider.colorPalette!
          .map((e) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () {
                      if (isLockscreen!) {
                        final ElementProvider provider =
                            Provider.of<ElementProvider>(context,
                                listen: false);
                        provider.updateElementColorInList(
                            provider.activeType!, e);
                      } else {
                        Provider.of<IconProvider>(context, listen: false)
                            .setBgColor = e;
                        Provider.of<IconProvider>(context, listen: false)
                            .setAccentColor = e;
                      }
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                          color: e, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  });
}
