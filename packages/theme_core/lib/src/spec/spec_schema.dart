import '../icons/icon_effect.dart';
import '../icons/icon_shape.dart';
import '../icons/icon_texture.dart';
import '../icons/control_center_template.dart';
import '../lockscreen/element_enums.dart';
import '../lockscreen/lock_element_spec.dart';
import 'theme_spec.dart';

/// A JSON Schema (draft 2020-12) for the theme spec, for editors and AI tools.
///
/// Enum values and the element fields come from the code, so the schema
/// follows the model; the validator still checks what a schema can't, such as
/// files on disk and legibility.
Map<String, Object?> themeSpecSchema() {
  Map<String, Object?> obj(
    Map<String, Object?> props, {
    List<String> required = const [],
    String? description,
  }) => {
    'type': 'object',
    if (description != null) 'description': description,
    'properties': props,
    if (required.isNotEmpty) 'required': required,
    'additionalProperties': false,
  };

  Map<String, Object?> names(List<Enum> values) => {
    'enum': [for (final v in values) v.name],
  };
  const color = {'\$ref': '#/\$defs/color'};
  const alignment = {'\$ref': '#/\$defs/alignment'};
  const number = {'type': 'number'};
  const string = {'type': 'string'};

  return {
    '\$schema': 'https://json-schema.org/draft/2020-12/schema',
    'title': 'MIUI/HyperOS theme spec',
    'description':
        'Everything needed to build one HyperOS 3 theme (.mtz). Relative '
        'paths resolve against the folder holding this file.',
    ...obj(
      {
        '\$schema': {
          'type': 'string',
          'description': 'Lets editors find this schema; ignored by the tool.',
        },
        'specVersion': {'const': ThemeSpec.currentVersion},
        'meta': obj(
          {
            'title': {
              'type': 'string',
              'minLength': 1,
              'description': 'Theme name, shown on the phone.',
            },
            'designer': string,
            'authorTag': string,
            'version': string,
            'uiVersion': {'type': 'integer', 'description': 'Target is 17.'},
            'profile': {
              'type': 'string',
              'description': 'Editor profile; picks default icon pack.',
            },
          },
          required: ['title'],
        ),
        'workspace': obj({
          'week': string,
          'folder': string,
        }, description: 'Where the desktop editor keeps this theme.'),
        'wallpaper': obj(
          {
            'home': {'type': 'string', 'description': 'Image file path.'},
            'lock': string,
          },
          required: ['home'],
        ),
        'icons': obj(
          {
            'pack': {'type': 'string', 'description': 'assets/icons/<pack>'},
            'margin': number,
            'padding': number,
            'radius': number,
            'borderWidth': number,
            'shape': names(IconShape.values),
            'iconColor': color,
            'borderColor': color,
            'background': obj({
              'colors': {'type': 'array', 'items': color},
              'randomColors': {'type': 'boolean'},
              'palette': {'type': 'array', 'items': color},
              'gradient': obj({'start': alignment, 'end': alignment}),
            }),
            'effect': obj({
              'type': names(IconEffect.values),
              'intensity': number,
              'blur': number,
              'elevation': number,
            }),
            'texture': obj({
              'type': names(IconTexture.values),
              'scale': number,
              'opacity': number,
            }),
          },
          required: ['pack'],
        ),
        'systemUi': obj({
          'accent': color,
          'controlCenterTemplate': names(ControlCenterTemplate.values),
        }),
        'lockscreen': obj({
          'bgAlpha': {'type': 'number', 'minimum': 0, 'maximum': 1},
          'assetsDir': {
            'type': 'string',
            'description':
                'Folder with bg.png and the default lockscreen images.',
          },
          'elements': {
            'type': 'array',
            'items': {'\$ref': '#/\$defs/element'},
          },
        }),
        'fonts': {
          'type': 'array',
          'description':
              'Font files for every element font except Roboto. Omit path '
              'when the build is given --fonts-dir.',
          'items': obj(
            {
              'ref': {
                'type': 'string',
                'description': 'The element font: Family, gf:Family or rf:…',
              },
              'path': string,
            },
            required: ['ref'],
          ),
        },
        'output': obj({'name': string, 'dir': string}),
      },
      required: ['specVersion', 'meta', 'wallpaper', 'icons'],
    ),
    '\$defs': {
      'color': {
        'description': '"#RRGGBB", "#AARRGGBB" or an ARGB integer.',
        'oneOf': [
          {
            'type': 'string',
            'pattern': r'^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$',
          },
          {'type': 'integer', 'minimum': 0, 'maximum': 4294967295},
        ],
      },
      'alignment': {
        'description': 'A name such as "Alignment.center" or [x, y] in -1..1.',
        'oneOf': [
          {'enum': _alignmentNames},
          {'type': 'array', 'items': number, 'minItems': 2, 'maxItems': 2},
        ],
      },
      'element': _elementSchema(),
    },
  };
}

const _alignmentNames = [
  'Alignment.topLeft',
  'Alignment.topCenter',
  'Alignment.topRight',
  'Alignment.centerLeft',
  'Alignment.center',
  'Alignment.centerRight',
  'Alignment.bottomLeft',
  'Alignment.bottomCenter',
  'Alignment.bottomRight',
];

Map<String, Object?> _elementSchema() {
  // The element's own fields, with their kinds read off a default instance.
  final defaults = const LockElementSpec(type: ElementType.hourClock).toJson();
  final props = <String, Object?>{};
  for (final entry in defaults.entries) {
    final key = entry.key;
    final value = entry.value;
    props[key] = switch (key) {
      'type' => {
        // Health types are left out: Mi Health data doesn't load on devices.
        'enum': [
          for (final t in ElementType.values)
            if (!t.isHealth) t.name,
        ],
      },
      'fontWeight' => {
        'description': '"FontWeight.w700" or 700.',
        'oneOf': [
          {'type': 'string', 'pattern': r'^FontWeight\.w[1-9]00$'},
          {'type': 'integer', 'minimum': 100, 'maximum': 900},
        ],
      },
      'animations' => {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'type': {
              'enum': [for (final a in ElementAnimation.values) a.name],
            },
            'duration': {'type': 'integer'},
            'amount': {'type': 'number'},
            'offsetY': {'type': 'number'},
            'loop': {'type': 'boolean'},
            'ease': {
              'enum': [for (final e in MamlEase.values) e.name],
            },
            'startX': {
              'type': ['number', 'null'],
            },
            'startY': {
              'type': ['number', 'null'],
            },
          },
          'required': ['type'],
          'additionalProperties': false,
        },
      },
      _ when LockscreenSpec.enumKeys.containsKey(key) => {
        'enum': [
          for (final v in LockscreenSpec.enumKeys[key]!)
            if (v != ArcProgressSource.steps) v.name,
        ],
      },
      _ when LockscreenSpec.colorKeys.contains(key) => {
        '\$ref': '#/\$defs/color',
      },
      _ when LockscreenSpec.alignKeys.contains(key) => {
        '\$ref': '#/\$defs/alignment',
      },
      _ => switch (value) {
        String() => {'type': 'string'},
        bool() => {'type': 'boolean'},
        num() => {'type': 'number'},
        null => {
          'type': ['number', 'null'],
        },
        _ => <String, Object?>{},
      },
    };
  }
  return {
    'type': 'object',
    'description':
        'One lockscreen element. Only "type" is required; every other field '
        'has a default.',
    'properties': props,
    'required': ['type'],
    'additionalProperties': false,
  };
}
