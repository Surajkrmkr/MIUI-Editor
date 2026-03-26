import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/theme_editor/core/extensions/color_ext.dart';
import 'package:xml/xml.dart';
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import 'element_provider.dart';
import 'wallpaper_provider.dart';
import 'service_providers.dart';
import 'usecase_providers.dart';

class LockscreenState {
  const LockscreenState({
    this.isExporting = false,
    this.isExportingPngs = false,
    this.isExported = false,
    this.isCopyingDefaults = false,
    this.dualMtzExport = false,
    this.pngsDone = 0,
    this.pngsTotal = 0,
    this.error,
  });

  final bool isExporting, isExportingPngs, isExported, isCopyingDefaults;
  final bool dualMtzExport;
  final int pngsDone, pngsTotal;
  final String? error;

  bool get isBusy => isExporting || isExportingPngs || isCopyingDefaults;

  double get pngsProgress => pngsTotal == 0 ? 0 : pngsDone / pngsTotal;

  String get pngsLabel => isExportingPngs ? 'Frames $pngsDone/$pngsTotal' : '';

  LockscreenState copyWith({
    bool? isExporting,
    isExportingPngs,
    isExported,
    isCopyingDefaults,
    bool? dualMtzExport,
    int? pngsDone,
    pngsTotal,
    String? error,
  }) =>
      LockscreenState(
        isExporting: isExporting ?? this.isExporting,
        isExportingPngs: isExportingPngs ?? this.isExportingPngs,
        isExported: isExported ?? this.isExported,
        isCopyingDefaults: isCopyingDefaults ?? this.isCopyingDefaults,
        dualMtzExport: dualMtzExport ?? this.dualMtzExport,
        pngsDone: pngsDone ?? this.pngsDone,
        pngsTotal: pngsTotal ?? this.pngsTotal,
        error: error,
      );
}

class LockscreenNotifier extends Notifier<LockscreenState> {
  @override
  LockscreenState build() => const LockscreenState();

  // ── Copy default PNGs ─────────────────────────────────────────────────────

  Future<void> copyDefaultPngs() async {
    state = state.copyWith(isCopyingDefaults: true);
    try {
      final ws = ref.read(wallpaperProvider);
      if (ws.weekNum == null || ws.currentThemeName == null) return;
      final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
      final lsPath = PathConstants.lockscreenAdvance(tp);
      final sample = PathConstants.sample2Lockscreen();
      final fs = ref.read(fileServiceProvider);
      await fs.createDir(lsPath);
      for (final png in PathConstants.lockscreenDefaultPngs) {
        if (png == null) continue;
        final src = PathConstants.p('$sample$png.png');
        final dst = PathConstants.p('$lsPath$png.png');
        if (await fs.exists(src)) await fs.copyFile(src, dst);
      }
    } catch (_) {}
    state = state.copyWith(isCopyingDefaults: false);
  }

  // ── Export manifest XML ───────────────────────────────────────────────────

  Future<Failure?> export(BuildContext context) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      final ws = ref.read(wallpaperProvider);
      final els = ref.read(elementProvider);

      if (ws.weekNum == null || ws.currentThemeName == null) {
        state = state.copyWith(isExporting: false, error: 'No active theme');
        return const ValidationFailure('No active theme');
      }

      final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
      final lsPath = PathConstants.lockscreenAdvance(tp);

      // ── Step 1: write manifest.xml ────────────────────────────────────────
      final doc = _buildManifest(els);
      final fs = ref.read(fileServiceProvider);
      await fs.writeString(
        '${lsPath}manifest.xml',
        doc.toXmlString(pretty: true, indent: '\t'),
      );

      // ── Step 2: export PNG frames (parallel batches) ──────────────────────
      final pngFailure = await exportPngs(context);
      if (pngFailure != null) {
        state = state.copyWith(isExporting: false, error: pngFailure.message);
        return pngFailure;
      }

