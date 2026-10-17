import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/theme_cli.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('schema_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<({int code, String out, String err})> run(List<String> args) async {
    final out = StringBuffer(), err = StringBuffer();
    final code = await runCli(args, out: out, err: err, cwd: tmp);
    return (code: code, out: out.toString(), err: err.toString());
  }

  test('prints the schema as JSON', () async {
    final r = await run(['schema']);
    expect(r.code, ExitCodes.ok);
    final schema = jsonDecode(r.out) as Map<String, dynamic>;
    expect(schema[r'$schema'], contains('json-schema.org'));
    expect(
      (schema['properties'] as Map).keys,
      containsAll(['meta', 'icons', 'lockscreen']),
    );
  });

  test('the checked-in schema is up to date', () async {
    final checkedIn = File('schema/theme.schema.json');
    expect(
      checkedIn.existsSync() ? checkedIn.readAsStringSync() : '',
      (await run(['schema'])).out,
      reason:
          'Regenerate with: dart run bin/theme.dart schema --out schema/theme.schema.json',
    );
  });

  test('--out writes the file and prints its path', () async {
    final r = await run(['schema', '--out', 'schemas/theme.schema.json']);
    final file = File(p.join(tmp.path, 'schemas', 'theme.schema.json'));
    expect(r.code, ExitCodes.ok, reason: r.err);
    expect(r.out.trim(), file.path);
    expect(jsonDecode(file.readAsStringSync()), isA<Map>());
  });

  test('an unwritable --out exits 3', () async {
    File(p.join(tmp.path, 'blocked')).writeAsStringSync('');
    final r = await run(['schema', '--out', 'blocked/x.json']);
    expect(r.code, ExitCodes.io);
    expect(r.err, contains('Cannot write'));
  });
}
