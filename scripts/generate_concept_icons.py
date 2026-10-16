"""Generates icon sets u6-u15 from one shared glyph library.

Each glyph is described semantically (body / secondary layer / cut-out detail),
and each style renders those roles differently:
  u6 Layered  - solid body, 45% secondary layer, knocked-out details
  u7 Bubbly   - softened one-tone stickers, secondary separated by a gap
  u8 Puffy    - heavily inflated shapes and fat strokes
  u9 Sketch   - clean outlines, secondary and inner details faded
  u10 Liquid (iOS), u11 Glass, u12 Stamp, u13 Retro, u14 Inline, u15 Tilted - see the MODES renderers
"""
from dataclasses import dataclass, replace
import zlib

from icon_kit import ALIASES, bbox, circle, gear, n, rotate, rrect, sparkle, svg_doc, tf, write_set


@dataclass(frozen=True)
class Part:
    d: str
    kind: str  # 'shape' | 'line'
    layer: str  # 'main' | 'sub' | 'cut'
    w: float = 1.0


def S(d, sub=False):
    return Part(d, 'shape', 'sub' if sub else 'main')


def L(d, sub=False, w=1.0):
    return Part(d, 'line', 'sub' if sub else 'main', w)


def CS(d):
    return Part(d, 'shape', 'cut')


def CL(d, w=1.0):
    return Part(d, 'line', 'cut', w)


HANDSET = ('M15 10h5l2.5 7-3.5 3a20 20 0 0 0 9 9l3-3.5 7 2.5v5a3 3 0 0 1-3 3'
           'C21.5 36 12 26.5 12 13a3 3 0 0 1 3-3z')
BUBBLE = ('M24 6C13.5 6 5 13.4 5 22.5c0 4.8 2.4 9.1 6.2 12.1L9.5 42l8.4-4.2'
          'c1.9.5 4 .7 6.1.7 10.5 0 19-7.4 19-16.5S34.5 6 24 6z')
BAG = 'M10 17h28l-1.7 20.5a5 5 0 0 1-5 4.5H16.7a5 5 0 0 1-5-4.5z'
BAG_HANDLE = 'M18 17v-2a6 6 0 0 1 12 0v2'
DOC = tf('M12 4h16l12 12v22a6 6 0 0 1-6 6H14a6 6 0 0 1-6-6V8a4 4 0 0 1 4-4z', .85, 3.6, 3.6)
DOC_FOLD = tf('M28 4v8a4 4 0 0 0 4 4h8', .85, 3.6, 3.6)
PALETTE = tf('M24 4C12.95 4 4 12.95 4 24s8.95 20 20 20c2.2 0 4-1.8 4-4 0-1-.4-1.9-1-2.6'
             '-.6-.7-1-1.6-1-2.6 0-2.2 1.8-4 4-4h4.7C39.4 30.8 44 26.2 44 20.5 44 11.4 35 4 24 4z',
             .85, 3.6, 3.6)
PLANE = tf('M21 6.5c0-1.7 1.3-3 3-3s3 1.3 3 3V18l15 9v4l-15-4.5V36l5 3.5V43l-8-2.5'
           '-8 2.5v-3.5l5-3.5v-9.5L6 31v-4l15-9z', .85, 3.6, 3.6)


def handset(s, cx, cy):
    return tf(HANDSET, s, cx - 24.5 * s, cy - 23 * s)


DISC = circle(24, 24, 17)

