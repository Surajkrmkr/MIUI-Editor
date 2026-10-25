import 'package:xml/xml.dart';

import '../values/alignment2.dart';
import '../values/rgba.dart';
import 'analog.dart';
import 'calendar_layout.dart';
import 'element_enums.dart';
import 'geometry.dart';
import 'lock_element_spec.dart';
import 'shortcut_app.dart';
import 'shortcut_layout.dart';
import 'unlock_skin_layout.dart';

/// Builds the lockscreen MAML `manifest.xml` for a list of elements.
class ManifestBuilder {
  const ManifestBuilder();

  /// Builds the live MAML document for the current lockscreen elements.
  XmlDocument build(List<LockElementSpec> elements, {double bgAlpha = 0}) {
    final doc = XmlDocument.parse(_baseManifest);

    final hasVideo = elements.any((e) => e.type == ElementType.videoWallpaper);
    if (hasVideo) {
      // Remove Wallpaper tag when video wallpaper is active
      for (final node in doc.findAllElements('Wallpaper').toList()) {
        node.parent?.children.remove(node);
      }
    } else {
      // Remove Video and ExternalCommands when no video wallpaper
      for (final node in doc.findAllElements('Video').toList()) {
        node.parent?.children.remove(node);
      }
      for (final node in doc.findAllElements('ExternalCommands').toList()) {
        node.parent?.children.remove(node);
      }
    }

    if (elements.any(
      (element) =>
          element.isVisible &&
          (element.type.isHealth ||
              (element.type == ElementType.arcShape &&
                  element.effectiveProgressSource == ArcProgressSource.steps)),
    )) {
      final binders = doc.findAllElements('VariableBinders').single;
      final binder = XmlElement(XmlName('ContentProviderBinder'), [
        XmlAttribute(XmlName('name'), 'MiSteps'),
        XmlAttribute(
          XmlName('uri'),
          'content://com.mi.health.provider.main/activity/steps/brief',
        ),
        // `column`, as Xiaomi's MiSteps sample: the provider is queried with
        // no projection, which is what it expects.
        XmlAttribute(
          XmlName('column'),
          'steps,goal,distance,energy,strength_duration,summary',
        ),
        XmlAttribute(XmlName('countName'), 'hasSteps'),
      ]);
      for (final column in [
        'steps',
        'goal',
        'distance',
        'energy',
        'strength_duration',
        'summary',
      ]) {
        binder.children.add(
          XmlElement(XmlName('Variable'), [
            XmlAttribute(XmlName('name'), 'MiSteps_$column'),
            XmlAttribute(XmlName('type'), 'string'),
            XmlAttribute(XmlName('column'), column),
          ]),
        );
      }
      binders.children.add(binder);
      // Re-query while the lockscreen is shown: Mi Health often answers
      // after init, which would otherwise leave the values empty.
      binders.parent!.children.insert(
        binders.parent!.children.indexOf(binders) + 1,
        XmlElement(
          XmlName('Var'),
          [
            XmlAttribute(XmlName('name'), 'MiSteps_poll'),
            XmlAttribute(XmlName('expression'), '#second'),
            XmlAttribute(XmlName('threshold'), '10'),
          ],
          [
            XmlElement(XmlName('Trigger'), [], [
              XmlElement(XmlName('BinderCommand'), [
                XmlAttribute(XmlName('name'), 'MiSteps'),
                XmlAttribute(XmlName('command'), 'refresh'),
              ]),
            ]),
          ],
        ),
      );
      final external =
          doc.findAllElements('ExternalCommands').firstOrNull ??
          XmlElement(XmlName('ExternalCommands'));
      if (external.parent == null) doc.rootElement.children.add(external);
      for (final action in ['init', 'resume']) {
        final trigger =
            external
                .findElements('Trigger')
                .where((element) => element.getAttribute('action') == action)
                .firstOrNull ??
            XmlElement(XmlName('Trigger'), [
              XmlAttribute(XmlName('action'), action),
            ]);
        if (trigger.parent == null) external.children.add(trigger);
        trigger.children.add(
          XmlElement(XmlName('BinderCommand'), [
            XmlAttribute(XmlName('name'), 'MiSteps'),
            XmlAttribute(XmlName('command'), 'refresh'),
          ]),
        );
      }
    }

    // bg alpha
    doc
            .findAllElements('Group')
            .firstWhere((e) => e.getAttribute('name') == 'bgAlpha')
            .innerXml =
        '<Rectangle width="#sw" alpha="${(bgAlpha * 255).toStringAsFixed(0)}"'
        ' height="#sh" fillColor="#ff000000"/>';

    final visibleElements = elements
        .where((element) => element.isVisible)
        .toList();
    for (final el in [
      ...visibleElements.where(
        (element) => element.type == ElementType.swipeUpUnlock,
      ),
      ...visibleElements.where(
        (element) => element.type != ElementType.swipeUpUnlock,
      ),
    ]) {
      final xml = _xmlFor(el);
      if (xml == null) continue;
      if (el.type.isMusic) {
        final mc = doc
            .findAllElements('MusicControl')
            .firstWhere((e) => e.getAttribute('name') == 'music_control');
        final group = XmlElement(XmlName('Group'), [
          XmlAttribute(XmlName('name'), el.type.name),
        ])..innerXml = xml;
        _addAnimation(group, el);
        mc.children.add(group);
      } else {
        final group =
            doc
                .findAllElements('Group')
                .where((element) => element.getAttribute('name') == el.name)
                .firstOrNull ??
            XmlElement(XmlName('Group'), [
              XmlAttribute(XmlName('name'), el.name),
            ]);
        group.innerXml = xml;
        _addAnimation(group, el);
        group.parent?.children.remove(group);
        doc.rootElement.children.add(group);
      }
    }
    _addOneShotTriggers(doc, elements);
    if (elements.any(
      (element) =>
          element.isVisible &&
          (element.type.isWeatherText ||
              element.type == ElementType.weatherIconClock),
    )) {
      final external =
          doc.findAllElements('ExternalCommands').firstOrNull ??
          XmlElement(XmlName('ExternalCommands'));
      if (external.parent == null) doc.rootElement.children.add(external);
      for (final action in ['init', 'resume']) {
        final trigger =
            external
                .findElements('Trigger')
                .where((trigger) => trigger.getAttribute('action') == action)
                .firstOrNull ??
            XmlElement(XmlName('Trigger'), [
              XmlAttribute(XmlName('action'), action),
            ]);
        if (trigger.parent == null) external.children.add(trigger);
        trigger.children.add(
          XmlElement(XmlName('BinderCommand'), [
            XmlAttribute(XmlName('name'), 'WeatherService'),
            XmlAttribute(XmlName('command'), 'refresh'),
          ]),
        );
      }
    }
    return doc;
  }

  void _addOneShotTriggers(XmlDocument doc, List<LockElementSpec> elements) {
    final targets = <String>{};
    for (final element in elements.where((element) => element.isVisible)) {
      final oneShots = element.activeAnimations
          .where((track) => !track.loop)
          .toList();
      if (oneShots.isEmpty) continue;
      final group = doc
          .findAllElements('Group')
          .where((group) => group.getAttribute('name') == element.name)
          .firstOrNull;
      if (group == null) continue;
      for (final track in oneShots) {
        for (final target
            in track.type == ElementAnimation.size
                ? _sizeAnimationTargets(group, element)
                : [group]) {
          final name = target.getAttribute('name') ?? '${element.name}_size';
          target.setAttribute('name', name);
          targets.add(name);
        }
      }
    }
    if (targets.isEmpty) return;
    final external =
        doc.findAllElements('ExternalCommands').firstOrNull ??
        XmlElement(XmlName('ExternalCommands'));
    if (external.parent == null) doc.rootElement.children.add(external);
    for (final action in ['init', 'resume']) {
      final trigger =
          external
              .findElements('Trigger')
              .where((trigger) => trigger.getAttribute('action') == action)
              .firstOrNull ??
          XmlElement(XmlName('Trigger'), [
            XmlAttribute(XmlName('action'), action),
          ]);
      if (trigger.parent == null) external.children.add(trigger);
      for (final target in targets) {
        trigger.children.add(
          XmlElement(XmlName('AnimationCommand'), [
            XmlAttribute(XmlName('target'), target),
            XmlAttribute(XmlName('command'), 'play'),
          ]),
        );
      }
    }
  }

