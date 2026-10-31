import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../domain/bulk_details.dart';

/// Example shown by "Insert sample"; matches docs/wallrio_bulk_details.schema.json.
const bulkDetailsSample = '''{
  "defaults": {
    "author": "WallRio",
    "category": "Nature",
    "isPremium": false
  },
  "walls": [
    {
      "file": "golden_fields.jpg",
      "name": "Golden Fields",
      "tags": ["Sunset", "Field", "Warm"],
      "colors": ["Yellow", "Orange"]
    },
    {
      "file": "misty_peaks.png",
      "name": "Misty Peaks",
      "category": "Mountains",
      "tags": ["Fog", "Mountain"],
      "colors": ["Blue", "Grey"],
      "isPremium": true
    }
  ]
}''';

/// A JSON editor for filling many uploads at once. Returns the parsed details
/// and the text (to reopen the editor where the user left off).
Future<({BulkDetails details, String text})?> showBulkDetailsDialog(
  BuildContext context, {
  required String initialText,
}) => showDialog(
  context: context,
  builder: (_) => _BulkDetailsDialog(initialText: initialText),
);

class _BulkDetailsDialog extends StatefulWidget {
  const _BulkDetailsDialog({required this.initialText});

  final String initialText;

  @override
  State<_BulkDetailsDialog> createState() => _BulkDetailsDialogState();
}

class _BulkDetailsDialogState extends State<_BulkDetailsDialog> {
  late final _controller = TextEditingController(text: widget.initialText);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() {
      _controller.text = File(path).readAsStringSync();
      _error = null;
    });
  }

  void _format() {
    try {
      final pretty = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonDecode(_controller.text));
      setState(() {
        _controller.text = pretty;
        _error = null;
      });
    } on FormatException catch (e) {
      setState(() => _error = 'Invalid JSON: ${e.message}');
    }
  }

  void _apply() {
    try {
      final details = BulkDetails.parse(_controller.text);
      Navigator.of(context).pop((details: details, text: _controller.text));
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fill details from JSON',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"defaults" apply to every file; each "walls" entry overrides them for the file '
                'named in "file" (case-insensitive, extension optional). Files dropped later get '
                'these details too. Fields: name, author, category, tags, colors, isPremium.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: colors.bgSubtle,
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  _error!,
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _loadFile,
                    icon: const Icon(Icons.file_open_outlined, size: 18),
                    label: const Text('Load .json'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _controller.text = bulkDetailsSample;
                      _error = null;
                    }),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Insert sample'),
                  ),
                  TextButton.icon(
                    onPressed: _format,
                    icon: const Icon(Icons.format_align_left_rounded, size: 18),
                    label: const Text('Format'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _apply, child: const Text('Apply')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
