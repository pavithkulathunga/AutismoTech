import 'package:autismotech_app/screens/diagnosis_screen.dart';
import 'package:autismotech_app/screens/emotion_screen.dart';
import 'package:autismotech_app/screens/home_screen.dart';
import 'package:autismotech_app/screens/music_screen.dart';
import 'package:autismotech_app/screens/games_screen.dart';
import 'package:autismotech_app/screens/happy_screen.dart';
import 'package:autismotech_app/screens/angry_screen.dart';
import 'package:autismotech_app/screens/suprise_screen.dart';
import 'package:autismotech_app/screens/calm_forest_screen.dart';
import 'package:autismotech_app/screens/video_list_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const HomeScreen(),
    '/home': (context) => const HomeScreen(),
    '/diagnosis': (context) => const DiagnosisScreen(),
    '/emotion': (context) => const EmotionScreen(),
    '/music': (context) => const MusicScreen(),
    '/games': (context) => const GamesScreen(),
    '/happy': (context) => const HappyScreen(),
    '/angry': (context) => const AngryScreen(),
    '/surprise': (context) => const SurpriseScreen(),
    '/calmforest': (context) => const CalmForestScreen(),
    '/video-list': (context) => const VideoListScreen(),
  };
}
