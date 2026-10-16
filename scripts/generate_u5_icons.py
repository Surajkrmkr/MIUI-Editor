"""Generates the u5 "Duotone" icon set into assets/icons/u5.

Each glyph is white on a 48x48 canvas: a 40%-opacity body plus solid accents.
The editor tints via BlendMode.srcIn, so the duotone survives any icon color.
"""
import math
import os

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons', 'u5')
SOFT = 'stroke="white" stroke-width="2" stroke-linejoin="round"'


def fill(d, soft=True, evenodd=False):
    rule = ' fill-rule="evenodd" clip-rule="evenodd"' if evenodd else ''
    return f'<path{rule} d="{d}" fill="white"{" " + SOFT if soft else ""}/>'


def line(d, w=3):
    return (f'<path d="{d}" stroke="white" stroke-width="{w}" '
            'stroke-linecap="round" stroke-linejoin="round"/>')


def circ(cx, cy, r):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="white"/>'


def ring(cx, cy, r, w=3):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" stroke="white" stroke-width="{w}"/>'


def rr(x, y, w, h, r):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="white"/>'


def base(*els):
    return '<g opacity="0.4">' + ''.join(els) + '</g>'


def group(transform, *els):
    return f'<g transform="{transform}">' + ''.join(els) + '</g>'


def sparkle(cx, cy, r, k):
    return (f'M{cx} {cy - r}Q{cx + k} {cy - k} {cx + r} {cy}'
            f'Q{cx + k} {cy + k} {cx} {cy + r}Q{cx - k} {cy + k} {cx - r} {cy}'
            f'Q{cx - k} {cy - k} {cx} {cy - r}Z')


def gear(cx=24, cy=24, teeth=8, R=19, r=14.5):
    pts = []
    step = 360 / teeth
    for i in range(teeth):
        a = i * step
        for rad, off in ((r, -13), (R, -8), (R, 8), (r, 13)):
            t = math.radians(a + off)
            pts.append(f'{cx + rad * math.cos(t):.2f} {cy + rad * math.sin(t):.2f}')
    return 'M' + 'L'.join(pts) + 'Z'


HANDSET = ('M15 10h5l2.5 7-3.5 3a20 20 0 0 0 9 9l3-3.5 7 2.5v5a3 3 0 0 1-3 3'
           'C21.5 36 12 26.5 12 13a3 3 0 0 1 3-3z')
BUBBLE = ('M24 6C13.5 6 5 13.4 5 22.5c0 4.8 2.4 9.1 6.2 12.1L9.5 42l8.4-4.2'
          'c1.9.5 4 .7 6.1.7 10.5 0 19-7.4 19-16.5S34.5 6 24 6z')
BAG = 'M9 16h30l-1.8 22a5 5 0 0 1-5 4.6H15.8a5 5 0 0 1-5-4.6z'
BAG_HANDLE = 'M17 20v-6a7 7 0 0 1 14 0v6'
DOC = 'M12 4h16l12 12v22a6 6 0 0 1-6 6H14a6 6 0 0 1-6-6V8a4 4 0 0 1 4-4z'
DOC_FOLD = 'M28 4v8a4 4 0 0 0 4 4h8z'
PLAY = 'M20 17v14l12-7z'


def handset(scale=1.0, cx=24, cy=24):
    return group(f'translate({cx} {cy}) scale({scale}) translate(-25 -23)', fill(HANDSET))


