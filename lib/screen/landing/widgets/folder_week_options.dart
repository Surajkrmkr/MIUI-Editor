import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miui_icon_generator/provider/directory.dart';
import 'package:miui_icon_generator/screen/homescreen/home_page.dart';

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
            Text("Select Folder",
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
                                    folderNum: provider.preLockFolderNum!,
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