      // ── Step 3: auto-pack MTZ ─────────────────────────────────────────────
      // No extra button tap — the full theme is ready, so zip it immediately.
      final (_, mtzFailure) = await ref.read(exportMtzUseCaseProvider).call(
            themePath: tp,
            themeName: ws.currentThemeName!,
            dualVersion: state.dualMtzExport,
          );
      if (mtzFailure != null) {
        // MTZ failure is non-fatal — XML + PNGs are still exported correctly.
        // Surface it as a warning rather than aborting.
        state = state.copyWith(
          isExporting: false,
          isExported: true,
          error: 'MTZ warning: ${mtzFailure.message}',
        );
        return null; // don't propagate — LS export itself succeeded
      }

      await checkExported();
      state = state.copyWith(isExporting: false, isExported: true);
      return null;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return ExportFailure(e.toString());
    }
  }

  // ── Export PNG frames via use case ────────────────────────────────────────

  Future<Failure?> exportPngs(BuildContext context) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return null;

    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final els = ref.read(elementProvider);

    state = state.copyWith(isExportingPngs: true, pngsDone: 0, pngsTotal: 0);

    final failure = await ref.read(exportLockscreenPngsUseCaseProvider).call(
          context: context,
          elementState: els,
          themePath: tp,
          onProgress: (done, total) =>
              state = state.copyWith(pngsDone: done, pngsTotal: total),
        );

    state = state.copyWith(isExportingPngs: false);
    return failure;
  }

  // ── Preset — delegates to use cases ──────────────────────────────────────

  Future<Failure?> savePreset(String name) => ref
      .read(savePresetUseCaseProvider)
      .call(name, ref.read(elementProvider).elements);

  Future<Failure?> loadPreset(String jsonPath) async {
    final (elements, failure) =
        await ref.read(loadPresetUseCaseProvider).call(jsonPath);
    if (failure != null) return failure;
    if (elements != null) {
      ref.read(elementProvider.notifier).setAll(elements);
    }
    return null;
  }

  // ── MTZ — delegates to use case ───────────────────────────────────────────

  void toggleDualMtzExport() =>
      state = state.copyWith(dualMtzExport: !state.dualMtzExport);

  Future<(String?, Failure?)> exportMtz() {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) {
      return Future.value((null, const ValidationFailure('No active theme')));
    }
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    return ref.read(exportMtzUseCaseProvider).call(
          themePath: tp,
          themeName: ws.currentThemeName!,
          dualVersion: state.dualMtzExport,
        );
  }

  void resetExportState() {
    state = state.copyWith(
      isExported: false,
      isExporting: false,
      isExportingPngs: false,
      pngsDone: 0,
      pngsTotal: 0,
      error: null,
    );
  }

  // checkExported() already exists — just make sure it's public (no underscore).
  Future<void> checkExported() async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final manifest =
        PathConstants.p('${PathConstants.lockscreenAdvance(tp)}manifest.xml');
    final exists = await ref.read(fileServiceProvider).exists(manifest);
    state = state.copyWith(isExported: exists);
  }

  // ── Manifest builder ───────────────────────────────────────────────────────

  XmlDocument _buildManifest(ElementState els) {
    final doc = XmlDocument.parse(_baseManifest);
    // bg alpha
    doc
            .findAllElements('Group')
            .firstWhere((e) => e.getAttribute('name') == 'bgAlpha')
            .innerXml =
        '<Rectangle width="#sw" alpha="${(els.bgAlpha * 255).toStringAsFixed(0)}"'
        ' height="#sh" fillColor="#ff000000"/>';

    for (final el in els.elements) {
      final xml = _xmlFor(el);
      if (xml == null) continue;
      if (el.type.isMusic) {
        final mc = doc
            .findAllElements('MusicControl')
            .firstWhere((e) => e.getAttribute('name') == 'music_control');
        mc.innerXml = mc.innerXml + xml;
      } else {
        doc
            .findAllElements('Group')
            .where((e) => e.getAttribute('name') == el.type.name)
            .forEach((g) => g.innerXml = xml);
      }
    }
    return doc;
  }

  String? _xmlFor(LockElement el) {
    // ── Static clock XMLs ──────────────────────────────────────────────────
    switch (el.type) {
      case ElementType.hourClock:
        return "<Image name='hour' srcExp=\"'hour/hour_'+ int((#hour12)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.minClock:
        return "<Image name='min' srcExp=\"'min/min_'+ int((#minute)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.dotClock:
        return "<Image name='dot' srcExp=\"'dot/dot.png'\" width='#sw' height='#sh'/>";
      case ElementType.weekClock:
        return "<Image name='week' srcExp=\"'week/week_'+ int((#day_of_week-1)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.monthClock:
        return "<Image name='month' srcExp=\"'month/month_'+ int((#month+1)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.dateClock:
        return "<Image name='date' srcExp=\"'date/date_'+ int((#date)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.amPmClock:
        return "<Image name='ampm' srcExp=\"'ampm/ampm_'+ int((#ampm)) +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.weatherIconClock:
        return "<Image name='weatherIcon' srcExp=\"'weather/weather_'+ #w_outID +'.png'\" width='#sw' height='#sh'/>";
      case ElementType.swipeUpUnlock:
        return "<Unlocker name='unlocker' visibility='not(#unlocker_v)'>"
            "<StartPoint x='0' y='0' w='#sw' h='#sh' easeType='BounceEaseOut' easeTime='400'/>"
            "<EndPoint x='0' y='-#sh' w='#sw' h='#sh - 400'>"
            "<Path x='0' y='0' tolerance='2000'>"
            "<Position x='0' y='0'/><Position x='0' y='-#sh'/>"
            "</Path></EndPoint></Unlocker>";
      case ElementType.tapToUnlock:
        return "<Unlocker name='unlocker' visibility='not(#unlocker_v)'>"
            "<StartPoint x='0' y='0' w='#sw' h='#sh' easeType='BounceEaseOut' easeTime='400'/>"
            "<EndPoint x='0' y='-#sh' w='#sw' h='#sh - 400'>"
            "<Path x='0' y='0' tolerance='2000'>"
            "<Position x='0' y='0'/><Position x='0' y='-#sh'/>"
            "</Path></EndPoint></Unlocker>";
      case ElementType.slideToUnlock:
      default:
        return _dynamicXml(el);
    }
  }

  String? _dynamicXml(LockElement el) {
    const ratio = 3.9;
    final w = (el.width * el.scale).toStringAsFixed(2);
    final h = (el.height * el.scale).toStringAsFixed(2);
    final dx = (el.dx * ratio).toStringAsFixed(2);
    final dy = (el.dy * ratio).toStringAsFixed(2);
    final ang = (360 - el.angle).toStringAsFixed(2);
    final c = el.color.toMamlHex();
    final c2 = el.colorSecondary.toMamlHex();
    final sz = (el.fontSize * ratio).toStringAsFixed(2);
    final bold = el.fontWeight == FontWeight.w700 ? 'true' : 'false';

    String alignStr = 'center';
    String dxAdj = dx;
    if (el.align == Alignment.centerLeft) {
      alignStr = 'left';
      dxAdj = '$dx-#sw/2';
    }
    if (el.align == Alignment.centerRight) {
      alignStr = 'right';
      dxAdj = '$dx+#sw/2';
    }

    if (el.type.isContainer) {
      return "<Image name='containerBG' srcExp=\"'container/${el.name}.png'\" width='#sw' height='#sh'/>";
    }
    if (el.type.isPng) {
      return "<Image name='pngBG' srcExp=\"'png/${el.name}.png'\" width='#sw' height='#sh'/>";
    }

    if (el.type.isDateTime) {
      return "<DateTime angle='$ang' x='#sw/2+$dxAdj' y='#sh/2+$dy'"
          " align='$alignStr' alignV='center' size='$sz' color='$c'"
          " formatExp=\"'${el.text}'\" bold='$bold'/>";
    }

    if (el.type.isNormalText) {
      return "<Text angle='$ang' x='#sw/2+$dxAdj' y='#sh/2+$dy'"
          " align='$alignStr' alignV='center' size='$sz' color='$c'"
          " textExp='${el.text}' bold='$bold'/>";
    }

    if (el.type == ElementType.notification) {
      return "<List name='notification_list' x='0' y='$dy+#sh/2' w='#screen_width'"
          " maxHeight='int(186+20)*3' data='icon:bitmap,title:string,content:string,time:string'"
          " visibility='#hasnotifications'>"
          "<Item x='540' y='0' w='1024' h='int(186+20)' align='center'>"
          "<Button x='0' y='0' w='1024' h='206'>"
          "<Normal><Rectangle x='0' w='1024' h='186' fillColor='$c2' cornerRadius='25'/></Normal>"
          "</Button></Item></List>";
    }

    if (el.type == ElementType.tapToUnlock) {
      return "<Unlocker name='unlocker' visibility='not(#unlocker_v)' x='#sw/2+$dx' y='#sh/2+$dy'>"
          "<StartPoint h='$h' w='$w' x='#touch_begin_x-50' y='#touch_begin_y-50'></StartPoint>"
          "<EndPoint h='0' w='0' x='0' y='0'></EndPoint>"
          "<Image align='center' alignV='center' alpha='255-75*#locks' scale='1.0' h='$h' w='$w' src='unlock/tap.png' x='#sw/2' y='#sh/2'/>"
          "<Button align='center' alignV='center' h='$h' w='$w' visibility='eq(#state,0)*eq(#open,0)' x='#sw/2+$dx' y='#sh/2+$dy'>"
          "<Triggers>"
          "<Trigger action='down'> <VariableCommand expression='1' name='locks'/> </Trigger>"
          "<Trigger action='up,cancel'> <VariableCommand expression='0' name='locks'/> </Trigger>"
          "<Trigger action='up'> <ExternCommand command='unlock'/> </Trigger>"
          "</Triggers>"
          "</Button>"
          "</Unlocker>";
    }

    if (el.type == ElementType.slideToUnlock) {
      return "<Unlocker name='unlocker' alwaysShow='true' bounceAcceleration='4000' bounceInitSpeed='80' x='#sw/2+$dx' y='#sh/2+$dy'>"
          "<Image align='center' src='unlock/slider_base.png' x='0' y='0-14'/>"
          "<StartPoint h='201' w='240' x='80-#sw/2' y='0'>"
          "<NormalState><Image src='unlock/unlock.png' x='60-#sw/2' y='0'/></NormalState>"
          "<ReachedState><Image alpha='0' src='unlock/unlock.png' x='#sw/2-365' y='0'/></ReachedState>"
          "</StartPoint>"
          "<EndPoint h='201' w='600' x='#sw/2-620' y='0'>"
          "<ReachedState><Image src='unlock/unlock.png' x='#sw/2-365' y='0'/></ReachedState>"
          "<Path tolerance='300' x='-#sw/2' y='0'>"
          "<Position x='80' y='0'/><Position x='#sw*0.8 - 25' y='0'/>"
          "</Path></EndPoint></Unlocker>";
    }

    if (el.type.isMusic) return _musicXml(el, w, h, dx, dy, ang);
    if (el.type.isIcon) return _iconXml(el, w, h, dx, dy, ang);
    return null;
  }

  String _musicXml(
      LockElement el, String w, String h, String dx, String dy, String ang) {
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
      LockElement el, String w, String h, String dx, String dy, String ang) {
    final meta = _iconMeta[el.type];
    if (meta == null) return '';
    return "<Group angle='$ang' x='#sw/2+$dx' y='#sh/2+$dy' align='center' alignV='center'>"
        "<Button align='center' alignV='center' w='$w' h='$h'>"
        "<Normal><Image align='center' alignV='center' src='${meta[0]}.png' w='$w' h='$h'/></Normal>"
        "<Triggers><Trigger action='up'>"
        "<IntentCommand action='android.intent.action.MAIN' package='${meta[1]}' class='${meta[2]}'>"
        "${meta.length > 3 ? "<IntentCommand action='android.intent.action.MAIN' package='${meta[3]}' class='${meta[4]}'>" : ""}"
        "<Extra name='StartActivityWhenLocked' type='boolean' expression='1'/></IntentCommand>"
        "<ExternCommand command='unlock' condition='not(#set_lock)'/>"
        "</Trigger></Triggers></Button></Group>";
  }

  static const Map<ElementType, List<String>> _iconMeta = {
    ElementType.cameraIcon: [
      'icon/camera',
      'com.android.camera',
      'com.android.camera.Camera'
    ],
    ElementType.themeIcon: [
      'icon/theme',
      'com.android.thememanager',
      'com.android.thememanager.ThemeResourceTabActivity'
    ],
    ElementType.settingIcon: [
      'icon/setting',
      'com.android.settings',
      'com.android.settings.MainSettings'
    ],
    ElementType.galleryIcon: [
      'icon/gallery',
      'com.miui.gallery',
      'com.miui.gallery.activity.HomePageActivity'
    ],
    ElementType.musicIcon: [
      'icon/music',
      'com.miui.player',
      'com.miui.player.ui.MusicBrowserActivity'
    ],
    ElementType.dialerIcon: [
      'icon/dialer',
      'com.android.contacts',
      'com.android.contacts.activities.TwelveKeyDialer',
      'com.google.android.dialer',
      'com.google.android.dialer.extensions.GoogleDialtactsActivity'
    ],
    ElementType.mmsIcon: [
      'icon/mms',
      'com.android.mms',
      'com.android.mms.ui.MmsTabActivity',
      'com.google.android.apps.messaging',
      'com.google.android.apps.messaging.ui.ConversationListActivity'
    ],
    ElementType.contactIcon: [
      'icon/contact',
      'com.android.contacts',
      'com.android.contacts.activities.PeopleActivity',
      'com.google.android.contacts',
      'com.android.contacts.activities.PeopleActivity'
    ],
    ElementType.whatsAppIcon: [
      'icon/whatsApp',
      'com.whatsapp',
      'com.whatsapp.Main'
    ],
    ElementType.telegramIcon: [
      'icon/telegram',
      'org.telegram.messenger',
      'org.telegram.messenger'
    ],
    ElementType.instagramIcon: [
      'icon/instagram',
      'com.instagram.android',
      'com.instagram.android.activity.MainTabActivity'
    ],
    ElementType.spotifyIcon: [
      'icon/spotify',
      'com.spotify.music',
      'com.spotify.music.MainActivity'
    ],
  };

  static final String _baseManifest = '''<?xml version="1.0" encoding="utf-8"?>
<Lockscreen version="2" frameRate="30" displayDesktop="false" screenWidth="1080">
  <Var expression="#screen_width" name="sw"/>
  <Var expression="#screen_height" name="sh"/>
  <Wallpaper name="wall" pivotX="#wall.bmp_width/2" pivotY="#wall.bmp_height/2"/>
  <Video layerType="bottom" name="mamlVideo"/>
  <VariableBinders>
    <ContentProviderBinder name="WeatherService"
      uri="content://weather/actualWeatherData/1"
      columns="weather_type,temperature" countName="hasweather">
      <Variable name="typeID" type="int" column="weather_type"/>
      <Trigger><VariableCommand name="w_outID" expression="#typeID" type="int"/></Trigger>
    </ContentProviderBinder>
    <ContentProviderBinder name="data"
      uri="content://keyguard.notification/notifications"
      columns="icon,title,content,time,key" countName="hasnotifications">
      <List name="notification_list"/>
    </ContentProviderBinder>
  </VariableBinders>
  <Group name="bgAlpha"></Group>
  <Image name="bgLock" srcExp="'bg.png'" width="#sw" height="#sh"/>
  <MusicControl name="music_control" align="center" alignV="center"
    autoShow="true" defAlbumCover="music/bg.png"
    enableLyric="true" updateLyricInterval="100"></MusicControl>
  ${ElementType.values.where((e) => !e.isMusic).map((e) => "<Group name='${e.name}'></Group>").join('\n  ')}
</Lockscreen>''';
}

final lockscreenProvider =
    NotifierProvider<LockscreenNotifier, LockscreenState>(
        LockscreenNotifier.new);