ICONS = {
    'browser': [base(circ(24, 24, 20)),
                line('M24 4.5c-5 5-7.5 12-7.5 19.5s2.5 14.5 7.5 19.5c5-5 7.5-12 7.5-19.5S29 9.5 24 4.5z'),
                line('M7 17h34M7 31h34')],
    'chrome': [base(circ(24, 24, 20)), ring(24, 24, 8), circ(24, 24, 4),
               line('M24 16H41M30.93 28l-8.5 14.72M17.07 28l-8.5-14.72')],
    'calculator': [base(rr(8, 4, 32, 40, 8)), rr(14, 10, 20, 8, 3),
                   circ(16, 27, 3), circ(24, 27, 3), circ(32, 27, 3),
                   circ(16, 36, 3), circ(24, 36, 3), circ(32, 36, 3)],
    'calendar': [base(rr(6, 9, 36, 33, 8)), fill('M6 17a8 8 0 0 1 8-8h20a8 8 0 0 1 8 8v3H6z', soft=False),
                 line('M16 5v8M32 5v8'),
                 rr(13, 25, 6, 6, 2), rr(21, 25, 6, 6, 2), rr(29, 25, 6, 6, 2),
                 rr(13, 33, 6, 6, 2), rr(21, 33, 6, 6, 2)],
    'camera': [base(rr(4, 12, 40, 28, 8)), fill('M17 12l2.5-4.5h9L31 12z'),
               ring(24, 26, 8), circ(24, 26, 3.5), circ(37, 18, 1.8)],
    'contacts': [base(rr(8, 4, 32, 40, 8)), circ(24, 19, 6),
                 fill('M14 36a10 9 0 0 1 20 0v1a2 2 0 0 1-2 2H16a2 2 0 0 1-2-2z')],
    'dialer': [base(circ(24, 24, 20)), handset(0.72)],
    'call_log': [base(rr(5, 5, 38, 38, 11)), handset(0.62, 21, 27),
                 line('M30 12h6v6M36 12l-8 8')],
    'clock': [base(circ(24, 24, 20)), line('M24 13v11l7 5'), circ(24, 24, 2.5),
              circ(24, 8, 1.6), circ(40, 24, 1.6), circ(24, 40, 1.6), circ(8, 24, 1.6)],
    'files': [base(fill('M4 14a6 6 0 0 1 6-6h9l5 5h14a6 6 0 0 1 6 6v17a6 6 0 0 1-6 6H10a6 6 0 0 1-6-6z', soft=False)),
              fill('M4 21a5 5 0 0 1 5-5h30a5 5 0 0 1 5 5v15a6 6 0 0 1-6 6H10a6 6 0 0 1-6-6z'
                   'M18 26.5a1.5 1.5 0 0 0 0 3h12a1.5 1.5 0 0 0 0-3z', soft=False, evenodd=True)],
    'settings': [base(fill(gear())), circ(24, 24, 7)],
    'recorder': [base(rr(17, 5, 14, 24, 7)), line('M21.5 13h5M21.5 19h5'),
                 line('M11 22a13 13 0 0 0 26 0M24 35v7M18 42h12')],
    'sim': [base(fill('M14 4h14l10 10v24a6 6 0 0 1-6 6H16a6 6 0 0 1-6-6V8a4 4 0 0 1 4-4z')),
            rr(16, 22, 16, 14, 3)],
    'themes': [base(fill('M24 4C12.95 4 4 12.95 4 24s8.95 20 20 20c2.2 0 4-1.8 4-4 0-1-.4-1.9-1-2.6'
                         '-.6-.7-1-1.6-1-2.6 0-2.2 1.8-4 4-4h4.7C39.4 30.8 44 26.2 44 20.5 44 11.4 35 4 24 4z',
                         soft=False)),
               circ(13, 23, 3), circ(17, 13.5, 3), circ(27, 10.5, 3), circ(35, 17, 3)],
    'play_store': [base(fill('M10 6.5c0-2 2.1-3.2 3.8-2.2l26 16.3c1.6 1 1.6 3.4 0 4.4l-26 16.3'
                             'c-1.7 1-3.8-.2-3.8-2.2z')),
                   line('M11.5 6.5L28 24 11.5 41.5')],
    'download': [base(circ(24, 24, 20)), line('M24 13v16M17 23l7 7 7-7M16 35h16')],
    'facebook': [base(circ(24, 24, 20)),
                 fill('M26.5 43.6V30h5l.8-6h-5.8v-3.6c0-1.7.5-2.9 3-2.9h3.1v-5.3c-.6-.1-2.4-.2-4.5-.2'
                      '-4.4 0-7.5 2.7-7.5 7.7V24h-5v6h5v13.6z', soft=False)],
    'instagram': [base(rr(6, 6, 36, 36, 11)), ring(24, 24, 8, 3.5), circ(33.5, 14.5, 2.5)],
    'google': [base(circ(24, 24, 20)), line('M33 17.7A11 11 0 1 0 35 24H25', 4)],
    'gmail': [base(rr(4, 9, 40, 30, 7)), line('M8 14l16 12 16-12', 3.5)],
    'maps': [base(fill('M24 4c-8.3 0-15 6.5-15 14.6C9 29.5 24 44 24 44s15-14.5 15-25.4C39 10.5 32.3 4 24 4z')),
             circ(24, 18.5, 5.5)],
    'youtube': [base(rr(3, 9, 42, 30, 10)), fill(PLAY)],
    'assistant': [base(circ(24, 24, 20)), fill(sparkle(24, 24, 13, 2), soft=False),
                  fill(sparkle(35, 13, 4, 0.6), soft=False)],
    'wallet': [base(rr(5, 10, 38, 30, 7)),
               fill('M27 19h11a5 5 0 0 1 5 5v2a5 5 0 0 1-5 5H27a5 5 0 0 1-5-5v-2a5 5 0 0 1 5-5z'
                    'M31 25a2 2 0 1 0 4 0 2 2 0 1 0-4 0z', soft=False, evenodd=True),
               line('M11 16h12')],
    'google_one': [base(circ(24, 24, 20)), line('M20 18l6-4v20', 4)],
    'chat': [base(fill(BUBBLE, soft=False)), circ(16, 22.5, 2.5), circ(24, 22.5, 2.5), circ(32, 22.5, 2.5)],
    'chat_lines': [base(fill('M14 7h20a9 9 0 0 1 9 9v10a9 9 0 0 1-9 9H18l-8 6v-6.7A9 9 0 0 1 5 26V16a9 9 0 0 1 9-9z')),
                   line('M14 18h20M14 25h12')],
    'remote': [base(rr(14, 4, 20, 40, 8)), circ(24, 15, 5),
               circ(19.5, 27, 2), circ(28.5, 27, 2), circ(19.5, 35, 2), circ(28.5, 35, 2)],
    'widgets': [rr(6, 6, 16, 16, 5), base(rr(26, 6, 16, 16, 5), rr(6, 26, 16, 16, 5)), rr(26, 26, 16, 16, 8)],
    'cleaner': [base(fill('M11 14h26l-2.2 25a5 5 0 0 1-5 4.5H18.2a5 5 0 0 1-5-4.5z')),
                line('M7 12h34M19 12V9a3 3 0 0 1 3-3h4a3 3 0 0 1 3 3v3'),
                fill(sparkle(24, 28, 7, 1), soft=False)],
    'compass': [base(circ(24, 24, 20)), fill('M24 9l6 15H18z'), line('M18 24h12l-6 15z', 2.5)],
    'radio': [base(rr(4, 14, 40, 28, 7)), line('M12 14L33 5'), circ(32, 28, 6.5),
              line('M11 23h9M11 30h9M11 37h9', 2.5)],
    'gallery': [base(rr(4, 6, 40, 36, 9)),
                fill('M4 33l11-11a3.5 3.5 0 0 1 5 0l10 10 3.5-3.5a3.5 3.5 0 0 1 5 0L44 33'
                     'a9 9 0 0 1-9 9H13a9 9 0 0 1-9-9z', soft=False),
                circ(32, 17, 4)],
    'photos': [fill('M24 24H8a8 8 0 0 1 16 0z', soft=False),
               base(group('rotate(90 24 24)', fill('M24 24H8a8 8 0 0 1 16 0z', soft=False))),
               group('rotate(180 24 24)', fill('M24 24H8a8 8 0 0 1 16 0z', soft=False)),
               base(group('rotate(270 24 24)', fill('M24 24H8a8 8 0 0 1 16 0z', soft=False)))],
    'notes': [base(rr(8, 4, 32, 40, 8)), line('M16 16h16M16 24h16M16 32h9'),
              fill('M33 30l4-4 3 3-4 4-4 1z')],
    'music': [base(circ(24, 24, 20)), circ(19, 31, 5), line('M24 31V13l8 3')],
    'support': [base(circ(24, 24, 20)), line('M11 29v-5a13 13 0 0 1 26 0v5'),
                rr(8, 25, 8, 13, 4), rr(32, 25, 8, 13, 4)],
    'security': [base(fill('M24 4l16 6v12c0 10.5-6.8 18.5-16 22C14.8 40.5 8 32.5 8 22V10z')),
                 line('M17 24l5 5 9-10', 3.5)],
    'weather': [base(circ(18, 18, 9)),
                fill('M14 40h21a8.5 8.5 0 0 0 1-16.9A11 11 0 0 0 15.5 26 7 7 0 0 0 14 40z')],
    'spotify': [base(circ(24, 24, 20)),
                line('M13 18.5c7-2.2 15-1.7 22 2', 4), line('M14.5 25c5.5-1.6 12-1.2 17.5 1.6', 3.5),
                line('M16 31c4.4-1.1 9-.8 13 1.1', 3)],
    'whatsapp': [base(fill('M24 5a19 19 0 0 0-16.4 28.6L5 43l9.7-2.5A19 19 0 1 0 24 5z')), handset(0.55)],
    'telegram': [base(circ(24, 24, 20)),
                 fill('M8.5 23.5L37.5 12l-5 25.5-9.5-7-4 4.5-.8-7.5z')],
    'scanner': [line('M8 16v-4a4 4 0 0 1 4-4h4M32 8h4a4 4 0 0 1 4 4v4M40 32v4a4 4 0 0 1-4 4h-4'
                     'M16 40h-4a4 4 0 0 1-4-4v-4'),
                base(rr(14, 14, 20, 20, 4)), line('M6 24h36')],
    'app_store': [base(fill(BAG)), line(BAG_HANDLE), line('M24 25v9M20 30l4 4 4-4')],
    'shop': [base(fill(BAG)), line(BAG_HANDLE), line('M18 30c4 3 8 3 12 0')],
    'share': [base(circ(24, 24, 20)), line('M18 33V15M13 20l5-5 5 5M30 15v18M25 28l5 5 5-5')],
    'home': [base(fill('M8 21.5L24 8l16 13.5V38a4 4 0 0 1-4 4H12a4 4 0 0 1-4-4z')),
             line('M5 22L24 6l19 16'), fill('M19 31a5 5 0 0 1 10 0v11H19z', soft=False)],
    'games': [base(rr(4, 14, 40, 22, 11)), line('M14 25h8M18 21v8'), circ(31, 22.5, 2.5), circ(36, 28, 2.5)],
    'twitter': [base(rr(6, 6, 36, 36, 10)), fill('M14 13h6.5L34 35h-6.5z'), line('M33 13L15 35', 2.6)],
    'netflix': [base(rr(4, 4, 40, 40, 12)), fill('M16 10h5.5l5 15V10H32v28h-5.5l-5-15v15H16z')],
    'prime_video': [base(rr(4, 8, 40, 28, 7)), fill('M21 16v12l10-6z'), line('M12 41c8 3 16 3 24 0')],
    'crosshair': [base(circ(24, 24, 20)), ring(24, 24, 9),
                  line('M24 6v7M24 35v7M6 24h7M35 24h7'), circ(24, 24, 2.5)],
    'linkedin': [base(rr(5, 5, 38, 38, 9)), rr(13, 21, 5, 15, 1.5), circ(15.5, 15, 3),
                 fill('M22 21h5v2.3c1-1.6 2.8-2.8 5.4-2.8 4 0 6 2.6 6 7V36h-5v-8'
                      'c0-2.2-.8-3.5-2.7-3.5S27 26 27 28v8h-5z', soft=False)],
    'bank': [base(fill('M7 17L24 7l17 10z'), rr(6, 37, 36, 6, 2)), line('M13 22v11M21 22v11M27 22v11M35 22v11')],
    'docs': [base(fill(DOC, soft=False)), fill(DOC_FOLD, soft=False), line('M16 25h16M16 32h10')],
    'sheets': [base(fill(DOC, soft=False)), fill(DOC_FOLD, soft=False),
               line('M15 23h18v12H15zM24 23v12M15 29h18', 2.5)],
    'music_circle': [base(circ(24, 24, 20)), ring(24, 24, 11, 2.5), fill('M21 19.5v9l7.5-4.5z')],
    'video': [base(rr(4, 8, 40, 32, 8)), fill(PLAY), line('M14 4l4 4M34 4l-4 4', 2.5)],
    'video_call': [base(rr(4, 12, 28, 24, 7)),
                   fill('M35 21l7-4.5c1-.6 2 .1 2 1.2v12.6c0 1.1-1 1.8-2 1.2l-7-4.5z')],
    'cast': [base(rr(6, 8, 36, 28, 6)), line('M6 30a6 6 0 0 1 6 6M6 23a13 13 0 0 1 13 13'), circ(7, 36, 2.5)],
    'screen_recorder': [base(circ(24, 24, 20)), ring(24, 24, 13), circ(24, 24, 7)],
}

