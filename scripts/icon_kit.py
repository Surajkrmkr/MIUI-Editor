"""Shared helpers for the generated icon sets (path math, package aliases, writer)."""
import math
import os
import re

ICONS_ROOT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons')


def n(v):
    return f'{v:.2f}'.rstrip('0').rstrip('.') if v != int(v) else str(int(v))


def circle(cx, cy, r):
    return f'M{n(cx - r)} {n(cy)}a{n(r)} {n(r)} 0 1 0 {n(2 * r)} 0a{n(r)} {n(r)} 0 1 0 {n(-2 * r)} 0z'


def rrect(x, y, w, h, r):
    a = f'a{n(r)} {n(r)} 0 0 1'
    return (f'M{n(x + r)} {n(y)}h{n(w - 2 * r)}{a} {n(r)} {n(r)}v{n(h - 2 * r)}{a} {n(-r)} {n(r)}'
            f'h{n(-(w - 2 * r))}{a} {n(-r)} {n(-r)}v{n(-(h - 2 * r))}{a} {n(r)} {n(-r)}z')


def sparkle(cx, cy, r, k):
    return (f'M{n(cx)} {n(cy - r)}Q{n(cx + k)} {n(cy - k)} {n(cx + r)} {n(cy)}'
            f'Q{n(cx + k)} {n(cy + k)} {n(cx)} {n(cy + r)}Q{n(cx - k)} {n(cy + k)} {n(cx - r)} {n(cy)}'
            f'Q{n(cx - k)} {n(cy - k)} {n(cx)} {n(cy - r)}Z')


def gear(cx=24, cy=24, teeth=8, R=19, r=14.5):
    pts = []
    for i in range(teeth):
        a = i * 360 / teeth
        for rad, off in ((r, -13), (R, -8), (R, 8), (r, 13)):
            t = math.radians(a + off)
            pts.append(f'{n(cx + rad * math.cos(t))} {n(cy + rad * math.sin(t))}')
    return 'M' + 'L'.join(pts) + 'Z'


_TOKEN = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?')
_ARITY = {'M': 2, 'L': 2, 'H': 1, 'V': 1, 'C': 6, 'S': 4, 'Q': 4, 'T': 2, 'A': 7, 'Z': 0}


def tf(d, s, dx=0.0, dy=0.0):
    """Scales then translates a path (absolute and relative commands)."""
    out, cmd, nums = [], None, []

    def flush():
        if cmd is None:
            return
        up, rel = cmd.upper(), cmd.islower()
        k = _ARITY[up]
        if k == 0:
            out.append(cmd)
            return
        for i in range(0, len(nums), k):
            g = nums[i:i + k]
            ox, oy = (0, 0) if rel else (dx, dy)
            if up == 'H':
                g = [g[0] * s + ox]
            elif up == 'V':
                g = [g[0] * s + oy]
            elif up == 'A':
                g = [g[0] * s, g[1] * s, g[2], g[3], g[4], g[5] * s + ox, g[6] * s + oy]
            else:
                g = [v * s + (ox if j % 2 == 0 else oy) for j, v in enumerate(g)]
            out.append(cmd + ' '.join(n(v) for v in g))

    for t in _TOKEN.findall(d):
        if t.isalpha():
            flush()
            cmd, nums = t, []
        else:
            nums.append(float(t))
    flush()
    return ''.join(out)


def rotate(d, deg, ox=24.0, oy=24.0):
    """Rotates a path about (ox, oy); output uses absolute commands only."""
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))

    def rp(x, y):
        x, y = x - ox, y - oy
        return f'{n(ox + x * c - y * s)} {n(oy + x * s + y * c)}'

    out = []
    cx = cy = sx = sy = 0.0
    cmd, nums = None, []

    def flush():
        nonlocal cx, cy, sx, sy
        if cmd is None:
            return
        up, rel = cmd.upper(), cmd.islower()
        k = _ARITY[up]
        if k == 0:
            out.append('Z')
            cx, cy = sx, sy
            return
        for i in range(0, len(nums), k):
            g = nums[i:i + k]
            bx, by = (cx, cy) if rel else (0, 0)
            if up == 'H':
                cx = g[0] + (cx if rel else 0)
                out.append('L' + rp(cx, cy))
            elif up == 'V':
                cy = g[0] + (cy if rel else 0)
                out.append('L' + rp(cx, cy))
            elif up == 'A':
                cx, cy = g[5] + bx, g[6] + by
                out.append(f'A{n(g[0])} {n(g[1])} {n(g[2] + deg)} {int(g[3])} {int(g[4])} {rp(cx, cy)}')
            else:
                pts = [(g[j] + bx, g[j + 1] + by) for j in range(0, k, 2)]
                letter = 'L' if up == 'M' and i > 0 else up
                out.append(letter + ' '.join(rp(x, y) for x, y in pts))
                cx, cy = pts[-1]
            if up == 'M' and i == 0:
                sx, sy = cx, cy

    for t in _TOKEN.findall(d):
        if t.isalpha():
            flush()
            cmd, nums = t, []
        else:
            nums.append(float(t))
    flush()
    return ''.join(out)


def bbox(d):
    """Conservative bounds (x0, y0, x1, y1) from end/control points and arc radii."""
    xs, ys = [], []
    cx = cy = sx = sy = 0.0
    cmd, nums = None, []

    def flush():
        nonlocal cx, cy, sx, sy
        if cmd is None:
            return
        up, rel = cmd.upper(), cmd.islower()
        k = _ARITY[up]
        if k == 0:
            cx, cy = sx, sy
            return
        for i in range(0, len(nums), k):
            g = nums[i:i + k]
            bx, by = (cx, cy) if rel else (0, 0)
            if up == 'H':
                cx = g[0] + (cx if rel else 0)
            elif up == 'V':
                cy = g[0] + (cy if rel else 0)
            elif up == 'A':
                ex, ey = g[5] + bx, g[6] + by
                mx, my = (cx + ex) / 2, (cy + ey) / 2
                xs.extend([mx - g[0], mx + g[0]])
                ys.extend([my - g[1], my + g[1]])
                cx, cy = ex, ey
            else:
                for j in range(0, k, 2):
                    xs.append(g[j] + bx)
                    ys.append(g[j + 1] + by)
                cx, cy = g[k - 2] + bx, g[k - 1] + by
            if up == 'M' and i == 0:
                sx, sy = cx, cy
            xs.append(cx)
            ys.append(cy)

    for t in _TOKEN.findall(d):
        if t.isalpha():
            flush()
            cmd, nums = t, []
        else:
            nums.append(float(t))
    flush()
    return min(xs), min(ys), max(xs), max(ys)


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


def svg_doc(body):
    return ('<svg width="48" height="48" viewBox="0 0 48 48" fill="none" '
            'xmlns="http://www.w3.org/2000/svg">\n' + body + '\n</svg>\n')


def write_set(folder, files):
    out = os.path.join(ICONS_ROOT, folder)
    os.makedirs(out, exist_ok=True)
    for name, content in files.items():
        with open(os.path.join(out, f'{name}.svg'), 'w') as f:
            f.write(content)
    print(f'{folder}: wrote {len(files)} icons')
