import 'package:flutter/material.dart';
import '../../domain/entities/element_widget.dart';

class LockWidget {
  const LockWidget({
    required this.name,
    required this.description,
    required this.elements,
    this.category = 'General',
  });

  final String name;
  final String description;
  final List<LockElement> elements;
  final String category;
}

final List<LockWidget> kPresetWidgets = [
  // ── Date/Calendar ──────────────────────────────────────────────────────────
  const LockWidget(
    name: 'Glass Calendar',
    description: 'Frosted glass effect calendar with adaptive background.',
    category: 'Date',
    elements: [
      LockElement(
        type: ElementType.containerBG1,
        width: 340,
        height: 120,
        radius: 24,
        dx: 0, dy: -300,
        color: Color(0x30FFFFFF),
        colorSecondary: Color(0x10FFFFFF),
        blurRadius: 15,
        borderWidth: 1,
        borderColor: Color(0x20FFFFFF),
      ),
      LockElement(
        type: ElementType.monthClock,
        dx: -80, dy: -300,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      LockElement(
        type: ElementType.dateClock,
        dx: 60, dy: -300,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ],
  ),

  // ── Music ──────────────────────────────────────────────────────────────────
  const LockWidget(
    name: 'Floating Music',
    description: 'Minimal music player with adaptive blur.',
    category: 'Music',
    elements: [
      LockElement(
        type: ElementType.containerBG2,
        width: 380,
        height: 100,
        radius: 30,
        dx: 0, dy: 300,
        color: Color(0x40000000),
        blurRadius: 20,
      ),
      LockElement(
        type: ElementType.musicBg,
        dx: -130, dy: 300,
        scale: 0.4,
      ),
      LockElement(
        type: ElementType.musicPlay,
        dx: 0, dy: 300,
        scale: 0.5,
      ),
      LockElement(
        type: ElementType.musicNext,
        dx: 80, dy: 300,
        scale: 0.4,
      ),
      LockElement(
        type: ElementType.musicPrev,
        dx: -80, dy: 300,
        scale: 0.4,
      ),
    ],
  ),

  // ── Weather ────────────────────────────────────────────────────────────────
  const LockWidget(
    name: 'Adaptive Weather',
    description: 'Clean weather widget that adapts to dark/light wallpapers.',
    category: 'Weather',
    elements: [
      LockElement(
        type: ElementType.containerBG3,
        width: 180,
        height: 180,
        radius: 40,
        dx: 0, dy: 0,
        color: Color(0x20000000),
        blurRadius: 10,
      ),
      LockElement(
        type: ElementType.weatherIconClock,
        dx: 0, dy: -30,
        scale: 1.5,
      ),
      LockElement(
        type: ElementType.weatherTemp,
        dx: 0, dy: 40,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ],
  ),

  // ── Shortcuts ──────────────────────────────────────────────────────────────
  const LockWidget(
    name: 'Quick Dock',
    description: 'Adaptive dock for your most used apps.',
    category: 'Shortcuts',
    elements: [
      LockElement(
        type: ElementType.containerBG4,
        width: 400,
        height: 80,
        radius: 20,
        dx: 0, dy: 450,
        color: Color(0x15FFFFFF),
        blurRadius: 25,
      ),
      LockElement(type: ElementType.dialerIcon, dx: -140, dy: 450, scale: 0.35),
      LockElement(type: ElementType.whatsAppIcon, dx: -70, dy: 450, scale: 0.35),
      LockElement(type: ElementType.cameraIcon, dx: 0, dy: 450, scale: 0.35),
      LockElement(type: ElementType.instagramIcon, dx: 70, dy: 450, scale: 0.35),
      LockElement(type: ElementType.galleryIcon, dx: 140, dy: 450, scale: 0.35),
    ],
  ),
  // ── Designer Series ───────────────────────────────────────────────────────
  const LockWidget(
    name: 'Desert Minimal',
    description: 'Ultra-thin minimal clock and date from "Black & White Desert" theme.',
    category: 'Designer Series',
    elements: [
      LockElement(
        type: ElementType.hourClock,
        dx: -380, dy: -300,
        fontSize: 120,
        fontWeight: FontWeight.w100,
        color: Colors.white,
      ),
      LockElement(
        type: ElementType.minClock,
        dx: -200, dy: -300,
        fontSize: 120,
        fontWeight: FontWeight.w100,
        color: Colors.white,
      ),
      LockElement(
        type: ElementType.weekClock,
        dx: -430, dy: -180,
        fontSize: 45,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
      LockElement(
        type: ElementType.dateClock,
        dx: -430, dy: -110,
        fontSize: 45,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    ],
  ),

  const LockWidget(
    name: 'Glass Music Dock',
    description: 'Premium music player with frosted glass and progress mask.',
    category: 'Designer Series',
    elements: [
      LockElement(
        type: ElementType.containerBG1,
        width: 380, height: 180, radius: 40,
        dx: 0, dy: 300,
        color: Color(0x30000000),
        blurRadius: 30,
        borderWidth: 1,
        borderColor: Color(0x20FFFFFF),
      ),
      LockElement(type: ElementType.musicPrev, dx: -100, dy: 300, scale: 0.6),
      LockElement(type: ElementType.musicPlay, dx: 0, dy: 300, scale: 0.8),
      LockElement(type: ElementType.musicNext, dx: 100, dy: 300, scale: 0.6),
    ],
  ),
  const LockWidget(
    name: 'Bento Desert',
    description: 'High-quality bento-box layout with analog clock, calendar, and weather.',
    category: 'Designer Series',
    elements: [
      // ── ANALOG CLOCK (Top Left) ───────────────────────────────────────────
      LockElement(
        type: ElementType.containerBG1,
        width: 380, height: 380, radius: 60,
        dx: -280, dy: -380,
        color: Colors.white,
      ),
      LockElement(type: ElementType.analogClockBg, dx: -280, dy: -380, width: 340, height: 340, path: r'time3\time'),
      LockElement(type: ElementType.analogHourHand, dx: -280, dy: -380, width: 200, height: 200, path: r'zz2'),
      LockElement(type: ElementType.analogMinHand, dx: -280, dy: -380, width: 200, height: 200, path: r'zz4'),
      LockElement(type: ElementType.analogSecHand, dx: -280, dy: -380, width: 200, height: 200, path: r'zz3'),

      // ── DIGITAL CLOCK & DATE (Top Right) ──────────────────────────────────
      LockElement(
        type: ElementType.containerBG2,
        width: 380, height: 220, radius: 40,
        dx: 280, dy: -460,
        color: Color(0xFFE0E0E0),
      ),
      LockElement(type: ElementType.hourClock, dx: 180, dy: -490, fontSize: 60, color: Colors.black, fontWeight: FontWeight.w300),
      LockElement(type: ElementType.minClock, dx: 380, dy: -490, fontSize: 60, color: Colors.black, fontWeight: FontWeight.w300),
      LockElement(type: ElementType.dateClock, dx: 280, dy: -420, fontSize: 24, color: Colors.black54),

      // ── WEATHER (Middle Right) ─────────────────────────────────────────────
      LockElement(
        type: ElementType.containerBG3,
        width: 380, height: 180, radius: 40,
        dx: 280, dy: -240,
        color: Color(0xFF1A1A1A),
      ),
      LockElement(type: ElementType.weatherIconClock, dx: 160, dy: -240, scale: 2.0),
      LockElement(type: ElementType.weatherTemp, dx: 340, dy: -260, fontSize: 32, color: Colors.white),
      LockElement(type: ElementType.weatherDesc, dx: 340, dy: -220, fontSize: 14, color: Colors.white70),

      // ── SHORTCUTS (Center Left) ───────────────────────────────────────────
      LockElement(type: ElementType.containerBG4, width: 180, height: 350, radius: 40, dx: -380, dy: 20, color: Colors.white),
      LockElement(type: ElementType.dialerIcon, dx: -380, dy: 20, scale: 0.5),
      
      LockElement(type: ElementType.containerBG5, width: 180, height: 350, radius: 40, dx: -180, dy: 20, color: Colors.white),
      LockElement(type: ElementType.themeIcon, dx: -180, dy: 20, scale: 0.5),

      // ── CALENDAR GRID (Center Right) ──────────────────────────────────────
      LockElement(
        type: ElementType.containerBG1, // Reuse or add more BG indices
        width: 380, height: 280, radius: 40,
        dx: 280, dy: 20,
        color: Colors.white,
      ),
      LockElement(type: ElementType.calendarGrid, dx: 280, dy: 20, color: Colors.black, colorSecondary: Colors.black12),

      // ── TOGGLE & TEXT ──────────────────────────────────────────────────────
      LockElement(type: ElementType.toggleSwitch, dx: -400, dy: 220),
      LockElement(type: ElementType.normalText1, text: 'Day and night', dx: -200, dy: 220, fontSize: 16, color: Colors.black87),

      // ── APPS (Bottom Center) ──────────────────────────────────────────────
      LockElement(type: ElementType.containerBG2, width: 180, height: 160, radius: 40, dx: 180, dy: 280, color: Colors.white),
      LockElement(type: ElementType.galleryIcon, dx: 180, dy: 280, scale: 0.4),

      LockElement(type: ElementType.containerBG3, width: 180, height: 160, radius: 40, dx: 380, dy: 280, color: Colors.white),
      LockElement(type: ElementType.missedCalls, dx: 380, dy: 280, scale: 0.4), // Placeholder for notes/doc icon

      // ── DRINKING WATER (Bottom Left) ──────────────────────────────────────
      LockElement(type: ElementType.containerBG4, width: 380, height: 320, radius: 40, dx: -280, dy: 600, color: Color(0xFFE0E0E0)),
      LockElement(type: ElementType.stepsCount, dx: -280, dy: 600, fontSize: 32, fontWeight: FontWeight.bold), // Using steps as % placeholder

      // ── MUSIC DISC (Bottom Right) ──────────────────────────────────────────
      LockElement(type: ElementType.containerBG5, width: 380, height: 180, radius: 90, dx: 280, dy: 480, color: Colors.white),
      LockElement(type: ElementType.musicBg, dx: 280, dy: 480, scale: 0.8),
      
      // ── CAMERA & BATTERY (Bottom Edge) ────────────────────────────────────
      LockElement(type: ElementType.containerBG1, width: 380, height: 140, radius: 70, dx: -280, dy: 880, color: Colors.white),
      LockElement(type: ElementType.cameraIcon, dx: -380, dy: 880, scale: 0.6),
      LockElement(type: ElementType.normalText2, text: 'CAMERA', dx: -180, dy: 880, fontSize: 20, fontWeight: FontWeight.w900),

      LockElement(type: ElementType.containerBG2, width: 380, height: 250, radius: 40, dx: 280, dy: 820, color: Colors.white),
      LockElement(type: ElementType.batteryLevel, dx: 280, dy: 780, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
      LockElement(type: ElementType.progressBar, dx: 280, dy: 850, width: 300),
    ],
  ),
];
