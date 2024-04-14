import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BuffyTextField extends StatefulWidget {
  final Function(String) onChanged;
  final String title;
  final String value;
  const BuffyTextField(
      {super.key,
      required this.title,
      required this.onChanged,
      required this.value});

  @override
  State<BuffyTextField> createState() => _BuffyTextFieldState();
}

class _BuffyTextFieldState extends State<BuffyTextField> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textController.text = stringToDouble(widget.value);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  String stringToDouble(String text) {
    try {
      return double.parse(text).toStringAsFixed(0);
    } catch (e) {
      return '0.0';
    }
  }

  @override
  void didUpdateWidget(BuffyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      textController.text = stringToDouble(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
        keyboardType: TextInputType.number,
        controller: textController,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        onChanged: (val) {
          widget.onChanged(double.parse(val).toStringAsFixed(2));
        },
        decoration: InputDecoration(
            border: const OutlineInputBorder(), label: Text(widget.title)));
  }
}
