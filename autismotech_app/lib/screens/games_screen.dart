import 'package:flutter/material.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Games Screen"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple, Colors.deepPurpleAccent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emotion Adventure Map',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildEmotionCard(
                      context,
                      icon: Icons.emoji_emotions,
                      title: 'Happy Hills',
                      color: Colors.yellow.shade700,
                      onTap: () {
                        Navigator.pushNamed(context, '/happy');
                      },
                    ),
                    _buildEmotionCard(
                      context,
                      icon: Icons.whatshot,
                      title: 'Angry Volcano',
                      color: Colors.redAccent,
                      onTap: () {},
                    ),
                    _buildEmotionCard(
                      context,
                      icon: Icons.wb_incandescent,
                      title: 'Surprise Cave',
                      color: Colors.orangeAccent,
                      onTap: () {},
                    ),
                    _buildEmotionCard(
                      context,
                      icon: Icons.self_improvement,
                      title: 'Calm Forest',
                      color: Colors.green,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildEmotionCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class GameSectionScreen extends StatelessWidget {
  const GameSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Happy Hills Game"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Game is starting...',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}
