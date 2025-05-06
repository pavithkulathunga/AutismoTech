import 'package:autismotech_app/screens/diagnosis_screen.dart';
import 'package:autismotech_app/screens/emotion_screen.dart';
import 'package:autismotech_app/screens/home_screen.dart';
import 'package:autismotech_app/screens/music_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const HomeScreen(),
    '/home': (context) => const HomeScreen(),
    '/diagnosis': (context) => const DiagnosisScreen(),
    '/emotion': (context) => const EmotionScreen(),
    '/music': (context) => const MusicScreen(),
  };
}