GLYPHS = {
    'browser': [S(DISC), CL('M24 7c-4.5 4.5-7 10.5-7 17s2.5 12.5 7 17c4.5-4.5 7-10.5 7-17s-2.5-12.5-7-17z'),
                CL('M8.5 18h31M8.5 30h31')],
    'chrome': [S(DISC), CL(circle(24, 24, 7.5)),
               CL('M24 16.5H40M30.5 27.75l-8 13.86M17.5 27.75l-8-13.86')],
    'calculator': [S(rrect(10, 6, 28, 36, 7)), CS(rrect(15, 11, 18, 8, 2.5))]
                  + [CS(circle(x, y, 2.6)) for y in (27, 35) for x in (17, 24, 31)],
    'calendar': [S(rrect(7, 10, 34, 31, 7)), L('M17 6v6M31 6v6'), CL('M7 19h34')]
                + [CS(circle(x, y, 2.2)) for x, y in ((16, 26), (24, 26), (32, 26), (16, 33), (24, 33))],
    'camera': [S('M17 13l2.5-4h9l2.5 4h6a5 5 0 0 1 5 5v17a5 5 0 0 1-5 5H11a5 5 0 0 1-5-5V18a5 5 0 0 1 5-5z'),
               CL(circle(24, 26, 7)), CS(circle(36, 18.5, 1.6))],
    'contacts': [S(circle(24, 16, 7.5)), S('M10 41a14 13 0 0 1 28 0z', sub=True)],
    'dialer': [S(handset(1.0, 24, 24))],
    'call_log': [S(handset(.8, 21, 27)), L('M29 11h7v7M36 11l-8 8', sub=True)],
    'clock': [S(DISC), CL('M24 14v10l6.5 4.5')],
    'files': [S('M7 14a5 5 0 0 1 5-5h8l4 4h12a5 5 0 0 1 5 5v4H7z', sub=True),
              S('M7 21a4 4 0 0 1 4-4h26a4 4 0 0 1 4 4v15a5 5 0 0 1-5 5H12a5 5 0 0 1-5-5z'), CL('M19 29h10')],
    'settings': [S(gear(R=17, r=13)), CS(circle(24, 24, 5.5))],
    'recorder': [S(rrect(18, 6, 12, 21, 6)), L('M12 22a12 12 0 0 0 24 0M24 34v6M18 40h12', sub=True),
                 CL('M22 13h4M22 19h4', .8)],
    'sim': [S('M15 6h12l8 8v22a5 5 0 0 1-5 5H18a5 5 0 0 1-5-5V8a2 2 0 0 1 2-2z'), CL(rrect(18.5, 21, 11, 13, 2.5), .8)],
    'themes': [S(PALETTE)] + [CS(circle(x, y, 2.6)) for x, y in ((14.6, 23.2), (18, 15), (26.5, 12.5), (33.3, 18))],
    'play_store': [S('M13 9.5c0-1.8 1.9-2.9 3.4-2L37 21.8c1.5.9 1.5 3.1 0 4L16.4 40.5c-1.5.9-3.4-.2-3.4-2z'),
                   CL('M14.5 9.5L27 24 14.5 38.5')],
    'download': [S('M20 7h8v14h6.5L24 33 13.5 21H20z'), S(rrect(11, 37, 26, 5, 2.5), sub=True)],
    'facebook': [S(DISC), CL('M27 41V22a4 4 0 0 1 4-4h3M21 27h12', 1.4)],
    'instagram': [S(rrect(8, 8, 32, 32, 10)), CL(circle(24, 24, 7), 1.2), CS(circle(32.5, 15.5, 2.2))],
    'google': [L('M33.5 16.5A12.5 12.5 0 1 0 36.5 24H25', w=1.4)],
    'gmail': [S(rrect(7, 11, 34, 26, 6)), CL('M11 16l13 10 13-10', 1.1)],
    'maps': [S('M24 6c-7.2 0-13 5.6-13 12.6C11 28 24 42 24 42s13-14 13-23.4C37 11.6 31.2 6 24 6z'),
             CS(circle(24, 18.5, 4.8))],
    'youtube': [S(rrect(6, 11, 36, 26, 9)), CS('M21 18.5v11l9-5.5z')],
    'assistant': [S(sparkle(23, 25, 15, 2.5)), S(sparkle(36, 11, 5.5, .8), sub=True)],
    'wallet': [S(rrect(12, 7, 22, 9, 3), sub=True), S(rrect(7, 12, 34, 27, 6)),
               CL('M41 20h-9a4.5 4.5 0 0 0 0 9h9'), CS(circle(32, 24.5, 1.8))],
    'google_one': [S(DISC), CL('M20.5 18.5l5-3.5v18', 1.3)],
    'chat': [S('M22 20h13a5 5 0 0 1 5 5v15l-6-5H27a5 5 0 0 1-5-5z', sub=True),
             S('M8 12a5 5 0 0 1 5-5h16a5 5 0 0 1 5 5v11a5 5 0 0 1-5 5H15l-7 6z'), CL('M14 14h10M14 20h6')],
    'chat_lines': [S(tf(BUBBLE, .85, 3.6, 3.6))]
                  + [CS(circle(x, 22.7, 2.3)) for x in (17.2, 24, 30.8)],
    'remote': [S(rrect(15, 6, 18, 36, 7)), CL(circle(24, 15, 3.5))]
              + [CS(circle(x, y, 2)) for y in (26, 33) for x in (20, 28)],
    'widgets': [S(rrect(8, 8, 14, 14, 4)), S(rrect(26, 8, 14, 14, 4), sub=True),
                S(rrect(8, 26, 14, 14, 4), sub=True), S(circle(33, 33, 7))],
    'cleaner': [S(rrect(9, 10, 30, 5, 2.5), sub=True),
                S('M12 17h24l-2 19.5a5 5 0 0 1-5 4.5H19a5 5 0 0 1-5-4.5z'), CS(sparkle(24, 29, 6, 1))],
    'compass': [S(DISC), CS('M24 12l5 12H19z'), CL('M19 24l5 12 5-12', .7)],
    'radio': [L('M14 16L31 8', sub=True), S(rrect(7, 16, 34, 24, 6)), CL(circle(31, 28, 5)),
              CL('M13 25h7M13 31h7', .9)],
    'gallery': [S(rrect(7, 10, 34, 28, 6), sub=True),
                S('M7 30l8.5-8.5a3 3 0 0 1 4.2 0L28 30l3.3-3.3a3 3 0 0 1 4.2 0L41 32v1a5 5 0 0 1-5 5H12a5 5 0 0 1-5-5z'),
                S(circle(34, 13, 5))],
    'photos': [S('M24 24H10a7 7 0 0 1 14 0z'), S('M24 24V10a7 7 0 0 1 0 14z', sub=True),
               S('M24 24H38a7 7 0 0 1-14 0z'), S('M24 24V38a7 7 0 0 1 0-14z', sub=True)],
    'notes': [S(rrect(10, 6, 28, 36, 7)), CL('M16 16h16M16 23h16M16 30h9')],
    'music': [S(circle(18, 33, 6)), L('M23 33V10l10 4')],
    'support': [L('M11 28v-4a13 13 0 0 1 26 0v4'), S(rrect(8, 25, 8, 13, 4)), S(rrect(32, 25, 8, 13, 4)),
                L('M36 38c0 3-3 4-8 4', sub=True)],
    'security': [S('M24 6l14 5v11c0 9.5-6 16.5-14 20-8-3.5-14-10.5-14-20V11z'), CL('M18 24l4.5 4.5 8-8.5', 1.1)],
    'weather': [S(circle(18, 18, 8), sub=True), L('M18 5v2M5 18h2M8.8 8.8l1.4 1.4M27.2 8.8l-1.4 1.4', sub=True),
                S('M15 39h19a7.5 7.5 0 0 0 1-14.9A10 10 0 0 0 16.2 26 6.6 6.6 0 0 0 15 39z')],
    'spotify': [S(DISC), CL('M15 19c6-1.8 12.5-1.4 18.5 1.6', 1.25), CL('M16 25c5-1.4 10-1 14.5 1.3', 1.05),
                CL('M17 31c3.8-1 7.6-.7 11 1', .85)],
    'whatsapp': [S('M24 7a17 17 0 0 0-14.7 25.5L7 41l8.7-2.3A17 17 0 1 0 24 7z'), CS(handset(.5, 24, 24))],
    'telegram': [S(DISC), CS('M13 23.5l20-8-3.5 18-6.5-4.5-3 3-.5-5.5z')],
    'scanner': [S(rrect(15, 15, 18, 18, 4), sub=True),
                L('M9 16v-3a4 4 0 0 1 4-4h3M32 9h3a4 4 0 0 1 4 4v3M39 32v3a4 4 0 0 1-4 4h-3'
                  'M16 39h-3a4 4 0 0 1-4-4v-3'), L('M8 24h32')],
    'app_store': [L(BAG_HANDLE, sub=True), S(BAG), CL('M24 24v9M20 29l4 4 4-4')],
    'shop': [L(BAG_HANDLE, sub=True), S(BAG), CL('M19 27c3 3 7 3 10 0')],
    'share': [S(DISC), CL('M18 32V16M13.5 20.5L18 16l4.5 4.5M30 16v16M25.5 27.5L30 32l4.5-4.5')],
    'home': [S('M10 21.5L24 9.5l14 12V37a4 4 0 0 1-4 4H14a4 4 0 0 1-4-4z'), CS('M20 42v-9a4 4 0 0 1 8 0v9z')],
    'games': [S('M16 15h16a9.5 9.5 0 0 1 0 19c-2.6 0-4.4-1.5-5.8-3.3h-4.4C20.4 32.5 18.6 34 16 34a9.5 9.5 0 0 1 0-19z'),
              CL('M12.5 24.5h7M16 21v7'), CS(circle(31, 22, 2)), CS(circle(34.5, 26.5, 2))],
    'twitter': [S('M12 10h7l17 28h-7z'), L('M35 10L13 38', w=.8)],
    'netflix': [L('M17 39V9l14 30V9', w=1.15)],
    'prime_video': [S(rrect(7, 9, 34, 24, 6)), CS('M21 15.5v11l9-5.5z'), L('M12 38c8 3.5 16 3.5 24 0', sub=True)],
    'crosshair': [S(DISC), CL(circle(24, 24, 7)), CL('M24 7v10M24 31v10M7 24h10M31 24h10')],
    'linkedin': [S(rrect(8, 8, 32, 32, 7)), CL('M16 22v11', 1.3), CS(circle(16, 16.5, 2.2)),
                 CL('M22.5 33V22M22.5 26.5c0-3 2-4.5 4.5-4.5s4.5 1.5 4.5 4.5V33', 1.3)],
    'bank': [S('M8 18L24 9l16 9z', sub=True), L('M15 22v11M24 22v11M33 22v11'), S(rrect(8, 36, 32, 5, 2))],
    'docs': [S(DOC), CL(DOC_FOLD, .8), CL('M17 25h14M17 31h9')],
    'sheets': [S(DOC), CL(DOC_FOLD, .8), CL('M16 23h16v11H16zM24 23v11M16 28.5h16', .8)],
    'music_circle': [S(DISC), CL(circle(24, 24, 9.5), .9), CS('M21.5 19.5v9l7.5-4.5z')],
    'video': [L('M16 6l4 5M32 6l-4 5', sub=True), S(rrect(6, 11, 36, 27, 7)), CS('M21 19v11l9-5.5z')],
    'video_call': [S(rrect(6, 13, 26, 22, 6)),
                   S('M34 21l6.5-4c1-.6 2 .1 2 1.2v11.6c0 1.1-1 1.8-2 1.2L34 27z', sub=True)],
    'cast': [S(rrect(8, 9, 32, 26, 5), sub=True), L('M8 30a6 6 0 0 1 6 6M8 23a13 13 0 0 1 13 13'),
             S(circle(9, 36, 2.5))],
    'screen_recorder': [S(DISC), CL(circle(24, 24, 10.5))],
}

