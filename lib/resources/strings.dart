import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MIUIString {
  static Map<String?, String?> dateTimeStringMap = {
    "dd": "08",
    "E": "Wed",
    "MM": '02',
    "yy": "22",
    "aa": "PM",
    "hh": '02',
    "mm": "36",
    "ss": "06"
  };

  static Map<String?, String?> globalVarMap = {
    "#battery_level": "100",
    "#temp": "24",
    "@cityName": "Cuttack",
    "@airQuality": "Moderately Polluted",
    "#sms_unread_count": "2",
    "#call_missed_count": "5",
    "@next_alarm_time": "Mon, 12:00 am",
    "'": "",
    "+": ""
  };

  static String getReplacedText(String? text) {
    String? localText = text;

    for (var e in dateTimeStringMap.entries) {
      if (localText!.contains(e.key!)) {
        localText = localText.replaceAll(e.key!, e.value!);
      }
    }
    return localText!;
  }

  static String getGlobalVarText(String? text) {
    String? localText = text;

    for (var e in globalVarMap.entries) {
      if (localText!.contains(e.key!)) {
        localText = localText.replaceAll(e.key!, e.value!);
      }
    }
    return localText!;
  }
}

class GlobalVarDetailsDialog extends StatelessWidget {
  const GlobalVarDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: TextButton.icon(
        icon: const Icon(Icons.info),
        onPressed: () {
          showDialog(
              context: context,
              builder: ((context) {
                return Dialog(
                    child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Wrap(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Date Time",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            height: 300,
                            width: 100,
                            child: ListView.builder(
                                itemCount: MIUIString.dateTimeStringMap.length,
                                itemBuilder: (context, i) {
                                  final keys = MIUIString.dateTimeStringMap.keys
                                      .toList();
                                  final val =
                                      MIUIString.dateTimeStringMap[keys[i]];
                                  return ListTile(
                                    title: Text(keys[i]!),
                                    subtitle: Text(val!),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Clipboard.setData(
                                          ClipboardData(text: keys[i]!));
                                    },
                                  );
                                }),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Global Variables",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            height: 300,
                            width: 300,
                            child: ListView.builder(
                                itemCount: MIUIString.globalVarMap.length - 2,
                                itemBuilder: (context, i) {
                                  final keys =
                                      MIUIString.globalVarMap.keys.toList();
                                  final val = MIUIString.globalVarMap[keys[i]];
                                  return ListTile(
                                    title: Text(keys[i]!),
                                    subtitle: Text(val!),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Clipboard.setData(
                                          ClipboardData(text: keys[i]!));
                                    },
                                  );
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ));
              }));
        },
        label: const Text('Instruction'),
      ),
    );
  }
}