  void _addAnimation(XmlElement group, LockElementSpec element) {
    if (element.type == ElementType.weatherIconClock) {
      group.setAttribute('x', '#sw/2+${element.dx * 3.9}');
      group.setAttribute('y', '#sh/2+${element.dy * 3.9}');
      group.setAttribute('pivotX', '0');
      group.setAttribute('pivotY', '0');
      group.setAttribute('angle', '${360 - element.angle}');
      group.setAttribute('scale', '${element.scale}');
    } else if (element.activeAnimations.any(
      (track) =>
          track.type == ElementAnimation.rotation ||
          track.type == ElementAnimation.scale,
    )) {
      final pivotX = '#sw/2+${element.dx * 3.9}';
      final pivotY = '#sh/2+${element.dy * 3.9}';
      final content = XmlElement(XmlName('Group'), [
        XmlAttribute(XmlName('name'), '${element.name}_animation_content'),
        XmlAttribute(XmlName('x'), '-($pivotX)'),
        XmlAttribute(XmlName('y'), '-($pivotY)'),
      ]);
      final children = group.children.toList();
      group.children.clear();
      content.children.addAll(children);
      group.children.add(content);
      group.setAttribute('x', pivotX);
      group.setAttribute('y', pivotY);
      group.setAttribute('pivotX', '0');
      group.setAttribute('pivotY', '0');
    }
    for (final track in element.activeAnimations) {
      _addAnimationTrack(group, element, track);
    }
  }

  XmlElement _sizeAnimationTarget(XmlElement group) {
    final child = group.children.whereType<XmlElement>().first;
    return child.getAttribute('name')?.endsWith('_animation_content') == true
        ? child.children.whereType<XmlElement>().first
        : child;
  }

  List<XmlElement> _sizeAnimationTargets(
    XmlElement group,
    LockElementSpec element,
  ) => element.type == ElementType.arcShape
      ? group.findAllElements('Arc').toList()
      : [_sizeAnimationTarget(group)];

  void _addAnimationTrack(
    XmlElement group,
    LockElementSpec element,
    ElementAnimationTrack track,
  ) {
    final duration = track.duration.clamp(100, 60000);
    final amount = track.amount;
    final node = switch (track.type) {
      ElementAnimation.position => 'PositionAnimation',
      ElementAnimation.rotation => 'RotationAnimation',
      ElementAnimation.alpha => 'AlphaAnimation',
      ElementAnimation.scale => 'ScaleAnimation',
      ElementAnimation.size => 'SizeAnimation',
      ElementAnimation.none => '',
    };
    XmlElement target = group;
    if (track.type == ElementAnimation.size) {
      target = _sizeAnimationTargets(group, element).first;
    }
    final animation = XmlElement(XmlName(node), [
      XmlAttribute(XmlName('loop'), '${track.loop}'),
      if (!track.loop) XmlAttribute(XmlName('initPause'), 'true'),
    ]);
    final frames = track.hasCustomStart
        ? [(0, 0.0), (duration, 1.0)]
        : [(0, 0.0), (duration ~/ 2, 1.0), (duration, 0.0)];
    for (final (time, progress) in frames) {
      final attributes = switch (track.type) {
        ElementAnimation.position => {
          'x':
              '${track.hasCustomStart ? (track.startX! - element.dx) * 3.9 * (1 - progress) : amount * progress}',
          'y':
              '${track.hasCustomStart ? (track.startY! - element.dy) * 3.9 * (1 - progress) : track.offsetY * progress}',
        },
        ElementAnimation.rotation => {'value': '${amount * progress}'},
        ElementAnimation.alpha => {
          'value': '${255 + (amount.clamp(0, 255) - 255) * progress}',
        },
        ElementAnimation.scale => {
          'value': '${1 + (amount.clamp(0.1, 4) - 1) * progress}',
        },
        ElementAnimation.size => {
          'w':
              '${element.width * element.scale * (1 + (amount.clamp(0.1, 4) - 1) * progress)}',
          'h':
              '${(element.type == ElementType.arcShape ? element.width : element.height) * element.scale * (1 + (amount.clamp(0.1, 4) - 1) * progress)}',
        },
        ElementAnimation.none => <String, String>{},
      };
      animation.children.add(
        XmlElement(XmlName('Item'), [
          XmlAttribute(XmlName('time'), '$time'),
          XmlAttribute(XmlName('easeType'), track.ease.mamlName),
          for (final entry in attributes.entries)
            XmlAttribute(XmlName(entry.key), entry.value),
        ]),
      );
    }
    target.children.add(animation);
    if (track.type == ElementAnimation.size) {
      for (final other in _sizeAnimationTargets(group, element).skip(1)) {
        other.children.add(animation.copy());
      }
    }
  }

  String? _xmlFor(LockElementSpec el) {
    // ── Static clock XMLs ──────────────────────────────────────────────────
    switch (el.type) {
      case ElementType.hourClock:
        return "<Image name='hour' srcExp=\"'hour/hour_'+ int((#hour12)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.minClock:
        return "<Image name='min' srcExp=\"'min/min_'+ int((#minute)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.secClock:
        return "<Image name='sec' srcExp=\"'sec/sec_'+ int((#second)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.dotClock:
        return "<Image name='dot' srcExp=\"'dot/dot.png'\" width='#sw' height='#sh'/>";
      case ElementType.dotClock2:
        return "<Image name='dot' srcExp=\"'dot/dot2.png'\" width='#sw' height='#sh'/>";
      case ElementType.weekClock:
        return "<Image name='week' srcExp=\"'week/week_'+ int((#day_of_week-1)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.monthClock:
        return "<Image name='month' srcExp=\"'month/month_'+ int((#month+1)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.dateClock:
        return "<Image name='date' srcExp=\"'date/date_'+ int((#date)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.amPmClock:
        return "<Image name='ampm' srcExp=\"'ampm/ampm_'+ int((#ampm)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.weatherIconClock:
        return "<Image name='weatherIcon' srcExp=\"'weather/weather_'+ #w_outID +'.png'\" x='0' y='0' w='156' h='156' align='center' alignV='center'/>";
      case ElementType.swipeUpUnlock:
        return "<Unlocker name='unlocker' visibility='not(#unlocker_v)'>"
            "<StartPoint x='0' y='0' w='#sw' h='#sh' easeType='BounceEaseOut' easeTime='400'/>"
            "<EndPoint x='0' y='-#sh' w='#sw' h='#sh - 400'>"
            "<Path x='0' y='0' tolerance='2000'>"
            "<Position x='0' y='0'/><Position x='0' y='-#sh'/>"
            "</Path></EndPoint></Unlocker>";
      case ElementType.tapToUnlock:
      case ElementType.slideToUnlock:
      default:
        return _dynamicXml(el);
    }
  }