TOGGLES = {
    'bluetooth': [L('M16 16l16 15-8 7V10l8 7-16 15', w=1.1)],
    'data': [L('M17 37V11M11 17l6-6 6 6M31 11v26M25 31l6 6 6-6')],
    'flight_mode': [S(PLANE)],
    'wifi_ap': [S(circle(24, 27, 3.5)), L('M17.5 33.5a9.5 9.5 0 1 1 13 0M12 39a17 17 0 1 1 24 0')],
}
SLASH = L('M10 10l28 28')
LOCK_BODY = [S(rrect(11, 22, 26, 19, 6)), CS(circle(24, 31, 2.5))]


@dataclass(frozen=True)
class Style:
    folder: str
    line: float  # main/sub stroke width
    cut: float  # knock-out stroke width
    inflate: float  # extra round stroke around shapes
    sub_opacity: float
    gap: float  # clearance cut from the secondary layer around the body
    outline: bool = False
    mode: str = 'fill'  # fill or a key of MODES


STYLES = [
    Style('u6', line=3.5, cut=3.0, inflate=0, sub_opacity=.45, gap=0, mode='layered'),
    Style('u7', line=4.5, cut=3.2, inflate=4.5, sub_opacity=1, gap=2.2, mode='bubbly'),
    Style('u8', line=5.0, cut=3.0, inflate=3, sub_opacity=.6, gap=0, mode='puffy'),
    Style('u9', line=2.5, cut=2.5, inflate=0, sub_opacity=.45, gap=0, outline=True),
    Style('u10', line=3.4, cut=2.8, inflate=0, sub_opacity=.45, gap=1.5, mode='liquid'),
    Style('u11', line=2.2, cut=2.4, inflate=0, sub_opacity=.5, gap=0, mode='glass'),
    Style('u12', line=3.5, cut=3.0, inflate=0, sub_opacity=.45, gap=0, mode='stamp'),
    Style('u13', line=3.5, cut=3.0, inflate=1, sub_opacity=.45, gap=0, mode='retro'),
    Style('u14', line=3.5, cut=3.0, inflate=0, sub_opacity=.45, gap=1.5, mode='inline'),
    Style('u15', line=3.8, cut=3.0, inflate=1.5, sub_opacity=.45, gap=0, mode='tilted'),
]

