import 'dart:io';

import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../provider/directory.dart';

class PreviewWeekWalls extends StatelessWidget {
  const PreviewWeekWalls({
    Key? key,
    required this.provider,
  }) : super(key: key);
  final DirectoryProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (MIUIConstants.isDesktop) ...[
          Text("Previews", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
        ],
        SizedBox(
          height: Platform.isAndroid ? 200 : 600,
          width: 350,
          child: provider.isLoadingPreviewWallPath!
              ? const Center(child: CircularProgressIndicator())
              : ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: GridView.builder(
                      scrollDirection:
                          Platform.isAndroid ? Axis.horizontal : Axis.vertical,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              childAspectRatio: 1,
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20),
                      itemCount: provider.previewWallsPath.length,
                      itemBuilder: (context, i) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(
                                    0, 5), // changes position of shadow
                              ),
                            ],
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: FileImage(
                                File(provider.previewWallsPath[i]!),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(provider.previewWallsPath[i]!
                                  .split(Platform.pathSeparator)
                                  .last),
                            ),
                          ),
                        );
                      }),
                ),
        ),
      ],
    );
  }
}
