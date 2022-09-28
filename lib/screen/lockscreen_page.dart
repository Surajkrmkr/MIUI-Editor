import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/font.dart';
import '../widgets/accent_color_list.dart';
import '../widgets/image_stack.dart';

class LockscreenPage extends StatelessWidget {
  const LockscreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lockscreen"),
        actions: [accentColorsList()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ImageStack(isLockscreen: true),
              Row(
                children: const [
                  FontPreview(),
                  FontListWidget(),
                ],
              )
            ]),
      ),
    );
  }
}

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
            ? ListView.builder(
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
                    },
                  );
                })
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
              "02",
              style: TextStyle(
                  fontFamily: provider.fontFamily, fontSize: 60, height: 1),
            ),
            Text(
              "36",
              style: TextStyle(
                  fontFamily: provider.fontFamily, fontSize: 60, height: 1),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Wednesday",
              style: TextStyle(fontFamily: provider.fontFamily, fontSize: 30),
            ),
            Text(
              "February",
              style: TextStyle(fontFamily: provider.fontFamily, fontSize: 30),
            ),
          ],
        ),
      );
    });
  }
}
