import 'package:asd_detection_flutter/screens/ProgressSummaryScreen.dart';
import 'package:asd_detection_flutter/screens/QuestionsScreen.dart';
import 'package:asd_detection_flutter/screens/SummaryScreen.dart' as summary;
import 'package:asd_detection_flutter/screens/login_screen.dart';
import 'package:asd_detection_flutter/screens/upload_screen.dart';
import 'package:asd_detection_flutter/theme/theme.dart';
import 'package:asd_detection_flutter/theme/colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 0.35, // Adjusted for better responsiveness
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.darkBlue,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBlue),
                  strokeCap: StrokeCap.round,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Loading',
                  style: loadingTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}