ROUND = 'stroke-linecap="round" stroke-linejoin="round"'


def el(p, color, st, extra=0.0, fill_shape=True):
    if p.kind == 'line':
        width = (st.line * min(p.w, 1) if st.outline else st.line * p.w) + extra
        return f'<path d="{p.d}" stroke="{color}" stroke-width="{n(width)}" {ROUND}/>'
    if st.outline and not fill_shape:
        return f'<path d="{p.d}" stroke="{color}" stroke-width="{n(st.line + extra)}" {ROUND}/>'
    stroke = st.inflate + extra
    s = f' stroke="{color}" stroke-width="{n(stroke)}" {ROUND}' if stroke else ''
    return f'<path d="{p.d}" fill="{color}"{s}/>'


def mask(mid, items):
    return (f'<mask id="{mid}" style="mask-type:luminance" maskUnits="userSpaceOnUse" x="0" y="0" '
            f'width="48" height="48"><rect width="48" height="48" fill="white"/>{"".join(items)}</mask>')


def cut_el(p, st):
    if p.kind == 'line':
        return f'<path d="{p.d}" stroke="black" stroke-width="{n(st.cut * p.w)}" {ROUND}/>'
    return f'<path d="{p.d}" fill="black"/>'


def render(parts, st):
    main = [p for p in parts if p.layer == 'main']
    sub = [p for p in parts if p.layer == 'sub']
    cuts = [p for p in parts if p.layer == 'cut']
    defs, out = [], []

    if st.outline:
        if sub:
            occlude = [f'<path d="{p.d}" fill="black"/>' for p in main if p.kind == 'shape']
            defs.append(mask('ms', occlude))
            body = ''.join(el(p, 'white', st, fill_shape=False) for p in sub)
            out.append(f'<g mask="url(#ms)" opacity="{st.sub_opacity}">{body}</g>')
        out += [el(p, 'white', st, fill_shape=False) for p in main]
        if cuts:
            inner = ''.join(f'<path d="{p.d}" fill="white"/>' if p.kind == 'shape'
                            else el(p, 'white', st) for p in cuts)
            out.append(f'<g opacity="0.5">{inner}</g>')
        return svg_doc('\n'.join(defs + out))

    if st.mode != 'fill':
        return svg_doc('\n'.join(MODES[st.mode](parts, st)))
    defs, out = fill_layers(parts, st)
    return svg_doc('\n'.join(defs + out))


