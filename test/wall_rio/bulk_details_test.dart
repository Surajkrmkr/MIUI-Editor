import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/wall_rio/domain/bulk_details.dart';
import 'package:miui_icon_generator/wall_rio/domain/models/catalog.dart';
import 'package:miui_icon_generator/wall_rio/presentation/widgets/bulk_details_dialog.dart';

WallpaperDraft _draft(String path) => WallpaperDraft(
      localPath: path,
      width: 1720,
      height: 3728,
      name: 'Auto',
      author: 'WallRio',
      category: '',
    );

void main() {
  test('the built-in sample parses', () {
    final details = BulkDetails.parse(bulkDetailsSample);
    expect(details.entries.map((e) => e.file), ['golden_fields.jpg', 'misty_peaks.png']);
  });

  test('defaults apply to every file, entries override them', () {
    final details = BulkDetails.parse(bulkDetailsSample);
    final golden = _draft('/drops/Golden_Fields.JPG');
    final misty = _draft('/drops/misty_peaks.png');
    final other = _draft('/drops/unlisted.png');

    expect(details.applyTo(golden), isTrue);
    expect(details.applyTo(misty), isTrue);
    expect(details.applyTo(other), isFalse);

    expect(golden.name, 'Golden Fields');
    expect(golden.category, 'Nature'); // from defaults
    expect(golden.colors, ['Yellow', 'Orange']);
    expect(golden.isPremium, isFalse);
    expect(misty.category, 'Mountains'); // entry wins
    expect(misty.isPremium, isTrue);
    expect(other.name, 'Auto'); // no entry: keeps its own name
    expect(other.category, 'Nature');
  });

  test('file matches with or without the extension, case-insensitively', () {
    final details = BulkDetails.parse('[{"file": "Neon City", "name": "Neon"}]');
    final draft = _draft(r'C:\walls\neon city.png');
    expect(details.applyTo(draft), isTrue);
    expect(draft.name, 'Neon');
  });

  test('unmatched lists entries that name no dropped file', () {
    final details = BulkDetails.parse(bulkDetailsSample);
    expect(details.unmatched(['/x/golden_fields.jpg']), ['misty_peaks.png']);
  });

  group('rejects with a readable message', () {
    void expectError(String json, String fragment) {
      expect(
        () => BulkDetails.parse(json),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(fragment))),
      );
    }

    test('broken JSON', () => expectError('{"walls": [', 'Invalid JSON'));
    test('typo in a field name', () => expectError('[{"file": "a", "catgory": "x"}]', '"catgory"'));
    test('missing file', () => expectError('[{"name": "a"}]', 'needs a "file"'));
    test('duplicate file', () => expectError('[{"file": "a.jpg"}, {"file": "A"}]', 'listed twice'));
    test('tags not a list', () => expectError('[{"file": "a", "tags": "Red"}]', 'list of text'));
    test('isPremium not a bool', () => expectError('{"defaults": {"isPremium": "yes"}}', 'true or false'));
    test('file in defaults', () => expectError('{"defaults": {"file": "a"}}', '"file"'));
  });

  test('template round-trips the current drafts', () {
    final draft = _draft('/drops/a.jpg')
      ..name = 'Alpha'
      ..tags = ['One']
      ..isPremium = true;
    final details = BulkDetails.parse(BulkDetails.template([draft]));
    final fresh = _draft('/elsewhere/a.jpg');
    details.applyTo(fresh);
    expect(fresh.name, 'Alpha');
    expect(fresh.tags, ['One']);
    expect(fresh.isPremium, isTrue);
  });
}