  String? _dynamicXml(LockElementSpec el) {
    const ratio = 3.9;
    if (el.type == ElementType.shortcutSet) return _shortcutSetXml(el, ratio);
    if (el.type == ElementType.flashlightIcon) {
      return _flashlightXml(
        el,
        (el.width * el.scale).toStringAsFixed(2),
        (el.height * el.scale).toStringAsFixed(2),
        (el.dx * ratio).toStringAsFixed(2),
        (el.dy * ratio).toStringAsFixed(2),
        (360 - el.angle).toStringAsFixed(2),
      );
    }
    if (el.type.isAnalog) {
      final s = el.width * el.scale;
      final x = '#sw/2+${(el.dx * ratio).toStringAsFixed(2)}-${s / 2}';
      final y = '#sh/2+${(el.dy * ratio).toStringAsFixed(2)}-${s / 2}';
      final base = (360 - el.angle) % 360;
      return [
        for (final part in analogPartsOfSpec(el))
          "<Image name='${el.name}${analogPartSuffix(el, part)}' src='analog/${el.name}${analogPartSuffix(el, part)}.png' x='$x' y='$y' w='$s' h='$s'"
              " pivotX='${s / 2}' pivotY='${s / 2}' antiAlias='true'"
              " angle='${part.angleExpression == null ? base : '${part.angleExpression}+$base'}'/>",
        if (el.type == ElementType.analogClock &&
            el.analogStyle == AnalogStyle.orbitDigital)
          _orbitDigitalXml(el, s, ratio),
      ].join();
    }
    final w = (el.width * el.scale).toStringAsFixed(2);
    final h = (el.height * el.scale).toStringAsFixed(2);
    final dx = (el.dx * ratio).toStringAsFixed(2);
    final dy = (el.dy * ratio).toStringAsFixed(2);
    final ang = (360 - el.angle).toStringAsFixed(2);
    final c = el.color.toHex(withAlpha: true);
    final c2 = el.colorSecondary.toHex(withAlpha: true);
    final sz = (el.fontSize * ratio).toStringAsFixed(2);
    final bold = '${el.isBold}';

    String alignStr = 'center';
    String dxAdj = dx;
    if (el.align == Alignment2.centerLeft) {
      alignStr = 'left';
      dxAdj = '$dx-#sw/2';
    }
    if (el.align == Alignment2.centerRight) {
      alignStr = 'right';
      dxAdj = '$dx+#sw/2';
    }

    if (el.type.isContainer) {
      return "<Image name='containerBG' srcExp=\"'container/${el.name}.png'\" width='#sw' height='#sh'/>";
    }
    if (el.type.isShape) {
      final tag = switch (el.type) {
        ElementType.rectangleShape => 'Rectangle',
        ElementType.circleShape => 'Circle',
        ElementType.ellipseShape => 'Ellipse',
        ElementType.lineShape => 'Line',
        _ => 'Arc',
      };
      final shape = XmlElement(XmlName(tag), [
        XmlAttribute(
          XmlName('x'),
          el.type == ElementType.lineShape ? '#sw/2+$dx-$w/2' : '#sw/2+$dx',
        ),
        XmlAttribute(XmlName('y'), '#sh/2+$dy'),
        if (el.type == ElementType.rectangleShape) ...[
          XmlAttribute(XmlName('align'), 'center'),
          XmlAttribute(XmlName('alignV'), 'center'),
        ],
        XmlAttribute(XmlName('w'), w),
        XmlAttribute(XmlName('h'), h),
        XmlAttribute(XmlName('angle'), ang),
        XmlAttribute(XmlName('strokeColor'), c),
        XmlAttribute(
          XmlName('fillColor'),
          el.type == ElementType.arcShape ? '#00000000' : c2,
        ),
        XmlAttribute(XmlName('weight'), '${el.shapeStrokeWidth * el.scale}'),
        XmlAttribute(XmlName('cap'), 'round'),
        if (el.type == ElementType.rectangleShape)
          XmlAttribute(XmlName('cornerRadius'), '${el.radius * el.scale}'),
        if (el.type == ElementType.circleShape)
          XmlAttribute(XmlName('r'), '${el.width * el.scale / 2}'),
        if (el.type == ElementType.lineShape) ...[
          XmlAttribute(XmlName('pivotX'), '${el.width * el.scale / 2}'),
          XmlAttribute(XmlName('pivotY'), '0'),
          XmlAttribute(XmlName('x1'), '#sw/2+$dx+$w/2'),
          XmlAttribute(XmlName('y1'), '#sh/2+$dy'),
        ],
        if (el.type == ElementType.arcShape) ...[
          XmlAttribute(XmlName('startAngle'), '${el.startAngle}'),
          XmlAttribute(
            XmlName('sweep'),
            switch (el.effectiveProgressSource.mamlFraction) {
              null => '${el.sweepAngle}',
              final fraction => '${el.sweepAngle}*$fraction',
            },
          ),
          XmlAttribute(XmlName('close'), 'false'),
        ],
      ]);
      if (el.type == ElementType.arcShape) {
        shape.setAttribute('h', w);
        shape.setAttribute('name', '${el.name}_progress');
        final track = XmlElement(XmlName('Arc'), [
          for (final attribute in shape.attributes)
            XmlAttribute(XmlName(attribute.name.local), attribute.value),
        ]);
        track.setAttribute('name', '${el.name}_track');
        track.setAttribute(
          'strokeColor',
          el.arcTrackColor.toHex(withAlpha: true),
        );
        track.setAttribute('sweep', '${el.sweepAngle}');
        return XmlElement(XmlName('Group'), [], [track, shape]).toXmlString();
      }
      if (el.type == ElementType.rectangleShape &&
          el.effectiveProgressSource.mamlFraction != null) {
        shape
          ..setAttribute('name', '${el.name}_track')
          ..setAttribute('fillColor', el.arcTrackColor.toHex(withAlpha: true))
          ..setAttribute('weight', '0');
        final progress = XmlElement(XmlName('Rectangle'), [
          XmlAttribute(XmlName('name'), '${el.name}_progress'),
          XmlAttribute(XmlName('x'), '#sw/2+$dx-$w/2'),
          XmlAttribute(XmlName('y'), '#sh/2+$dy'),
          XmlAttribute(XmlName('alignV'), 'center'),
          XmlAttribute(
            XmlName('w'),
            '$w*${el.effectiveProgressSource.mamlFraction}',
          ),
          XmlAttribute(XmlName('h'), h),
          XmlAttribute(XmlName('fillColor'), c),
          XmlAttribute(XmlName('cornerRadius'), '${el.radius * el.scale}'),
        ]);
        return XmlElement(XmlName('Group'), [], [
          shape,
          progress,
        ]).toXmlString();
      }
      return shape.toXmlString();
    }
    if (el.type == ElementType.depthLayer) {
      final src = 'depth/${el.name}.png';
      // Cut from bg.png: stretched to the screen like the bgLock image.
      if (el.path == 'bg.png') {
        return "<Image name='${el.name}' src='$src' x='0' y='0' w='#sw' h='#sh'/>";
      }
      // Cut from the wallpaper: cover-fit like it; width/height are its pixels.
      final bw = el.width.toStringAsFixed(0);
      final bh = el.height.toStringAsFixed(0);
      final s = 'max(#sw/$bw,#sh/$bh)';
      return "<Image name='${el.name}' src='$src'"
          " x='(#sw-$bw*$s)/2' y='(#sh-$bh*$s)/2' w='$bw*$s' h='$bh*$s'/>";
    }
    if (el.type == ElementType.batteryText ||
        el.type == ElementType.batteryLevel ||
        el.type.isHealth) {
      var expression = el.type.isHealth
          ? "ifelse(strIsEmpty(@MiSteps_${el.type.healthColumn}),'--',@MiSteps_${el.type.healthColumn})"
          : "#battery_level+'%'";
      if (el.type == ElementType.stepsDistance) expression += "+' km'";
      if (el.type == ElementType.stepsCalories) expression += "+' kcal'";
      if (el.type == ElementType.stepsDuration) expression += "+' min'";
      if (el.type == ElementType.stepsSummary) {
        expression =
            "ifelse(strIsEmpty(@MiSteps_summary),'--',eqs(@MiSteps_summary,'0'),'No data',eqs(@MiSteps_summary,'1'),'Below goal',eqs(@MiSteps_summary,'2'),'Low activity',eqs(@MiSteps_summary,'3'),'Goal reached','--')";
      }
      return XmlElement(XmlName('Text'), [
        XmlAttribute(XmlName('x'), '#sw/2+$dxAdj'),
        XmlAttribute(XmlName('y'), '#sh/2+$dy'),
        XmlAttribute(XmlName('align'), alignStr),
        XmlAttribute(XmlName('alignV'), 'center'),
        XmlAttribute(XmlName('angle'), ang),
        XmlAttribute(XmlName('size'), sz),
        XmlAttribute(XmlName('color'), c),
        XmlAttribute(XmlName('bold'), bold),
        XmlAttribute(XmlName('textExp'), expression),
      ]).toXmlString();
    }
    if (el.type.isPng) {
      return "<Image name='pngBG' srcExp=\"'png/${el.name}.png'\" width='#sw' height='#sh'/>";
    }

    if (el.type.isDateTime) {
      return XmlElement(XmlName('DateTime'), [
        XmlAttribute(XmlName('angle'), ang),
        XmlAttribute(XmlName('x'), '#sw/2+$dxAdj'),
        XmlAttribute(XmlName('y'), '#sh/2+$dy'),
        XmlAttribute(XmlName('align'), alignStr),
        XmlAttribute(XmlName('alignV'), 'center'),
        XmlAttribute(XmlName('size'), sz),
        XmlAttribute(XmlName('color'), c),
        XmlAttribute(XmlName('format'), el.text),
        XmlAttribute(XmlName('bold'), bold),
      ]).toXmlString();
    }

    if (el.type.isNormalText) {
      final escaped = el.text
          .replaceAll("'", "''")
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      return "<Text angle='$ang' x='#sw/2+$dxAdj' y='#sh/2+$dy'"
          " align='$alignStr' alignV='center' size='$sz' color='$c'"
          " textExp=\"'$escaped'\" bold='$bold'/>";
    }

    if (el.type.isWeatherText) {
      final expression = switch (el.type) {
        ElementType.weatherTemp => "#weather_temperature+'°C'",
        ElementType.weatherDesc => '@weather_description',
        ElementType.weatherCity => '@weather_location',
        ElementType.weatherTemperatureRange => '@weather_temperature_range',
        ElementType.weatherAqi => "'AQI '+#weather_aqi",
        _ => "#weather_humidity+'%'",
      };
      return XmlElement(XmlName('Text'), [
        XmlAttribute(XmlName('angle'), ang),
        XmlAttribute(XmlName('x'), '#sw/2+$dxAdj'),
        XmlAttribute(XmlName('y'), '#sh/2+$dy'),
        XmlAttribute(XmlName('align'), alignStr),
        XmlAttribute(XmlName('alignV'), 'center'),
        XmlAttribute(XmlName('size'), sz),
        XmlAttribute(XmlName('color'), c),
        XmlAttribute(XmlName('bold'), bold),
        XmlAttribute(XmlName('visibility'), '#hasweather'),
        XmlAttribute(XmlName('textExp'), expression),
      ]).toXmlString();
    }

    if (el.type == ElementType.calendarGrid &&
        el.calendarStyle != CalendarStyle.classic) {
      return _styledCalendarXml(el, dx, dy, ang, sz, bold);
    }

    if (el.type == ElementType.calendarGrid) {
      final cellWidth = el.width / 7;
      final cellHeight = el.height / el.calendarDisplayRows;
      final headerRows = el.calendarDisplayRows - el.calendarWeekRows;
      final fullMonth = el.calendarWeekRows == 6;
      final day = fullMonth
          ? '(#__calendar_i-#calendar_first+1)'
          : '(#date-(#day_of_week-1)+#__calendar_i)';
      final visible = fullMonth ? 'ge($day,1)*le($day,#calendar_days)' : '1';
      return "<Group x='#sw/2+$dx' y='#sh/2+$dy' angle='$ang' scale='${el.scale}'>"
          "<Group x='-${el.width / 2}' y='-${el.height / 2}'>"
          "<Var name='calendar_first' expression='(#day_of_week-1-(#date-1)%7+7)%7'/>"
          "<Var name='calendar_leap' expression='eq(#year%4,0)*ne(#year%100,0)+eq(#year%400,0)'/>"
          "<Var name='calendar_days' expression='ifelse(eq(#month,1),28+#calendar_leap,eq(#month,3)+eq(#month,5)+eq(#month,8)+eq(#month,10),30,31)'/>"
          '${el.calendarShowMonth ? "<DateTime format='MMMM yyyy' x='${el.width / 2}' y='${cellHeight / 2}' align='center' alignV='center' size='$sz' color='$c' bold='$bold'/>" : ""}'
          '${el.calendarShowWeekdays ? "<Array count=\"7\" indexName=\"__calendar_week\"><Text textExp=\"substr(\u0027SMTWTFS\u0027,#__calendar_week,1)\" x=\"(#__calendar_week+0.5)*$cellWidth\" y=\"${cellHeight * (el.calendarShowMonth ? 1.5 : .5)}\" align=\"center\" alignV=\"center\" size=\"$sz\" color=\"$c\" bold=\"$bold\"/></Array>" : ""}'
          "<Array count='${el.calendarWeekRows * 7}' indexName='__calendar_i'>"
          "<Rectangle x='(#__calendar_i%7)*$cellWidth' y='(int(#__calendar_i/7)+$headerRows)*$cellHeight' w='$cellWidth' h='$cellHeight' cornerRadius='${el.radius * ratio}' fillColor='$c2' visibility='$visible*eq($day,#date)'/>"
          "<DateTime format='d' value='#time_sys+($day-#date)*86400000' x='(#__calendar_i%7+0.5)*$cellWidth' y='(int(#__calendar_i/7)+${headerRows + .5})*$cellHeight' align='center' alignV='center' size='$sz' color='$c' bold='$bold' visibility='$visible'/>"
          "</Array></Group></Group>";
    }

    if (el.type == ElementType.notification) {
      final limit = el.notificationLimit.clamp(1, 10);
      final listHeight = 206 * limit;
      final listX = el.align == Alignment2.centerLeft
          ? '0'
          : el.align == Alignment2.centerRight
          ? '-1024'
          : '-512';
      return "<Group x='#sw/2+$dxAdj' y='#sh/2+$dy' angle='$ang' scale='${el.scale}'>"
          "<List name='notification_list' x='$listX' y='-${listHeight / 2}' w='1024'"
          " maxHeight='$listHeight' data='icon:bitmap,title:string,content:string,time:string,info:string,subtext:string,key:int'"
          " visibility='#hasnotifications'>"
          "<Item x='0' y='0' w='1024' h='206'>"
          "<Button name='notice_open' x='0' y='0' w='916' h='186'>"
          "<Normal><Rectangle x='0' w='1024' h='186' fillColor='$c2' cornerRadius='${el.radius * ratio}'/></Normal>"
          "<Triggers><Trigger action='up'>"
          "<IntentCommand action='com.miui.app.ExtraStatusBarManager.action_remove_keyguard_notification' broadcast='true'>"
          "<Extra name='com.miui.app.ExtraStatusBarManager.extra_notification_key' type='int' expression='#notification_list.key'/>"
          "<Extra name='com.miui.app.ExtraStatusBarManager.extra_notification_click' type='int' expression='1'/>"
          "</IntentCommand></Trigger></Triggers>"
          "</Button>"
          "<Image name='notice_icon' x='36' y='32' w='96' h='96'/>"
          "<Text x='156' y='54' w='500' alignV='center' size='44' color='$c'"
          " name='notice_title' bold='$bold'/>"
          "<Text x='156' y='100' w='740' size='34' color='$c'"
          " name='notice_content' bold='$bold'/>"
          "<Text x='900' y='54' w='220' align='right' alignV='center' size='28' color='$c'"
          " name='notice_time' bold='$bold'/>"
          "<Button name='notice_close' x='920' y='28' w='80' h='80' alignChildren='true'><Normal>"
          "<Line x='20' y='20' x1='60' y1='60' strokeColor='$c' weight='5' cap='round'/>"
          "<Line x='20' y='60' x1='60' y1='20' strokeColor='$c' weight='5' cap='round'/>"
          "</Normal><Triggers><Trigger action='up'>"
          "<IntentCommand action='com.miui.app.ExtraStatusBarManager.action_remove_keyguard_notification' broadcast='true'>"
          "<Extra name='com.miui.app.ExtraStatusBarManager.extra_notification_key' type='int' expression='#notification_list.key'/>"
          "<Extra name='com.miui.app.ExtraStatusBarManager.extra_notification_click' type='int' expression='0'/>"
          "</IntentCommand><BinderCommand name='data' command='refresh'/>"
          "</Trigger></Triggers></Button>"
          "</Item><AttrDataBinders>"
          "<AttrDataBinder target='notice_icon' attr='bitmap' data='icon'/>"
          "<AttrDataBinder target='notice_title' attr='text' data='title'/>"
          "<AttrDataBinder target='notice_content' attr='text' data='content'/>"
          "<AttrDataBinder target='notice_time' attr='text' data='time'/>"
          "</AttrDataBinders></List></Group>";
    }

    if (el.type.isUnlockControl && el.unlockSkin != UnlockSkin.classic) {
      return _skinnedUnlockXml(el, dxAdj, dy, ang);
    }

    if (el.type == ElementType.tapToUnlock) {
      final width = el.width * el.scale;
      final height = el.height * el.scale;
      final left = el.align == Alignment2.centerLeft
          ? 0
          : el.align == Alignment2.centerRight
          ? -width
          : -width / 2;
      final glyph =
          "<Rectangle w='$w' h='$h' cornerRadius='${el.effectiveUnlockCornerRadius * el.scale}' fillColor='$c2' alpha='${(el.unlockBackgroundOpacity.clamp(0, 1) * 255).round()}'/>"
          '${_unlockIconXml(el, width, height)}';
      final label = _unlockTextXml(el, width, height);
      return "<Group x='#sw/2+$dxAdj' y='#sh/2+$dy' angle='$ang'>"
          "<Button name='tap_unlock_button' x='$left' y='${-height / 2}' w='$w' h='$h' alignChildren='true' haptic='true'>"
          "<Normal>$glyph$label</Normal><Pressed><Group alpha='160'>$glyph$label</Group></Pressed>"
          "<Triggers><Trigger action='up'><ExternCommand command='unlock'/></Trigger></Triggers>"
          "</Button></Group>";
    }

    if (el.type == ElementType.slideToUnlock ||
        el.type == ElementType.dragToUnlock) {
      final drag = el.type == ElementType.dragToUnlock;
      final unlockerName = drag ? 'drag_unlocker' : 'slide_unlocker';
      final width = el.width * el.scale;
      final height =
          (el.height < el.width / 3 ? el.height : el.width / 3) * el.scale;
      final travel = width - height;
      final left = el.align == Alignment2.centerLeft
          ? 0
          : el.align == Alignment2.centerRight
          ? -width
          : -width / 2;
      final thumb =
          (drag
              ? "<Rectangle x='${height * .12}' y='0' w='${height * .76}' h='$height' cornerRadius='${height * .12}' fillColor='$c2' alpha='${(el.unlockThumbOpacity.clamp(0, 1) * 255).round()}'/>"
              : "<Circle x='${height / 2}' y='${height / 2}' r='${height * .42}' fillColor='$c2' alpha='${(el.unlockThumbOpacity.clamp(0, 1) * 255).round()}'/>") +
          _unlockIconXml(el, height, height);
      final cable = drag
          ? "<Line name='drag_cable' x='#$unlockerName.move_x+${height / 2}' y='${height / 2}' x1='${width - height / 2}' y1='${height / 2}' strokeColor='$c2' weight='${height * .06}' cap='round'/>"
                "<Circle name='drag_target' x='${width - height / 2}' y='${height / 2}' r='${height * .36}' strokeColor='$c2' weight='${height * .06}' fillColor='#00000000'/>"
          : '';
      return "<Group x='#sw/2+$dxAdj' y='#sh/2+$dy' angle='$ang'>"
          "<Group x='$left' y='${-height / 2}'>"
          "<Rectangle w='$width' h='$height' cornerRadius='${el.effectiveUnlockCornerRadius * el.scale}' fillColor='$c2' alpha='${(el.unlockBackgroundOpacity.clamp(0, 1) * 255).round()}'/>"
          '$cable'
          '${_unlockTextXml(el, width, height)}'
          "<Unlocker name='$unlockerName' alwaysShow='true' bounceAcceleration='4000' bounceInitSpeed='80'>"
          "<StartPoint x='0' y='0' w='$height' h='$height' anchorX='0' anchorY='0' alignChildren='true'>"
          "<NormalState>$thumb</NormalState><PressedState>$thumb</PressedState>"
          '${drag ? "<ReachedState>$thumb</ReachedState>" : ""}'
          "</StartPoint><EndPoint x='$travel' y='0' w='$height' h='$height' align='center' alignV='center'>"
          "<Path x='0' y='0' tolerance='1080'>"
          "<Position x='0' y='0'/><Position x='$travel' y='0'/>"
          "</Path></EndPoint></Unlocker></Group></Group>";
    }

    if (el.type.isMusic) return _musicXml(el, w, h, dx, dy, ang);
    if (el.type.isIcon) return _iconXml(el, w, h, dx, dy, ang);
    return null;
  }

