import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../../../widgets/iphone_frame.dart';
import 'preset_thumbnail.dart';

// IPhoneFrame adds _bezelH*2 + _btnGap*2 = 26 px wide, 16 px tall
const _frameW = AppConstants.screenWidth + 26;   // 302.92
const _frameH = AppConstants.screenHeight + 16;   // 616
const _displayW = 140.0;
const _displayH = _frameH * _displayW / _frameW;  // ≈ 284.7
const _frameScale = _displayW / _frameW;

/// Loads a preset's JSON, renders a phone-canvas thumbnail, and applies it on tap.
class PresetCard extends ConsumerWidget {
  const PresetCard({
    super.key,
    required this.path,
    required this.index,
  });

  final String path;
  final int index;

  Future<List<LockElement>> _load() async {
    final file = File('$path${Platform.pathSeparator}preset.json');
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LockElement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = path.split(Platform.pathSeparator).last;

    return FutureBuilder<List<LockElement>>(
      future: _load(),
      builder: (context, snapshot) {
        final phoneContent = switch (snapshot.connectionState) {
          ConnectionState.done when snapshot.hasData =>
            PresetThumbnail(
              elements: snapshot.data!,
              thumbnailWidth: AppConstants.screenWidth,
            ),
          ConnectionState.done => _ErrorPlaceholder(),
          _ => _LoadingPlaceholder(),
        };

        return _PresetCardFrame(
          name: name,
          index: index,
          onTap: () async {
            await ref
                .read(lockscreenProvider.notifier)
                .loadPreset('$path${Platform.pathSeparator}preset.json');
            if (context.mounted) Navigator.pop(context);
          },
          phone: SizedBox(
            width: _displayW,
            height: _displayH,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: _frameW,
              maxHeight: _frameH,
              child: Transform.scale(
                scale: _frameScale,
                alignment: Alignment.topLeft,
                child: IPhoneFrame(child: phoneContent),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PresetCardFrame extends StatefulWidget {
  const _PresetCardFrame({
    required this.name,
    required this.index,
    required this.onTap,
    required this.phone,
  });

  final String name;
  final int index;
  final VoidCallback onTap;
  final Widget phone;

  @override
  State<_PresetCardFrame> createState() => _PresetCardFrameState();
}

class _PresetCardFrameState extends State<_PresetCardFrame> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.phone,
              const SizedBox(height: 8),
              Text(
                '#${widget.index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: cs.onSurfaceVariant.withAlpha(180),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  static const _w = 120.0;
  static const _h = _w * AppConstants.screenHeight / AppConstants.screenWidth;

  @override
  Widget build(BuildContext context) => Container(
        width: _w,
        height: _h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1A2744)],
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _ErrorPlaceholder extends StatelessWidget {
  static const _w = 120.0;
  static const _h = _w * AppConstants.screenHeight / AppConstants.screenWidth;

  @override
  Widget build(BuildContext context) => Container(
        width: _w,
        height: _h,
        color: Colors.red.withAlpha(30),
        child: const Center(child: Icon(Icons.error_outline, size: 22)),
      );
}
