import 'package:asd_detection_flutter/screens/login_screen.dart';
import 'package:asd_detection_flutter/screens/register_screen.dart';
import 'package:asd_detection_flutter/screens/splash_screen.dart';
import 'package:flutter/material.dart';


class RouteManager {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      default:
        // You can customize the default route (or show a "Not Found" page)
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}