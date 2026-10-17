import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/root_config.dart';
import 'package:theme_cli/theme_cli.dart';

import 'support/fake_renderer.dart';

/// Tests that expect no root can't run when the shell sets one.
final _envRoot = Platform.environment['THEME_ROOT'] == null
    ? null
    : 'THEME_ROOT is set in the environment';

void main() {
  late Directory tmp;
  late ThemeRoot root;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('root_test');
    root = ThemeRoot(p.join(tmp.path, 'Xiaomi Contract'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  void png(String path, {int w = 30, int h = 60}) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(
      img.encodePng(
        img.Image(width: w, height: h)..clear(img.ColorRgb8(20, 20, 60)),
      ),
    );

  /// Wall/2/sky.png, Wall/loose.png and the default lockscreen assets.
  void library() {
    png(p.join(root.wallFolder('2'), 'sky.png'));
    png(p.join(root.wallDir, 'loose.png'));
    png(p.join(root.assetsDir, 'bg.png'));
  }

  Map<String, dynamic> spec({
    String home = 'sky.png',
    Object? assetsDir,
    Object? workspace,
  }) => {
    'specVersion': 1,
    'meta': {'title': 'Neon', 'designer': 'D', 'authorTag': 'T'},
    'wallpaper': {'home': home},
    'icons': {'pack': 'u1'},
    'lockscreen': {
      'assetsDir': ?assetsDir,
      'elements': [
        {'type': 'swipeUpUnlock'},
      ],
    },
    'workspace': ?workspace,
  };

  group('ThemeRoot', () {
    test('lays out the folders like the desktop editor', () {
      expect(root.wallFolder('2'), p.join(root.path, 'Wall', '2'));
      expect(root.weekDir('3'), p.join(root.path, 'THEMES', 'Week3'));
      expect(
        root.assetsDir,
        p.join(root.path, 'Sample2', 'lockscreen', 'advance'),
      );
      expect(root.presetsDir, p.join(root.path, 'Preset'));
    });

    test('refuses a week or folder that could leave the root', () {
      for (final bad in ['../x', 'a/b', '', '..', 'a b']) {
        expect(() => root.weekDir(bad), throwsArgumentError, reason: bad);
        expect(() => root.wallFolder(bad), throwsArgumentError, reason: bad);
      }
      expect(isSafeSegment('3'), isTrue);
      expect(isSafeSegment('A_2-b'), isTrue);
    });

    group('prepare', () {
      test('fills in the default lockscreen assets', () {
        library();
        final s = root.prepare(spec(), tmp.path);
        expect(s['lockscreen']['assetsDir'], root.assetsDir);
      });

      test('keeps an assetsDir the spec names', () {
        library();
        final s = root.prepare(spec(assetsDir: '/mine'), tmp.path);
        expect(s['lockscreen']['assetsDir'], '/mine');
      });

      test('leaves the lockscreen alone when the assets folder is missing', () {
        final s = root.prepare(spec(), tmp.path);
        expect(s['lockscreen'].containsKey('assetsDir'), isFalse);
      });

      test(
        'finds a wallpaper by name in the workspace folder, then in Wall',
        () {
          library();
          final byFolder = root.prepare(
            spec(workspace: {'folder': '2'}),
            tmp.path,
          );
          expect(
            byFolder['wallpaper']['home'],
            p.join(root.wallFolder('2'), 'sky.png'),
          );

          final loose = root.prepare(spec(home: 'loose.png'), tmp.path);
          expect(loose['wallpaper']['home'], p.join(root.wallDir, 'loose.png'));
        },
      );

      test(
        'a wallpaper next to the spec, or an absolute one, is left alone',
        () {
          library();
          png(p.join(tmp.path, 'sky.png'));
          expect(
            root.prepare(
              spec(workspace: {'folder': '2'}),
              tmp.path,
            )['wallpaper']['home'],
            'sky.png',
          );
          expect(
            root.prepare(
              spec(home: '/elsewhere/sky.png'),
              tmp.path,
            )['wallpaper']['home'],
            '/elsewhere/sky.png',
          );
        },
      );

      test('an unknown wallpaper stays as written, so validation names it', () {
        library();
        expect(
          root.prepare(spec(home: 'nope.png'), tmp.path)['wallpaper']['home'],
          'nope.png',
        );
      });

      test('an unsafe workspace folder is not used for lookup', () {
        library();
        final s = root.prepare(spec(workspace: {'folder': '../2'}), tmp.path);
        expect(s['wallpaper']['home'], 'sky.png');
      });
    });
  });

  group('specPreparer', () {
    test('is null when there is nothing to apply', () {
      expect(specPreparer(), isNull);
    });

    test('sets week and folder, over what the spec says', () {
      final s = spec(workspace: {'week': '1', 'folder': '9', 'extra': true});
      specPreparer(week: '5', folder: '2')!(s, tmp.path);
      expect(s['workspace'], {'week': '5', 'folder': '2', 'extra': true});
    });

    test('creates the workspace when the spec has none', () {
      final s = spec();
      specPreparer(week: '5')!(s, tmp.path);
      expect(s['workspace'], {'week': '5'});
    });
  });

  group('batch with a root', () {
    Future<({int code, String out, String err})> cli(
      List<String> args,
      Sidecar sidecar,
    ) async {
      final o = StringBuffer(), e = StringBuffer();
      final code = await runCli(
        args,
        out: o,
        err: e,
        cwd: tmp,
        sidecar: sidecar,
      );
      return (code: code, out: o.toString(), err: e.toString());
    }

    String write(Map<String, dynamic> s, [String name = 'neon.json']) {
      final f = File(p.join(tmp.path, 'specs', name))
        ..createSync(recursive: true);
      f.writeAsStringSync(jsonEncode(s));
      return f.path;
    }

    test(
      'builds a spec that names only a wallpaper, into THEMES/Week<n>',
      () async {
        library();
        final renderer = FakeRenderer();
        final r = await cli([
          'batch',
          write(spec()),
          '--root',
          root.path,
          '--week',
          '3',
          '--folder',
          '2',
          '--no-contrast',
        ], renderer);

        expect(r.code, ExitCodes.ok, reason: '${r.out}\n${r.err}');
        final job = renderer.jobs.single;
        expect(job.outDir, root.weekDir('3'));
        expect(
          File(p.join(root.weekDir('3'), 'Neon.mtz')).existsSync(),
          isTrue,
        );

        final built = renderer.specs.single;
        expect(
          built['wallpaper']['home'],
          p.join(root.wallFolder('2'), 'sky.png'),
        );
        expect(built['lockscreen']['assetsDir'], root.assetsDir);
        expect(built['workspace'], {'week': '3', 'folder': '2'});
      },
    );

    test(
      'the rewritten spec resolves paths next to the original and is removed afterwards',
      () async {
        library();
        final original = write(spec());
        final renderer = FakeRenderer();
        await cli([
          'batch',
          original,
          '--root',
          root.path,
          '--week',
          '3',
          '--folder',
          '2',
          '--no-contrast',
        ], renderer);

        final job = renderer.jobs.single;
        expect(job.id, original);
        expect(job.spec, isNot(original));
        expect(job.baseDir, p.dirname(original));
        expect(File(job.spec).existsSync(), isFalse);
        expect(
          File(original).readAsStringSync(),
          jsonEncode(spec()),
          reason: 'the original is untouched',
        );
      },
    );

    test('a spec that needs nothing is built from the original file', () async {
      library();
      final complete = spec(
        home: p.join(root.wallFolder('2'), 'sky.png'),
        assetsDir: root.assetsDir,
      );
      final path = write(complete);
      final renderer = FakeRenderer();
      await cli([
        'batch',
        path,
        '--out',
        'out',
        '--root',
        root.path,
        '--no-contrast',
      ], renderer);
      expect(renderer.jobs.single.spec, path);
    });

    test('--week needs --root, and --out may stand in for it', () async {
      library();
      final path = write(spec());
      final env = Platform.environment['THEME_ROOT'];
      if (env == null) {
        expect(
          (await cli(['batch', path, '--week', '3'], FakeRenderer())).code,
          ExitCodes.usage,
        );
      }
      expect(
        (await cli(['batch', path], FakeRenderer())).code,
        ExitCodes.usage,
      );
      expect(
        (await cli([
          'batch',
          path,
          '--root',
          root.path,
          '--week',
          '../x',
        ], FakeRenderer())).code,
        ExitCodes.usage,
      );
    });

    test('without --root nothing is filled in', () async {
      library();
      final r = await cli([
        'batch',
        write(spec()),
        '--out',
        'out',
        '--no-contrast',
      ], FakeRenderer());
      expect(r.code, ExitCodes.invalid);
      expect(r.out, contains('asset.missing'));
    }, skip: _envRoot);

    test('validate takes --root too', () async {
      library();
      final path = write(spec(workspace: {'folder': '2'}));
      expect(
        (await cli(['validate', path, '--no-contrast'], FakeRenderer())).code,
        ExitCodes.invalid,
      );
      expect(
        (await cli([
          'validate',
          path,
          '--root',
          root.path,
          '--no-contrast',
        ], FakeRenderer())).code,
        ExitCodes.ok,
      );
    }, skip: _envRoot);
  });
}