  String _flashlightXml(
    LockElementSpec el,
    String w,
    String h,
    String dx,
    String dy,
    String ang,
  ) =>
      "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
      "<Image src='icon/flashlight.png' align='center' alignV='center' w='$w' h='$h'/>"
      "<Button name='${el.name}_torch' align='center' alignV='center' w='$w' h='$h'>"
      "<Triggers><Trigger action='up'>"
      "<VariableCommand name='lightSwitch' expression='!(#lightSwitch)'/>"
      "<IntentCommand action='miui.intent.action.TOGGLE_TORCH' broadcast='true'>"
      "<Extra name='miui.intent.extra.IS_ENABLE' type='boolean' expression='ifelse(int(@__miui_version_code)=8,#lightSwitch,1)'/>"
      "</IntentCommand></Trigger></Triggers></Button></Group>";

  /// Live digits and orbiting minute/second bubbles of the Orbit digital face.
  String _orbitDigitalXml(LockElementSpec el, double s, double ratio) {
    final cx = '#sw/2+${(el.dx * ratio).toStringAsFixed(2)}';
    final cy = '#sh/2+${(el.dy * ratio).toStringAsFixed(2)}';
    final ink = el.unlockAccent.toHex(withAlpha: true);
    final disc = el.colorSecondary.toHex(withAlpha: true);
    String f(double v) => (v * s).toStringAsFixed(2);
    // MAML trig functions take radians; 6° per minute/second.
    String px(double r, String v) => '$cx+${f(r)}*sin(#$v*0.1047198)';
    String py(double r, String v) => '$cy-${f(r)}*cos(#$v*0.1047198)';
    String text(String x, String y, double size, String attrs) =>
        "<Text x='$x' y='$y' align='center' alignV='center' size='${f(size)}'"
        " color='$ink' bold='true' $attrs/>";
    const o = OrbitDigital.minuteOrbit, so = OrbitDigital.secondOrbit;
    return text(
          cx,
          cy,
          OrbitDigital.hourText,
          "format='%02d' paras='ifelse(#time_format==1,#hour24,#hour12)'",
        ) +
        "<DateTime x='$cx' y='$cy+${f(OrbitDigital.dayY)}' align='center' alignV='center'"
            " size='${f(OrbitDigital.dayText)}' color='$ink' format='EEE'/>" +
        "<DateTime x='$cx' y='$cy+${f(OrbitDigital.dateY)}' align='center' alignV='center'"
            " size='${f(OrbitDigital.dateText)}' color='$ink' bold='true' format='MM/dd'/>" +
        "<Circle x='${px(o, 'minute')}' y='${py(o, 'minute')}' r='${f(OrbitDigital.minuteBubble)}' fillColor='$disc'/>" +
        text(
          px(o, 'minute'),
          py(o, 'minute'),
          OrbitDigital.minuteText,
          "format='%02d' paras='#minute'",
        ) +
        "<Line x='${px(so, 'second')}' y='${py(so, 'second')}'"
            " x1='${px(OrbitDigital.secondStem, 'second')}' y1='${py(OrbitDigital.secondStem, 'second')}'"
            " strokeColor='$disc' weight='${f(.008)}' cap='round'/>" +
        "<Circle x='${px(so, 'second')}' y='${py(so, 'second')}' r='${f(OrbitDigital.secondBubble)}' fillColor='$disc'/>" +
        text(
          px(so, 'second'),
          py(so, 'second'),
          OrbitDigital.secondText,
          "format='%02d' paras='#second'",
        );
  }