def fill_layers(parts, st, pfx=''):
    main = [p for p in parts if p.layer == 'main']
    sub = [p for p in parts if p.layer == 'sub']
    cut_items = [cut_el(p, st) for p in parts if p.layer == 'cut']
    defs, out = [], []
    if sub:
        gap_items = [el(p, 'black', st, extra=2 * st.gap) for p in main] if st.gap else []
        attrs = ''
        if gap_items or cut_items:
            defs.append(mask(f'{pfx}ms', gap_items + cut_items))
            attrs = f' mask="url(#{pfx}ms)"'
        op = f' opacity="{st.sub_opacity}"' if st.sub_opacity < 1 else ''
        out.append(f'<g{attrs}{op}>' + ''.join(el(p, 'white', st) for p in sub) + '</g>')
    body = ''.join(el(p, 'white', st) for p in main)
    if cut_items:
        defs.append(mask(f'{pfx}mc', cut_items))
        out.append(f'<g mask="url(#{pfx}mc)">{body}</g>')
    else:
        out.append(body)
    return defs, out


def stroke(d, w, color='white', extra=''):
    return f'<path d="{d}" stroke="{color}" stroke-width="{n(w)}" {ROUND}{extra}/>'


def liquid(parts, st):
    """iOS-style: SF-weight glyphs, hierarchical layers, Liquid Glass gradient body and top rim light."""
    main = [p for p in parts if p.layer == 'main']
    sub = [p for p in parts if p.layer == 'sub']
    cut_items = [cut_el(p, st) for p in parts if p.layer == 'cut']
    defs = [
        '<linearGradient id="lf" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="white" stop-opacity="0.9"/>'
        '<stop offset="1" stop-color="white" stop-opacity="0.6"/></linearGradient>',
        '<linearGradient id="lr" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="white"/>'
        '<stop offset="0.45" stop-color="white" stop-opacity="0"/></linearGradient>',
    ]
    out = []
    if sub:
        gap = [el(p, 'black', st, extra=2 * st.gap) for p in main]
        defs.append(mask('ms', gap + cut_items))
        out.append(f'<g mask="url(#ms)" opacity="{st.sub_opacity}">'
                   + ''.join(el(p, 'white', st) for p in sub) + '</g>')
    # Lines get flat fills: a zero-height bounding box would void an objectBoundingBox gradient.
    body = ''.join(f'<path d="{p.d}" fill="url(#lf)"/>' if p.kind == 'shape'
                   else stroke(p.d, st.line * p.w, extra=' stroke-opacity="0.9"') for p in main)
    rim = ''.join(f'<path d="{p.d}" stroke="url(#lr)" stroke-width="1.4" {ROUND}/>'
                  for p in main if p.kind == 'shape')
    if cut_items:
        defs.append(mask('mc', cut_items))
        out.append(f'<g mask="url(#mc)">{body}{rim}</g>')
    else:
        out.append(body + rim)
    return ['<defs>' + ''.join(defs[:2]) + '</defs>'] + defs[2:] + out


