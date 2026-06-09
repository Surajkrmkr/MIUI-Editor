import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:morphable_shape/morphable_shape.dart';
import 'package:miui_icon_generator/theme_editor/core/constants/app_constants.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/user_profile.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/icon_editor_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/user_profile_provider.dart';
import '../utils/icon_shape_utils.dart';
import '../utils/icon_visual_utils.dart';
import 'dart:math' as math;

class IconPreviewOnPhone extends ConsumerWidget {
  const IconPreviewOnPhone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(iconEditorProvider);
    final profile = ref.watch(activeUserProfileProvider);
    final iconAssets = ref.watch(iconAssetsProvider);

    return iconAssets.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (profile == null || data.isEmpty) {
          return const SizedBox.shrink();
        }

        const offset = AppConstants.iconGridPreviewOffset;
        const count = AppConstants.iconGridPreviewCount;
        final shown = data.skip(offset).take(count).toList();

        return Padding(
          padding:
              const EdgeInsets.only(bottom: 50, top: 50, left: 8, right: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Clock preview
              const Text('02:36',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w500)),
              // Icon grid preview
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: shown
                        .take(4)
                        .map((name) => _IconCell(
                              name: name,
                              profile: profile,
                              state: s,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: shown
                        .skip(4)
                        .map((name) => _IconCell(
                              name: name,
                              profile: profile,
                              state: s,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell(
      {required this.name, required this.profile, required this.state});
  final String name;
  final UserProfile profile;
  final IconEditorState state;

  @override
  Widget build(BuildContext context) {
    final colors = state.randomColors
        ? [
            state.bgColors[
                math.Random(name.hashCode).nextInt(state.bgColors.length)]
          ]
        : [state.bgColor, state.bgColor2];

    final iconPath = 'assets/icons/${profile.iconFolder}/$name.svg';

    return SizedBox(
      width: 45,
      height: 45,
      child: Container(
        margin: EdgeInsets.all(state.margin),
        child: CustomPaint(
          painter:
              _IconBackgroundPainter(state: state, colors: colors, name: name),
          child: Container(
            padding: EdgeInsets.all(state.padding),
            child: SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(state.iconColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBackgroundPainter extends CustomPainter {
  final IconEditorState state;
  final List<Color> colors;
  final String name;

  _IconBackgroundPainter({required this.state, required this.colors, required this.name});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final rect = Offset.zero & size;
      final shapeBorder = IconShapeUtils.getBorder(
        state.shape,
        state.radius,
        borderWidth: state.borderWidth,
        borderColor: state.borderColor,
        scale: 1.0,
        seed: name.hashCode,
      );

      final path = (shapeBorder as OutlinedShapeBorder).getOuterPath(rect);

      // 1 ── Draw Fill (Gradient or Solid)
      final paint = Paint();
      if (colors.length > 1) {
        paint.shader = LinearGradient(
          begin: state.bgGradStart as Alignment,
          end: state.bgGradEnd as Alignment,
          colors: [colors.first, colors.last],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      } else {
        paint.color = colors.first;
      }
      canvas.drawPath(path, paint);

      // 2 ── Apply Textures
      IconVisualUtils.applyTexture(
        canvas, 
        path, 
        state.texture, 
        rect,
        scale: state.textureScale,
        opacity: state.textureOpacity,
      );

      // 3 ── Apply Effects
      IconVisualUtils.applyEffect(
        canvas, 
        path, 
        state.effect, 
        rect, 
        colors.first,
        intensity: state.effectIntensity,
        blur: state.effectBlur,
        elevation: state.effectElevation,
      );

      // 4 ── Draw Border Stroke
      if (state.borderWidth > 0) {
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = state.borderWidth
          ..color = state.borderColor;
        canvas.drawPath(path, borderPaint);
      }
    } catch (e) {
      debugPrint('Icon grid paint error: $e');
    }
  }

  @override
  bool shouldRepaint(covariant _IconBackgroundPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.colors != colors;
  }
}
