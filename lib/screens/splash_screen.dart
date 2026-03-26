import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToDashboard();
  }

  Future<void> _navigateToDashboard() async {
  await Future.delayed(const Duration(seconds: 3));
  if (!mounted) return;
  // ignore: use_build_context_synchronously
  Navigator.pushReplacementNamed(context, AppRoutes.home);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SizedBox.expand( // Ensures the center is relative to the whole screen
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo made bigger and fits inside a contained box
            Image.asset(
              'assets/images/logo2.png', 
              width: 220, // Increased size
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.eco, 
                color: Colors.white, 
                size: 120
              ),
            ),
            const SizedBox(height: 30),
            // Optional: Add a subtle loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}