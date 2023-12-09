import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miui_icon_generator/provider/directory.dart';
import 'package:miui_icon_generator/screen/homescreen/home_page.dart';

import '../../../widgets/ui_widgets.dart';

class FolderWeekOptions extends StatelessWidget {
  FolderWeekOptions({
    Key? key,
    required this.provider,
  }) : super(key: key);

  final TextEditingController weekNumController = TextEditingController();
  final DirectoryProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 600,
        height: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Select Folder",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Wrap(
                    alignment: WrapAlignment.center,
                    children: provider.preLockPaths
                        .map((path) => SizedBox(
                              width: 150,
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
              ),
            ),
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
                  onSubmitted: (value) => _onSubmit(context),
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: UIWidgets.iconButton(
                          onPressed: () => _onSubmit(context),
                          icon: Icons.navigate_next),
                      label: const Text("Week Number"))),
            ),
          ],
        ));
  }

  void _onSubmit(context) {
    if (weekNumController.text.isNotEmpty) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                    folderNum: provider.preLockFolderNum!,
                    weekNum: weekNumController.text,
                  )));
    }
  }
}