def glass(parts, st):
    """Frosted translucent bodies with crisp rims and solid inner details."""
    def body(p):
        if p.kind == 'line':
            return stroke(p.d, 3.2 * min(p.w, 1.3))
        return f'<path d="{p.d}" fill="white" fill-opacity="0.3" stroke="white" stroke-width="{n(st.line)}" {ROUND}/>'

    def detail(p):
        if p.kind == 'line':
            return stroke(p.d, st.cut * min(p.w, 1.2))
        return f'<path d="{p.d}" fill="white"/>'

    sub = ''.join(body(p) for p in parts if p.layer == 'sub')
    return [f'<g opacity="{st.sub_opacity}">{sub}</g>' if sub else '',
            ''.join(body(p) for p in parts if p.layer == 'main'),
            ''.join(detail(p) for p in parts if p.layer == 'cut')]


def stamp(parts, st):
    """Glyph punched out of a solid squircle plate."""
    k = .74
    off = 24 * (1 - k)
    items = []
    for layer, color in (('sub', '#777'), ('main', 'black'), ('cut', 'white')):
        for p in parts:
            if p.layer != layer:
                continue
            d = tf(p.d, k, off, off)
            if p.kind == 'shape':
                items.append(f'<path d="{d}" fill="{color}"/>')
            else:
                w = (st.cut if layer == 'cut' else st.line) * p.w * k
                items.append(stroke(d, w, color))
    return [mask('mp', items), f'<g mask="url(#mp)"><path d="{rrect(3, 3, 42, 42, 14)}" fill="white"/></g>']


