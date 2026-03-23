import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../landing/landing_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});
  @override
  ConsumerState<UserProfileScreen> createState() => _State();
}

class _State extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  UserProfileType? _selected;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = Tween(begin: 1.0, end: 0.0).animate(_ctrl);
    _scale = Tween(begin: 1.0, end: 2.0).animate(_ctrl)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LandingScreen()));
        }
      });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onSelect(UserProfileType type) {
    ref.read(userProfileProvider.notifier).select(type);
    setState(() => _selected = type);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Welcome to MIUI World'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back to Launcher',
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    ),
    body: Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _fade.value,
          child: FractionallySizedBox(
            widthFactor: 0.7, heightFactor: 0.6,
            child: GridView.builder(
              padding: const EdgeInsets.all(40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 20, mainAxisSpacing: 20),
              itemCount: kUserProfiles.length,
              itemBuilder: (_, i) {
                final type    = kUserProfiles.keys.elementAt(i);
                final profile = kUserProfiles[type]!;
                return Transform.scale(
                  scale: _selected == type ? _scale.value : 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () => _onSelect(type),
                        child: Container(
                          height: 100, width: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(profile.avatarAsset),
                                fit: BoxFit.cover),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(profile.displayName.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
