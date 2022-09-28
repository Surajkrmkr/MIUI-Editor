import 'package:flutter/material.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';
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
              Consumer<FontProvider>(builder: (context, provider, _) {
                return Row(
                  children: [
                    Text(
                      "Hello World! 12345",
                      style: provider.font!.toTextStyle(),
                    ),
                    // SizedBox(
                    //   height: 600,
                    //   width: 300,
                    //   child: FontPicker(
                    //     showInDialog: true,
                    //     onFontChanged: (PickerFont font) {
                    //       provider.changeFont = font;
                    //     },
                    //     initialFontFamily: 'Roboto',
                    //   ),
                    // ),
                  ],
                );
              }),
            ]),
      ),
    );
  }
}
