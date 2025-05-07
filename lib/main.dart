import 'package:asd_detection_flutter/screens/route_manager.dart';
import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'screens/splash_screen.dart'; // Ensure SplashScreen is imported for onUnknownRoute fallback

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASD Detection Flutter',
      theme: appTheme,
      initialRoute: '/splash', // Set SplashScreen as the first route
      onGenerateRoute: RouteManager.generateRoute,
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}