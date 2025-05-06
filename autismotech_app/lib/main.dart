
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/video_list_screen.dart';
import 'screens/emotion_screen.dart';
import 'screens/diagnosis_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutismoTech App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/video-list': (context) => const VideoListScreen(),
        '/emotion': (context) => const EmotionScreen(),
        '/diagnosis': (context) => const DiagnosisScreen(),
      },
    );
  }
}