  String _styledCalendarXml(
    LockElementSpec el,
    String dx,
    String dy,
    String ang,
    String sz,
    String bold,
  ) {
    final l = CalendarLayout.of(el);
    String f(double v) => v.toStringAsFixed(2);
    String hex(Rgba c) => c.toHex(withAlpha: true);
    final inset = l.exportInset;
    final fullMonth = el.calendarWeekRows == 6;
    final day = fullMonth
        ? '(#__calendar_i-#calendar_first+1)'
        : '(#date-(#day_of_week-1)+#__calendar_i)';
    final visible = fullMonth ? 'ge($day,1)*le($day,#calendar_days)' : '1';
    String label(Rect2 r, String text, Rgba color) =>
        "<Text text='$text' x='${f(r.center.dx)}' y='${f(r.center.dy)}' align='center' alignV='center'"
        " size='$sz' color='${hex(color)}' bold='$bold'/>";
    final b = StringBuffer(
      "<Group x='#sw/2+$dx' y='#sh/2+$dy' angle='$ang' scale='${el.scale}'>"
      "<Group x='-${el.width / 2}' y='-${el.height / 2}'>"
      "<Image src='calendar/${el.name}_panel.png' x='${f(-inset)}' y='${f(-inset)}'"
      " w='${f(el.width + inset * 2)}' h='${f(el.height + inset * 2)}'/>"
      "<Var name='calendar_first' expression='(#day_of_week-1-(#date-1)%7+7)%7'/>"
      "<Var name='calendar_leap' expression='eq(#year%4,0)*ne(#year%100,0)+eq(#year%400,0)'/>"
      "<Var name='calendar_days' expression='ifelse(eq(#month,1),28+#calendar_leap,eq(#month,3)+eq(#month,5)+eq(#month,8)+eq(#month,10),30,31)'/>",
    );
    if (l.showsDates) {
      final h = l.highlight(l.firstDateRow, 0);
      const dRow = 'int(#__calendar_i/7)';
      b.write(
        "<Array count='${el.calendarWeekRows * 7}' indexName='__calendar_i'>"
        "<Rectangle x='${f(h.left)}+(#__calendar_i%7)*${f(l.colW)}' y='${f(h.top)}+$dRow*${f(l.rowH)}'"
        " w='${f(h.width)}' h='${f(h.height)}' cornerRadius='${f(h.radius)}'"
        " fillColor='${hex(el.colorSecondary)}' visibility='$visible*eq($day,#date)'/>"
        '</Array>',
      );
    }
    if (l.monthRow case final row?) {
      final r = l.cell(row, 0);
      b.write(
        "<DateTime format='MMMM yyyy' x='${f(l.inner.center.dx)}' y='${f(r.center.dy)}'"
        " align='center' alignV='center' size='$sz' color='${hex(el.color)}' bold='$bold'/>",
      );
    }
    if (l.weekdayRow case final row?) {
      for (var c = 0; c < 7; c++) {
        b.write(label(l.cell(row, c), l.labels[c], l.labelColor(c)));
      }
    }
    if (l.showsDates) {
      final x = '${f(l.inner.left)}+(#__calendar_i%7+0.5)*${f(l.colW)}';
      final y =
          '${f(l.inner.top)}+(int(#__calendar_i/7)+${l.firstDateRow + .5})*${f(l.rowH)}';
      String dateText(Rgba color, String show) =>
          "<DateTime format='d' value='#time_sys+($day-#date)*86400000' x='$x' y='$y'"
          " align='center' alignV='center' size='$sz' color='${hex(color)}' bold='$bold'"
          " visibility='$show'/>";
      b.write(
        "<Array count='${el.calendarWeekRows * 7}' indexName='__calendar_i'>"
        '${dateText(el.color, '$visible*ne($day,#date)')}'
        '${dateText(l.todayText, '$visible*eq($day,#date)')}'
        '</Array>',
      );
    }
    b.write('</Group></Group>');
    return b.toString();
  }

  String _shortcutSetXml(LockElementSpec el, double ratio) {
    final l = ShortcutSetLayout.of(el);
    final apps = ShortcutApp.parse(el.shortcutApps);
    String n(double v) => (v * el.scale).toStringAsFixed(2);
    final src = 'shortcut/${el.name}';
    final buffer = StringBuffer(
      "<Group x='#sw/2+${(el.dx * ratio).toStringAsFixed(2)}-${n(l.size.width / 2)}'"
      " y='#sh/2+${(el.dy * ratio).toStringAsFixed(2)}-${n(l.size.height / 2)}'"
      " angle='${(360 - el.angle) % 360}'>",
    );
    if (l.panel case final p?) {
      final inset = shortcutPanelInset(p);
      buffer.write(
        "<Image src='${src}_panel.png' x='${n(p.left - inset)}' y='${n(p.top - inset)}' w='${n(p.width + inset * 2)}' h='${n(p.height + inset * 2)}'/>",
      );
    }
    for (var i = 0; i < l.tiles.length; i++) {
      final t = l.tiles[i];
      final inset = shortcutTileExportInset(t);
      final app = apps[i];
      final probeName = '${el.name}_${i}_app';
      final probe = _appProbeXml(
        probeName,
        app.iconType,
        package: app.iconType == null ? app.package : null,
        activity: app.iconType == null ? app.activity : null,
      );
      final probeRef = probe == null ? null : probeName;
      if (probe != null) buffer.write(probe);
      final action = switch (app.iconType) {
        final type? => _appLaunchXml(type, probe: probeRef),
        null when app.package != null => _appLaunchXml(
          null,
          package: app.package,
          activity: app.activity,
          probe: probeRef,
        ),
        null =>
          "<IntentCommand action='miui.intent.action.TOGGLE_TORCH' broadcast='true'>"
              "<Extra name='miui.intent.extra.IS_TOGGLE' type='boolean' expression='1'/></IntentCommand>",
      };
      final image =
          "<Image src='${src}_$i.png' x='${n(-inset)}' y='${n(-inset)}' w='${n(t.width + inset * 2)}' h='${n(t.height + inset * 2)}'/>";
      buffer.write(
        // alignChildren makes the image coordinates relative to this button.
        "<Button name='${el.name}_$i' x='${n(t.left)}' y='${n(t.top)}' w='${n(t.width)}' h='${n(t.height)}' alignChildren='true'>"
        '<Normal>$image</Normal>'
        "<Pressed><Group alpha='170'>$image</Group></Pressed>"
        "<Triggers><Trigger action='up'>$action</Trigger></Triggers></Button>",
      );
    }
    buffer.write('</Group>');
    return buffer.toString();
  }

  String _skinnedUnlockXml(
    LockElementSpec el,
    String dxAdj,
    String dy,
    String ang,
  ) {
    final l = UnlockSkinLayout.of(el);
    String n(double v) => (v * el.scale).toStringAsFixed(2);
    final left = el.align == Alignment2.centerLeft
        ? 0.0
        : el.align == Alignment2.centerRight
        ? -l.width
        : -l.width / 2;
    final src = 'unlock/${el.name}';
    final track =
        "<Image src='${src}_track.png' x='0' y='0' w='${n(l.width)}' h='${n(l.height)}'/>";
    final icon =
        el.unlockSkin == UnlockSkin.meet ||
            el.effectiveUnlockIcon == UnlockIcon.none
        ? ''
        : "<Image src='$src.png' x='${n(l.iconCenter.dx)}' y='${n(l.iconCenter.dy)}' w='${n(l.iconSize)}' h='${n(l.iconSize)}' align='center' alignV='center'/>";
    final label = el.unlockText.isEmpty
        ? ''
        : XmlElement(XmlName('Text'), [
            XmlAttribute(XmlName('name'), '${el.name}_label'),
            XmlAttribute(XmlName('text'), el.unlockText),
            XmlAttribute(XmlName('x'), n(l.textRect.center.dx)),
            XmlAttribute(XmlName('y'), n(l.textRect.center.dy)),
            XmlAttribute(XmlName('w'), n(l.textRect.width)),
            XmlAttribute(XmlName('align'), 'center'),
            XmlAttribute(XmlName('alignV'), 'center'),
            XmlAttribute(
              XmlName('size'),
              '${el.unlockTextFontSize * 3.9 * el.scale}',
            ),
            XmlAttribute(XmlName('color'), el.color.toHex(withAlpha: true)),
            XmlAttribute(XmlName('bold'), '${el.isBold}'),
            XmlAttribute(XmlName('marqueeSpeed'), '0'),
          ]).toXmlString();
    final open = "<Group x='#sw/2+$dxAdj' y='#sh/2+$dy' angle='$ang'>";
    if (el.type == ElementType.tapToUnlock) {
      final glyph = '$track$icon$label';
      return "$open<Button name='tap_unlock_button' x='${n(left)}' y='${n(-l.height / 2)}' w='${n(l.width)}' h='${n(l.height)}' alignChildren='true' haptic='true'>"
          "<Normal>$glyph</Normal><Pressed><Group alpha='160'>$glyph</Group></Pressed>"
          "<Triggers><Trigger action='up'><ExternCommand command='unlock'/></Trigger></Triggers>"
          '</Button></Group>';
    }
    final drag = el.type == ElementType.dragToUnlock;
    final thumb =
        "<Image src='${src}_thumb.png' x='0' y='0' w='${n(l.thumbPaintWidth)}' h='${n(l.thumbHeight)}'/>$icon";
    final target = switch (l.target) {
      final t? =>
        "<Image src='${src}_target.png' x='${n(t.left)}' y='${n(t.top)}' w='${n(t.width)}' h='${n(t.height)}'/>",
      null => '',
    };
    return "$open<Group x='${n(left)}' y='${n(-l.height / 2)}'>"
        '$track$target$label'
        "<Unlocker name='${drag ? 'drag_unlocker' : 'slide_unlocker'}' alwaysShow='true' bounceAcceleration='4000' bounceInitSpeed='80'>"
        "<StartPoint x='0' y='${n(l.thumbY)}' w='${n(l.thumbWidth)}' h='${n(l.thumbHeight)}' anchorX='0' anchorY='0' alignChildren='true'>"
        '<NormalState>$thumb</NormalState><PressedState>$thumb</PressedState>'
        '${drag ? "<ReachedState>$thumb</ReachedState>" : ""}'
        "</StartPoint><EndPoint x='${n(l.travel)}' y='${n(l.thumbY)}' w='${n(l.thumbWidth)}' h='${n(l.thumbHeight)}' align='center' alignV='center'>"
        "<Path x='0' y='${n(l.thumbY)}' tolerance='1080'>"
        "<Position x='0' y='0'/><Position x='${n(l.travel)}' y='0'/>"
        '</Path></EndPoint></Unlocker></Group></Group>';
  }

  String _unlockIconXml(LockElementSpec element, double width, double height) {
    if (element.effectiveUnlockIcon == UnlockIcon.none) return '';
    var size =
        (width < height ? width : height) *
        element.unlockIconScale.clamp(.2, 1);
    final labeledTap =
        element.type == ElementType.tapToUnlock &&
        element.unlockText.isNotEmpty;
    final inline = labeledTap && element.unlockInline;
    if (labeledTap && !inline && size > height * .45) size = height * .45;
    final x = inline
        ? (height < width * .4 ? height : width * .4) / 2
        : width / 2;
    return "<Image src='unlock/${element.name}.png' x='$x' y='${height * (labeledTap && !inline ? .32 : .5)}' w='$size' h='$size' align='center' alignV='center'/>";
  }

  String _unlockTextXml(LockElementSpec element, double width, double height) {
    if (element.unlockText.isEmpty) return '';
    final tap = element.type == ElementType.tapToUnlock;
    final drag = element.type == ElementType.dragToUnlock;
    final inline =
        tap &&
        element.unlockInline &&
        element.effectiveUnlockIcon != UnlockIcon.none;
    final inset = inline
        ? (height < width * .4 ? height : width * .4)
        : tap
        ? 0.0
        : height;
    final span = width - inset - (drag ? height : 0);
    return XmlElement(XmlName('Text'), [
      XmlAttribute(XmlName('name'), '${element.name}_label'),
      XmlAttribute(XmlName('text'), element.unlockText),
      XmlAttribute(
        XmlName('x'),
        '${inline ? inset + (span - width * .08) / 2 : inset + span / 2}',
      ),
      XmlAttribute(
        XmlName('y'),
        '${height * (drag
                ? .82
                : tap && !inline && element.effectiveUnlockIcon != UnlockIcon.none
                ? .78
                : .5)}',
      ),
      XmlAttribute(XmlName('w'), '${inline ? span - width * .08 : span * .84}'),
      XmlAttribute(XmlName('align'), 'center'),
      XmlAttribute(XmlName('alignV'), 'center'),
      XmlAttribute(
        XmlName('size'),
        '${element.unlockTextFontSize * 3.9 * element.scale}',
      ),
      XmlAttribute(XmlName('color'), element.color.toHex(withAlpha: true)),
      XmlAttribute(XmlName('bold'), '${element.isBold}'),
      XmlAttribute(XmlName('marqueeSpeed'), '0'),
    ]).toXmlString();
  }

