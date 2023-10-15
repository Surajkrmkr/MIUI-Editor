import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:provider/provider.dart';

import '../provider/directory.dart';
import 'homescreen/home_page.dart';

class LandingPage extends StatelessWidget {
  LandingPage({super.key});

  final TextEditingController? weekNumController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Provider.of<DirectoryProvider>(context, listen: false).getPreLockCount();
      Provider.of<DirectoryProvider>(context, listen: false)
          .setPreviewWallsPath(folderNum: "1");
    });
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text(
                  "Welcome to MIUI World",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30),
                ),
                if (Platform.isAndroid)
                  const SizedBox(
                    height: 20,
                  ),
                Consumer<DirectoryProvider>(builder: (context, provider, _) {
                  if (provider.isLoadingPrelockCount!) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.preLockPaths.isEmpty) {
                    return Text(
                      "NO FOLDER AVAILABLE",
                      style: Theme.of(context).textTheme.bodyLarge,
                    );
                  }
                  return Platform.isAndroid
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PreviewWeekWalls(provider: provider),
                            FolderWeekOptions(
                                weekNumController: weekNumController,
                                provider: provider),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FolderWeekOptions(
                                weekNumController: weekNumController,
                                provider: provider),
                            PreviewWeekWalls(provider: provider)
                          ],
                        );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
          Text("Previews", style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(
            height: 20,
          ),
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
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(provider.previewWallsPath[i]!
                                .split(Platform.pathSeparator)
                                .last),
                          ),
                        );
                      }),
                ),
        ),
      ],
    );
  }
}

class FolderWeekOptions extends StatelessWidget {
  const FolderWeekOptions({
    Key? key,
    required this.weekNumController,
    required this.provider,
  }) : super(key: key);

  final TextEditingController? weekNumController;
  final DirectoryProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 600,
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Choose Folder",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(
              height: 20,
            ),
            Wrap(
                alignment: WrapAlignment.center,
                children: provider.preLockPaths
                    .map((path) => SizedBox(
                          width: 100,
                          child: RadioListTile(
                              title: Text(path!),
                              value: path,
                              groupValue: provider.preLockFolderNum,
                              onChanged: (val) {
                                provider.setPreLockFolderNum = val!;
                                provider.setPreviewWallsPath(folderNum: val);
                              }),
                        ))
                    .toList()),
            const SizedBox(
              height: 20,
            ),
            Text(
              provider.status!,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 300,
              child: TextField(
                  keyboardType: TextInputType.number,
                  controller: weekNumController,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  onSubmitted: ((value) {
                    if (value.isNotEmpty) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePage(
                                    folderNum: provider.preLockFolderNum,
                                    weekNum: weekNumController!.text,
                                  )));
                    }
                  }),
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.navigate_next),
                      label: Text("Week Number"))),
            ),
          ],
        ));
  }
}
