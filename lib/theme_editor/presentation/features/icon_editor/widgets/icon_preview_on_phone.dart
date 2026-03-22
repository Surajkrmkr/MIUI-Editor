import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../providers/icon_editor_provider.dart';
import '../../../providers/user_profile_provider.dart';
import 'dart:math';

class IconPreviewOnPhone extends ConsumerWidget {
  const IconPreviewOnPhone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(iconEditorProvider);
    final profile = ref.watch(activeUserProfileProvider);
    if (profile == null || s.iconAssetsPath.isEmpty) {
      return const SizedBox.shrink();
    }

    final offset = AppConstants.iconGridPreviewOffset;
    final count = AppConstants.iconGridPreviewCount;
    final shown = s.iconAssetsPath.skip(offset).take(count).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 50, top: 50, left: 8, right: 8),
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
                          name: name as String,
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
                          name: name as String,
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
        ? [state.bgColors[Random().nextInt(state.bgColors.length)]]
        : [state.bgColor, state.bgColor2];

    return SizedBox(
      width: 45,
      height: 45,
      child: Container(
        margin: EdgeInsets.all(state.margin),
        padding: EdgeInsets.all(state.padding),
        decoration: BoxDecoration(
          border:
              Border.all(width: state.borderWidth, color: state.borderColor),
          borderRadius: BorderRadius.circular(state.radius),
          gradient: LinearGradient(
            begin: state.bgGradStart as Alignment,
            end: state.bgGradEnd as Alignment,
            colors: colors.length > 1 ? colors : [colors.first, colors.first],
          ),
        ),
        child: SvgPicture.asset(
          'assets/icons/${profile.iconFolder}/$name.svg',
          colorFilter: ColorFilter.mode(state.iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