  String _musicXml(
    LockElementSpec el,
    String w,
    String h,
    String dx,
    String dy,
    String ang,
  ) {
    switch (el.type) {
      case ElementType.musicBg:
        return "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
            "<Group align='center' alignV='center' w='$w' h='$h' layered='true'>"
            "<Image name='music_album_cover' w='$w' h='$h'/>"
            "<Image w='$w' h='$h' src='music/bg.png' xfermode='dst_in'/></Group></Group>";
      case ElementType.musicNext:
        return "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
            "<Image src='music/next.png' align='center' alignV='center' w='$w' h='$h'/></Group>"
            "<Button name='music_next' w='$w' h='$h' align='center' alignV='center' x='#sw/2+$dx' y='#sh/2+$dy'/>";
      case ElementType.musicPrev:
        return "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
            "<Image src='music/prev.png' align='center' alignV='center' w='$w' h='$h'/></Group>"
            "<Button name='music_prev' w='$w' h='$h' align='center' alignV='center' x='#sw/2+$dx' y='#sh/2+$dy'/>";
      case ElementType.musicPlay:
        return "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
            "<Image src='music/play.png' align='center' alignV='center' w='$w' h='$h'"
            " visibility=\"ifelse(strIsEmpty(@music_control.title),true,false)\"/></Group>"
            "<Button name='music_play' w='$w' h='$h' align='center' alignV='center' x='#sw/2+$dx' y='#sh/2+$dy'/>";
      case ElementType.musicPause:
        return "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
            "<Image src='music/pause.png' align='center' alignV='center' w='$w' h='$h'"
            " visibility=\"ifelse(strIsEmpty(@music_control.title),false,true)\"/></Group>"
            "<Button name='music_pause' w='$w' h='$h' align='center' alignV='center' x='#sw/2+$dx' y='#sh/2+$dy'/>";
      default:
        return '';
    }
  }

