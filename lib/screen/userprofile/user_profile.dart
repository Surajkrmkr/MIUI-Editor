import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/userprofile.dart';
import '../landing/export.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  UserProfiles _selectedUser = UserProfiles.defaultUser;

  void onProfileSelected(
      Map<String, String>? user, UserProfiles userType, context) {
    if (user != null) {
      Provider.of<UserProfileProvider>(context, listen: false).setUserProfile =
          userType;
      setState(() {
        _selectedUser = userType;
      });
      _controller.forward(); // Start the fade-out animation
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration:
          const Duration(milliseconds: 600), // Duration of the fade effect
      vsync: this,
    );

    _fadeAnimation = Tween(begin: 1.0, end: 0.0).animate(_controller);

    // Scale animation: from normal size (1.0) to larger size (1.3)
    _scaleAnimation = Tween(begin: 1.0, end: 2.0).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // After the animation is done, navigate to the next screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    heightFactor: 0.6,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(40.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 20.0,
                        mainAxisSpacing: 20.0,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userType = users.keys.elementAt(index);
                        final user = users[userType];
                        return Transform.scale(
                          scale: _selectedUser == userType
                              ? _scaleAnimation.value
                              : 1.0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: () =>
                                    onProfileSelected(user, userType, context),
                                child: Container(
                                  height: 100.0,
                                  width: 100.0,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              "assets/users/${userType.name}.png"),
                                          fit: BoxFit.cover),
                                      borderRadius: BorderRadius.circular(25)),
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              Text(
                                userType.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: const Text("Welcome to MIUI World", textAlign: TextAlign.center),
    );
  }
}
