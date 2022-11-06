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
