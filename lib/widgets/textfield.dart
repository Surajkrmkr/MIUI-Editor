import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../provider/export.dart';
import '../provider/icon.dart';
import '../provider/wallpaper.dart';

class TextFields extends StatelessWidget {
  const TextFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final provider = Provider.of<IconProvider>(context, listen: false);
      return SizedBox(
        width: 200,
        height: 400,
        child: Column(
          children: [
            buildTextField(
                initialtext: provider.radius.toString(),
                text: 'Radius',
                onChange: (e) {
                  if (e.isNotEmpty) {
                    provider.setRadius = double.parse(e);
                  }
                }),
            const SizedBox(
              height: 40,
            ),
            buildTextField(
                initialtext: provider.margin.toString(),
                text: 'Margin',
                onChange: (e) {
                  provider.setMargin = double.parse(e);
                }),
            const SizedBox(
              height: 40,
            ),
            buildTextField(
                initialtext: provider.padding.toString(),
                text: 'Padding',
                onChange: (e) {
                  provider.setPadding = double.parse(e);
                }),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 23, horizontal: 35)),
                onPressed: () {
                  final wallNum = Provider.of<WallpaperProvider>(context,listen: false).index! +1;
                  final folderNum = Provider.of<WallpaperProvider>(context,listen: false).folderNum;
                  Provider.of<ExportIconProvider>(context, listen: false)
                      .export(provider:provider,folderNum: folderNum,wallNum: wallNum.toString());
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return Consumer<ExportIconProvider>(
                          builder: (context, provider, _) {
                            final progress = provider.progress;
                            final total = IconVectorData.vectorList.length;
                            return SimpleDialog(
                              contentPadding: const EdgeInsets.all(20),
                              title: const Center(child: Text("Get Set Go")),
                              children: [
                                Center(
                                    child: Column(
                                  children: [
                                    if (provider.isExporting!)
                                      LinearProgressIndicator(
                                        value: progress!.toDouble() / total,
                                      ),
                                    if (provider.isExporting!)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            "${provider.progress.toString()}/$total"),
                                      ),
                                    if (!provider.isExporting!)
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 20.0),
                                          child: Text("Export Completed...")),
                                    if (!provider.isExporting!)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20.0),
                                        child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text("OK")),
                                      )
                                  ],
                                ))
                              ],
                            );
                          },
                        );
                      });
                },
                child: const Text("Export"))
          ],
        ),
      );
    });
  }

  TextField buildTextField(
      {required String? initialtext,
      required String? text,
      required Function(String e)? onChange}) {
    return TextField(
        keyboardType: TextInputType.number,
        controller: TextEditingController(text: initialtext),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        onChanged: onChange,
        decoration: InputDecoration(
            border: const OutlineInputBorder(), label: Text(text!)));
  }
}