def retro(parts, st):
    """Solid glyph with an offset print-style drop shadow."""
    k = .88

    def moved(ps, shift):
        return [replace(p, d=tf(p.d, k, 24 * (1 - k) + shift, 24 * (1 - k) + shift)) for p in ps]

    silhouette = [replace(p, layer='main') for p in parts if p.layer != 'cut']
    sdefs, sout = fill_layers(moved(silhouette, 1.8), st, 's')
    fdefs, fout = fill_layers(moved(parts, -1.2), st, 'f')
    return sdefs + fdefs + [f'<g opacity="0.35">{"".join(sout)}</g>'] + fout


def inline(parts, st):
    """Solid body inset inside a thin outer rim, separated by a hairline gap."""
    main = [p for p in parts if p.layer == 'main']
    shapes = [p for p in main if p.kind == 'shape']
    lines = [p for p in main if p.kind == 'line']
    sub = [p for p in parts if p.layer == 'sub']
    cut_items = [cut_el(p, st) for p in parts if p.layer == 'cut']
    band = [stroke(p.d, 4.2, 'black') for p in shapes]
    defs = [mask('mb', band + cut_items), mask('mc', cut_items)]
    out = []
    if sub:
        gap = [el(p, 'black', st, extra=2 * st.gap) for p in main]
        defs.append(mask('ms', gap + cut_items))
        out.append(f'<g mask="url(#ms)" opacity="{st.sub_opacity}">'
                   + ''.join(el(p, 'white', st) for p in sub) + '</g>')
    out.append('<g mask="url(#mb)">' + ''.join(f'<path d="{p.d}" fill="white"/>' for p in shapes) + '</g>')
    out.append('<g mask="url(#mc)">' + ''.join(stroke(p.d, 1.4) for p in shapes)
               + ''.join(stroke(p.d, st.line * p.w) for p in lines) + '</g>')
    return defs + out


def layered(parts, st):
    """Two stacked tones: solid upper layer, translucent lower layer, split by a gap."""
    boxes = [bbox(p.d) for p in parts if p.layer != 'cut']
    y0, y1 = min(b[1] for b in boxes), max(b[3] for b in boxes)
    split = y0 + (y1 - y0) * .55
    cut_items = [cut_el(p, st) for p in parts if p.layer == 'cut']
    top = f'<rect width="48" height="{n(split - 1)}" fill="white"/>'
    bottom = f'<rect y="{n(split + 1)}" width="48" height="{n(48 - split)}" fill="white"/>'

    def region(mid, rect):
        return (f'<mask id="{mid}" style="mask-type:luminance" maskUnits="userSpaceOnUse" x="0" y="0" '
                f'width="48" height="48">{rect}{"".join(cut_items)}</mask>')

    def layer(op_main, op_sub):
        sub = ''.join(el(p, 'white', st) for p in parts if p.layer == 'sub')
        main = ''.join(el(p, 'white', st) for p in parts if p.layer == 'main')
        return f'<g opacity="{op_sub}">{sub}</g><g opacity="{op_main}">{main}</g>'

    return [region('mt', top), region('mbt', bottom),
            f'<g mask="url(#mt)">{layer(1, .45)}</g>',
            f'<g mask="url(#mbt)">{layer(.5, .25)}</g>']


