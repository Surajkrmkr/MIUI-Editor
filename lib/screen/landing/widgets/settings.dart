import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../functions/shared_prefs.dart';
import '../../../provider/directory.dart';
import '../../../widgets/ui_widgets.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController totalThemeCountController =
      TextEditingController();
  late ThemeSettings settings;

  @override
  void initState() {
    settings = SharedPrefs.getDataFromSF();
    totalThemeCountController.text = settings.themeCount.toString();
    super.initState();
  }

  void _setData() {
    final newSettings = ThemeSettings(
      themeCount: int.parse(totalThemeCountController.text),
    );
    SharedPrefs.setDataToSF(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Wrap(
        children: [
          const SizedBox(height: 20),
          TextField(
              controller: totalThemeCountController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (value) => _setData(),
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UIWidgets.iconButton(
                          onPressed: () {
                            totalThemeCountController.text =
                                (int.parse(totalThemeCountController.text) + 1)
                                    .toString();
                            _setData();
                          },
                          icon: Icons.add),
                      UIWidgets.iconButton(
                          onPressed: () {
                            if (int.parse(totalThemeCountController.text) > 1) {
                              totalThemeCountController.text =
                                  (int.parse(totalThemeCountController.text) -
                                          1)
                                      .toString();
                              _setData();
                            }
                          },
                          icon: Icons.remove_outlined),
                      const SizedBox(width: 10),
                    ],
                  ),
                  label: const Text("Theme Count")))
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            final provider =
                Provider.of<DirectoryProvider>(context, listen: false);
            provider
              ..getPreLockCount()
              ..setPreviewWallsPath(folderNum: "1");
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