  String _iconXml(
    LockElementSpec el,
    String w,
    String h,
    String dx,
    String dy,
    String ang,
  ) {
    final meta = _iconMeta[el.type];
    if (meta == null) return '';
    final source = (el.path.isEmpty ? '${meta[0]}.png' : '${el.path}.png')
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp(r'^/'), '');
    final image = XmlElement(XmlName('Image'), [
      XmlAttribute(XmlName('align'), 'center'),
      XmlAttribute(XmlName('alignV'), 'center'),
      XmlAttribute(XmlName('src'), source),
      XmlAttribute(XmlName('w'), w),
      XmlAttribute(XmlName('h'), h),
    ]).toXmlString();
    final probeName = '${el.name}_app';
    final probe = _appProbeXml(probeName, el.type);
    return "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
        '${probe ?? ''}'
        "<Button align='center' alignV='center' w='$w' h='$h'>"
        "<Normal>$image</Normal>"
        "<Triggers><Trigger action='up'>"
        '${_appLaunchXml(el.type, probe: probe == null ? null : probeName)}'
        "</Trigger></Triggers></Button></Group>";
  }

  static const _systemIntentIcons = {
    ElementType.dialerIcon,
    ElementType.mmsIcon,
    ElementType.contactIcon,
    ElementType.calendarIcon,
    ElementType.settingIcon,
  };

  /// Invisible app icon; its `bmp_width` is 0 when the app isn't installed.
  String? _appProbeXml(
    String name,
    ElementType? type, {
    String? package,
    String? activity,
  }) {
    if (_systemIntentIcons.contains(type)) return null;
    final pkg = package ?? _iconMeta[type]?[1];
    if (pkg == null) return null;
    final cls = activity ?? _activityOf(type);
    final component = cls == null ? pkg : '$pkg,$cls';
    return "<Image name='$name' srcType='ApplicationIcon' srcExp=\"'$component'\" x='0' y='0' w='1' h='1' alpha='0'/>";
  }

  static String? _activityOf(ElementType? type) {
    final meta = _iconMeta[type];
    return meta != null && meta.length > 2 ? meta[2] : null;
  }

  String _appLaunchXml(
    ElementType? type, {
    String? package,
    String? activity,
    String? probe,
  }) {
    final launchPackage = package ?? _iconMeta[type]?[1];
    final launchClass = activity ?? _activityOf(type);
    final attributes = switch (type) {
      ElementType.dialerIcon => {'action': 'android.intent.action.DIAL'},
      ElementType.mmsIcon => {
        'action': 'android.intent.action.SENDTO',
        'uri': 'sms:',
      },
      ElementType.contactIcon => {
        'action': 'android.intent.action.MAIN',
        'category': 'android.intent.category.APP_CONTACTS',
      },
      ElementType.calendarIcon => {
        'action': 'android.intent.action.MAIN',
        'category': 'android.intent.category.APP_CALENDAR',
      },
      ElementType.settingIcon => {'action': 'android.settings.SETTINGS'},
      _ => {
        'action': 'android.intent.action.MAIN',
        if (launchClass == null) 'category': 'android.intent.category.LAUNCHER',
        'package': launchPackage!,
        if (launchClass != null) 'class': launchClass,
        // FLAG_ACTIVITY_NEW_TASK: the lockscreen is not an activity context.
        'flags': '268435456',
      },
    };
    final command = XmlElement(
      XmlName('IntentCommand'),
      [
        for (final entry in attributes.entries)
          XmlAttribute(XmlName(entry.key), entry.value),
      ],
      [
        XmlElement(XmlName('Extra'), [
          XmlAttribute(XmlName('name'), 'StartActivityWhenLocked'),
          XmlAttribute(XmlName('type'), 'boolean'),
          XmlAttribute(XmlName('expression'), '1'),
        ]),
      ],
    );
    // The store opens only when the app is missing; the launch always runs so
    // a misread install check can't block an installed app.
    final market = probe != null && attributes.containsKey('package')
        ? "<IntentCommand action='android.intent.action.VIEW' uri='market://details?id=$launchPackage&amp;ref=mithemelockscreen' flags='268435456' condition='not(#$probe.bmp_width)'/>"
        : '';
    return '<ExternCommand command="unlock"/>$market${command.toXmlString()}';
  }

  static const Map<ElementType, List<String>> _iconMeta = {
    ElementType.cameraIcon: [
      'icon/camera',
      'com.android.camera',
      'com.android.camera.Camera',
    ],
    ElementType.themeIcon: [
      'icon/theme',
      'com.android.thememanager',
      'com.android.thememanager.ThemeResourceTabActivity',
    ],
    ElementType.settingIcon: [
      'icon/setting',
      'com.android.settings',
      'com.android.settings.MiuiSettings',
    ],
    ElementType.galleryIcon: [
      'icon/gallery',
      'com.miui.gallery',
      'com.miui.gallery.activity.HomePageActivity',
    ],
    ElementType.musicIcon: [
      'icon/music',
      'com.miui.player',
      'com.miui.player.ui.MusicBrowserActivity',
    ],
    ElementType.dialerIcon: [
      'icon/dialer',
      'com.android.contacts',
      'com.android.contacts.activities.TwelveKeyDialer',
      'com.google.android.dialer',
      'com.google.android.dialer.extensions.GoogleDialtactsActivity',
    ],
    ElementType.mmsIcon: [
      'icon/mms',
      'com.android.mms',
      'com.android.mms.ui.MmsTabActivity',
      'com.google.android.apps.messaging',
      'com.google.android.apps.messaging.ui.ConversationListActivity',
    ],
    ElementType.contactIcon: [
      'icon/contact',
      'com.android.contacts',
      'com.android.contacts.activities.PeopleActivity',
      'com.google.android.contacts',
      'com.android.contacts.activities.PeopleActivity',
    ],
    ElementType.whatsAppIcon: [
      'icon/whatsApp',
      'com.whatsapp',
      'com.whatsapp.Main',
    ],
    ElementType.telegramIcon: [
      'icon/telegram',
      'org.telegram.messenger',
      'org.telegram.ui.LaunchActivity',
    ],
    ElementType.instagramIcon: [
      'icon/instagram',
      'com.instagram.android',
      'com.instagram.android.activity.MainTabActivity',
    ],
    ElementType.spotifyIcon: [
      'icon/spotify',
      'com.spotify.music',
      'com.spotify.music.MainActivity',
    ],
    ElementType.calendarIcon: [
      'icon/calendar',
      'com.android.calendar',
      'com.android.calendar.AllInOneActivity',
    ],
    ElementType.weatherIcon: [
      'icon/weather',
      'com.miui.weather2',
      'com.miui.weather2.ActivityWeatherMain',
    ],
    ElementType.clockIcon: [
      'icon/clock',
      'com.android.deskclock',
      'com.android.deskclock.DeskClockTabActivity',
    ],
    ElementType.notesIcon: [
      'icon/notes',
      'com.miui.notes',
      'com.miui.notes.ui.NotesListActivity',
    ],
    ElementType.browserIcon: [
      'icon/browser',
      'com.mi.globalbrowser',
      'com.mi.globalbrowser.Main',
    ],
    ElementType.calculatorIcon: [
      'icon/calculator',
      'com.miui.calculator',
      'com.miui.calculator.cal.CalculatorActivity',
    ],
    ElementType.compassIcon: [
      'icon/compass',
      'com.miui.compass',
      'com.miui.compass.CompassActivity',
    ],
    ElementType.fileManagerIcon: [
      'icon/fileManager',
      'com.android.fileexplorer',
      'com.android.fileexplorer.FileExplorerTabActivity',
    ],
    ElementType.videoIcon: [
      'icon/video',
      'com.miui.video',
      'com.miui.video.HomeActivity',
    ],
    ElementType.securityIcon: [
      'icon/security',
      'com.miui.securitycenter',
      'com.miui.securitycenter.Main',
    ],
    ElementType.radioIcon: [
      'icon/radio',
      'com.miui.fmradio',
      'com.miui.fmradio.FmRadioActivity',
    ],
    ElementType.recorderIcon: [
      'icon/recorder',
      'com.android.soundrecorder',
      'com.android.soundrecorder.SoundRecorder',
    ],
    ElementType.downloadsIcon: [
      'icon/downloads',
      'com.android.providers.downloads.ui',
      'com.android.providers.downloads.ui.DownloadList',
    ],
  };

  static final String _baseManifest =
      '''<?xml version="1.0" encoding="utf-8"?>
<Lockscreen version="2" frameRate="30" displayDesktop="false" screenWidth="1080" useVariableUpdater="Battery,DateTime.Second">
  <Var expression="#screen_width" name="sw"/>
  <Var expression="#screen_height" name="sh"/>
  <Wallpaper name="wall" pivotX="#wall.bmp_width/2" pivotY="#wall.bmp_height/2"/>
  <Video layerType="bottom" name="mamlVideo"/>
  <VariableBinders>
    <ContentProviderBinder name="WeatherService"
      uri="content://weather/actualWeatherData/1"
      columns="weather_type,temperature,description,city_name,temperature_range,aqilevel,humidity" countName="hasweather">
      <Variable name="typeID" type="int" column="weather_type"/>
      <Variable name="weather_temperature" type="int" column="temperature"/>
      <Variable name="weather_description" type="string" column="description"/>
      <Variable name="weather_location" type="string" column="city_name"/>
      <Variable name="weather_temperature_range" type="string" column="temperature_range"/>
      <Variable name="weather_aqi" type="int" column="aqilevel"/>
      <Variable name="weather_humidity" type="int" column="humidity"/>
      <Trigger><VariableCommand name="w_outID" expression="#typeID" type="int"/></Trigger>
    </ContentProviderBinder>
    <ContentProviderBinder name="data"
      uri="content://keyguard.notification/notifications"
      columns="icon,title,content,time,info,subtext,key" countName="hasnotifications">
      <List name="notification_list"/>
    </ContentProviderBinder>
  </VariableBinders>
  	<ExternalCommands>
		<Trigger action="init">
		  <VideoCommand command="config" loop="1" path="&apos;video.mp4&apos;" scaleMode="2" target="mamlVideo"/>
		  <VideoCommand command="play" target="mamlVideo"/>
		  <IntentCommand action="initialization" broadcast="true">
			<Extra expression="#btnVar" name="bg_number" type="number"/>
		  </IntentCommand>
		</Trigger>
		<Trigger action="pause">
		  <AnimationCommand command="play(0,0)" target="resumeAni"/>
		  <VideoCommand command="seekTo" target="mamlVideo" time="0"/>
		</Trigger>
		<Trigger action="resume">
		  <AnimationCommand command="play" target="resumeAni"/>
		  <VideoCommand command="play" delay="100" target="mamlVideo"/>
		</Trigger>
	  </ExternalCommands>
  <Group name="bgAlpha"></Group>
  <Image name="bgLock" srcExp="'bg.png'" width="#sw" height="#sh"/>
  <MusicControl name="music_control" align="center" alignV="center"
    autoShow="true" defAlbumCover="music/bg.png"
    enableLyric="true" updateLyricInterval="100"></MusicControl>
  ${ElementType.values.where((e) => !e.isMusic).map((e) => "<Group name='${e.name}'></Group>").join('\n  ')}
</Lockscreen>''';
}