TOGGLES = {
    'bluetooth': [line('M15 15l18 17-9 8V8l9 8-18 17', 3.5)],
    'data': [line('M17 38V10M10 17l7-7 7 7M31 10v28M24 31l7 7 7-7')],
    'flight_mode': [fill('M21 6.5c0-1.7 1.3-3 3-3s3 1.3 3 3V18l15 9v4l-15-4.5V36l5 3.5V43l-8-2.5'
                         '-8 2.5v-3.5l5-3.5v-9.5L6 31v-4l15-9z')],
    'wifi_ap': [circ(24, 26, 3.5), line('M17 33a10 10 0 1 1 14 0M11.3 38.7a18 18 0 1 1 25.4 0')],
}
SLASH = line('M8 8l32 32', 3.5)
LOCK_BODY = rr(10, 21, 28, 22, 6)

ALIASES = {
    'browser': ['com.android.browser', 'com.miui.browser', 'com.mi.globalbrowser'],
    'chrome': ['com.android.chrome', 'com.google.android.apps.chrome.Main'],
    'calculator': ['com.android.calculator2', 'com.miui.calculator'],
    'calendar': ['com.android.calendar', 'com.xiaomi.calendar'],
    'camera': ['com.android.camera', 'com.android.camera2', 'com.miui.camera2'],
    'contacts': ['com.android.contacts', 'com.google.android.contacts', 'com.android.providers.contacts'],
    'dialer': ['com.android.contacts.activities.TwelveKeyDialer', 'com.google.android.dialer',
               'com.android.phone', 'com.android.incallui'],
    'call_log': ['com.android.providers.contacts.CallLogProvider'],
    'clock': ['com.android.deskclock'],
    'files': ['com.android.fileexplorer', 'com.mi.android.globalFileexplorer', 'com.google.android.apps.nbu.files'],
    'settings': ['com.android.settings'],
    'recorder': ['com.android.soundrecorder'],
    'sim': ['com.android.stk', 'com.android.providers.telephony'],
    'themes': ['com.android.thememanager'],
    'play_store': ['com.android.vending'],
    'download': ['com.android.providers.downloads', 'com.android.providers.downloads.ui'],
    'facebook': ['com.facebook.katana', 'com.facebook.lite'],
    'instagram': ['com.instagram.android'],
    'google': ['com.google.android.googlequicksearchbox'],
    'gmail': ['com.google.android.gm'],
    'maps': ['com.google.android.apps.maps', 'com.google.android.gms.maps'],
    'youtube': ['com.google.android.youtube', 'com.vanced.android.youtube'],
    'assistant': ['com.google.android.apps.googleassistant'],
    'wallet': ['com.google.android.apps.nbu.paisa.user', 'com.mipay.wallet.in'],
    'google_one': ['com.google.android.apps.subscriptions.red'],
    'chat': ['com.android.mms'],
    'chat_lines': ['com.google.android.apps.messaging', 'com.google.android.apps.messaging-1'],
    'remote': ['com.duokan.phone.remotecontroller'],
    'widgets': ['com.mi.globalminusscreen'],
    'cleaner': ['com.miui.cleaner'],
    'compass': ['com.miui.compass'],
    'radio': ['com.miui.fm', 'com.miui.fmradio'],
    'gallery': ['com.miui.gallery', 'com.miui.gallery.app.Gallery', 'com.android.gallery', 'com.android.gallery3d'],
    'photos': ['com.google.android.apps.photos'],
    'notes': ['com.miui.notes'],
    'music': ['com.miui.player', 'com.android.music'],
    'support': ['com.miui.miservice'],
    'security': ['com.miui.securitycenter', 'com.miui.securitycenter.Main', 'com.miui.securitycenter.MainActivity'],
    'weather': ['com.miui.weather2', 'com.miui.weather2.ActivityWeatherMain'],
    'spotify': ['com.spotify.music'],
    'whatsapp': ['com.whatsapp'],
    'telegram': ['org.telegram.messenger', 'org.thunderdog.challegram'],
    'scanner': ['com.xiaomi.scanner'],
    'app_store': ['com.xiaomi.mipicks'],
    'shop': ['com.mi.global.shop', 'in.amazon.mShop.android.shopping'],
    'share': ['com.xiaomi.midrop'],
    'home': ['com.xiaomi.smarthome'],
    'games': ['com.xiaomi.glgm'],
    'twitter': ['com.twitter.android'],
    'netflix': ['com.netflix.mediaclient'],
    'prime_video': ['com.amazon.avod.thirdpartyclient'],
    'crosshair': ['com.activision.callofduty.shooter'],
    'linkedin': ['com.linkedin.android'],
    'bank': ['com.bankofbaroda.mconnect'],
    'docs': ['com.google.android.apps.docs', 'com.google.androi.apps.docs',
             'com.google.android.apps.docs.app.NewMainProxyActivity'],
    'sheets': ['com.google.android.apps.docs.editors.sheets'],
    'music_circle': ['com.google.android.apps.youtube.music', 'com.vanced.android.apps.youtube.music'],
    'video': ['com.miui.video', 'com.miui.vedioplayer', 'com.google.android.videos'],
    'video_call': ['com.google.android.apps.tachyon'],
    'cast': ['com.google.android.apps.chromecast.app'],
    'screen_recorder': ['com.miui.screenrecorder'],
}


def svg(els):
    return ('<svg width="48" height="48" viewBox="0 0 48 48" fill="none" '
            'xmlns="http://www.w3.org/2000/svg">\n' + '\n'.join(els) + '\n</svg>\n')


def main():
    os.makedirs(OUT, exist_ok=True)
    files = {}
    for key, names in ALIASES.items():
        for name in names:
            files[name] = svg(ICONS[key])
    for key, glyph in TOGGLES.items():
        files[f'status_bar_toggle_{key}_on'] = svg(glyph)
        files[f'status_bar_toggle_{key}_off'] = svg([base(*glyph), SLASH])
    files['status_bar_toggle_lock_on'] = svg([LOCK_BODY, line('M16 21v-5a8 8 0 0 1 16 0v5')])
    files['status_bar_toggle_lock'] = svg([base(LOCK_BODY), line('M16 21v-5a8 8 0 0 1 15.5-2.8')])
    for name, content in files.items():
        with open(os.path.join(OUT, f'{name}.svg'), 'w') as f:
            f.write(content)
    print(f'Wrote {len(files)} icons to {os.path.abspath(OUT)}')


if __name__ == '__main__':
    main()
