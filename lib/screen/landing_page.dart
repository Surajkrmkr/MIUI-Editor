import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              "Welcome to MIUI World \n by Suraj",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30),
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
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                      width: 600,
                      height: 400,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Choose Folder",
                              style: Theme.of(context).textTheme.headline5),
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
                                            groupValue:
                                                provider.preLockFolderNum,
                                            onChanged: (val) {
                                              provider.setPreLockFolderNum =
                                                  val!;
                                              provider.setPreviewWallsPath(
                                                  folderNum: val);
                                            }),
                                      ))
                                  .toList()),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            provider.status!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                    color: Colors.pinkAccent,
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
                                                  folderNum:
                                                      provider.preLockFolderNum,
                                                  weekNum:
                                                      weekNumController!.text,
                                                )));
                                  }
                                }),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.navigate_next),
                                    label: Text("Week Number"))),
                          ),
                        ],
                      )),
                  Column(
                    children: [
                      Text("Previews",
                          style: Theme.of(context).textTheme.headline5),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: 600,
                        width: 350,
                        child: provider.isLoadingPreviewWallPath!
                            ? const CircularProgressIndicator()
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: GridView.builder(
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
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0,
                                                  5), // changes position of shadow
                                            ),
                                          ],
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: FileImage(
                                              File(provider
                                                  .previewWallsPath[i]!),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                      ),
                    ],
                  )
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
