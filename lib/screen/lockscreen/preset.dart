import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../provider/directory.dart';
import '../../provider/lockscreen.dart';

class PresetLockscreenDialog extends StatelessWidget {
  const PresetLockscreenDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.layers),
      onPressed: () {
        showDialog(
          context: context,
          builder: ((context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: const PresetPage()),
            );
          }),
        );
      },
      label: const Text('Preset collections'),
    );
  }
}

class PresetPage extends StatefulWidget {
  const PresetPage({
    super.key,
  });

  @override
  State<PresetPage> createState() => _PresetPageState();
}

class _PresetPageState extends State<PresetPage> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      final provider = Provider.of<DirectoryProvider>(context, listen: false);
      provider.getPresetLockPath();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preset Collections"),
      ),
      body: Consumer<DirectoryProvider>(builder: (context, provider, _) {
        if (provider.isLoadingPrelockCount!) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.presetLockPaths.isEmpty) {
          return Center(
            child: Text(
              "NO PRESET AVAILABLE",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.presetLockPaths.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, crossAxisSpacing: 20, mainAxisSpacing: 20),
            itemBuilder: (context, i) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () =>
                        Provider.of<LockscreenProvider>(context, listen: false)
                            .importPresetToLockscreen(
                                context: context,
                                jsonPath: provider.presetLockPaths[i]!),
                    child: Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        margin: EdgeInsets.zero,
                        child: Center(
                            child: Text(
                                "Preset #${i + 1}\n${provider.presetLockPaths[i]!.split("/").last}")))),
              );
            });
      }),
    );
  }
}