def shine(parts):
    """Glossy highlight arc in the top-left of the largest body, unless it hits a detail."""
    shapes = [(bbox(p.d), p) for p in parts if p.layer == 'main' and p.kind == 'shape']
    if not shapes:
        return []
    (x0, y0, x1, y1), _ = max(shapes, key=lambda s: (s[0][2] - s[0][0]) * (s[0][3] - s[0][1]))
    w, h = x1 - x0, y1 - y0
    if min(w, h) < 16:
        return []
    r = min(w, h) * .16
    sx, sy = x0 + w * .24, y0 + h * .24
    area = (sx - 2, sy - 2, sx + r + 2, sy + r + 5)
    for p in parts:
        if p.layer == 'cut':
            b = bbox(p.d)
            if b[0] < area[2] and b[2] > area[0] and b[1] < area[3] and b[3] > area[1]:
                return []
    return [CL(f'M{n(sx)} {n(sy + r)}a{n(r)} {n(r)} 0 0 1 {n(r)} {n(-r)}', .75),
            CS(circle(sx, sy + r + 3, 1.3))]


def bubbly(parts, st):
    """Chunky one-tone stickers with a glossy highlight cut into the body."""
    defs, out = fill_layers(parts + shine(parts), st)
    return defs + out


def puffy(parts, st):
    """Fluffy plush: solid core wrapped in stacked soft halos for a fuzzy edge."""
    k = .86
    scaled = [replace(p, d=tf(p.d, k, 24 * (1 - k), 24 * (1 - k))) for p in parts]
    fur = [p for p in scaled if p.layer == 'cut' or (p.layer == 'main' and p.kind == 'shape')]
    out, defs = [], []
    for i, (grow, op) in enumerate(((4, .16), (2, .38))):
        halo_st = replace(st, inflate=st.inflate + grow, line=st.line + grow)
        hdefs, hout = fill_layers(fur, halo_st, f'h{i}')
        defs += hdefs
        out.append(f'<g opacity="{op}">{"".join(hout)}</g>')
    cdefs, cout = fill_layers(scaled, st, 'c')
    return defs + cdefs + out + cout


TILT_ANGLES = (-15, -10, -6, 6, 10, 15)


def tilted(parts, st):
    """Solid glyph rotated by a stable per-icon angle, so a grid looks hand-scattered."""
    seed = zlib.crc32(''.join(p.d for p in parts).encode())
    deg = TILT_ANGLES[seed % len(TILT_ANGLES)]
    k = .9
    turned = [replace(p, d=rotate(tf(p.d, k, 24 * (1 - k), 24 * (1 - k)), deg)) for p in parts]
    defs, out = fill_layers(turned, st)
    return defs + out


MODES = {'liquid': liquid, 'glass': glass, 'stamp': stamp, 'retro': retro, 'inline': inline,
         'layered': layered, 'bubbly': bubbly, 'puffy': puffy, 'tilted': tilted}


def as_sub(parts):
    return [replace(p, layer='sub') if p.layer == 'main' else p for p in parts]


def build(st):
    files = {}
    for key, names in ALIASES.items():
        doc = render(GLYPHS[key], st)
        for name in names:
            files[name] = doc
    for key, glyph in TOGGLES.items():
        files[f'status_bar_toggle_{key}_on'] = render(glyph, st)
        files[f'status_bar_toggle_{key}_off'] = render(as_sub(glyph) + [SLASH], st)
    files['status_bar_toggle_lock_on'] = render(LOCK_BODY + [L('M17 22v-5a7 7 0 0 1 14 0v5')], st)
    files['status_bar_toggle_lock'] = render(LOCK_BODY + [L('M17 22v-5a7 7 0 0 1 13.6-2.3')], st)
    return files


if __name__ == '__main__':
    for style in STYLES:
        write_set(style.folder, build(style))
