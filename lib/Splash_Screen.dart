import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'Login_Screen.dart';
import 'Home_Screen.dart';

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  Future<bool> _checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Simulate splash screen delay
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashUI();
        } else {
          // Navigate after first frame to avoid context issues
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    snapshot.data! ? MyHomeScreen() : MyLoginScreen(),
              ),
            );
          });

          return const SizedBox.shrink(); // Placeholder while navigating
        }
      },
    );
  }

  Widget _buildSplashUI() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFFD3D3D3),
              Color(0xFFA9A9A9),
            ],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Lottie.asset(
              "assets/animations/camera_animation.json",
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
