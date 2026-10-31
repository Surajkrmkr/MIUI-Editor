import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../application/providers/catalog_provider.dart';
import '../../domain/catalog_rules.dart';
import '../../domain/models/catalog.dart';

/// Creates a collection, or edits [existing]. Returns the collection's id.
Future<String?> showCollectionDialog(
  BuildContext context, {
  Map<String, dynamic>? existing,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _CollectionDialog(existing: existing),
    );

class _CollectionDialog extends ConsumerStatefulWidget {
  const _CollectionDialog({this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_CollectionDialog> createState() => _CollectionDialogState();
}

class _CollectionDialogState extends ConsumerState<_CollectionDialog> {
  late final _name = TextEditingController(text: '${widget.existing?['name'] ?? ''}');
  late final _productId = TextEditingController(text: '${widget.existing?['productId'] ?? ''}');
  late bool _hideForIOS = widget.existing?['hideForIOS'] == true;
  // New collections derive the product id from the name until it's edited.
  late bool _productIdTouched = widget.existing != null;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _productId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(catalogProvider(CatalogKind.collections).notifier);
    try {
      final String id;
      if (_isNew) {
        id = await notifier.createCollection(
          name: _name.text,
          productId: _productId.text.trim(),
          hideForIOS: _hideForIOS,
        );
      } else {
        id = '${widget.existing!['id']}';
        await notifier.updateCollection(
          id,
          name: _name.text,
          productId: _productId.text.trim(),
          hideForIOS: _hideForIOS,
        );
      }
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: Text(_isNew ? 'New collection' : 'Edit collection'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: _isNew,
              decoration: InputDecoration(
                labelText: 'Name',
                helperText: _isNew
                    ? 'Also the image folder name in Storage'
                    : 'Existing images keep their folder; new uploads use this name',
              ),
              onChanged: (v) {
                if (!_productIdTouched) {
                  _productId.text = v.trim().isEmpty ? '' : CatalogRules.defaultProductId(v);
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productId,
              decoration: const InputDecoration(
                labelText: 'In-app product id',
                helperText: 'Must match the product in Play Console and App Store Connect',
              ),
              onChanged: (_) => _productIdTouched = true,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hide on iOS'),
              subtitle: const Text('For collections not sold on the App Store'),
              value: _hideForIOS,
              onChanged: (v) => setState(() => _hideForIOS = v),
            ),
            if (_isNew)
              Text(
                'The app lists the collection as soon as it is saved, even while it is '
                'empty, so upload its wallpapers right after creating it. Buying it needs '
                'the in-app product to exist in the stores.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              SelectableText(_error!, style: TextStyle(color: colors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || _name.text.trim().isEmpty ? null : _save,
          child: Text(_isNew ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
