import 'package:flutter/material.dart';

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  double imageLeftPosition = 0.0;

  void moveImageLeft() {
    setState(() {
      imageLeftPosition = (imageLeftPosition - 20).clamp(
        0.0,
        MediaQuery.of(context).size.width - 200,
      );
    });
  }

  void moveImageRight() {
    setState(() {
      imageLeftPosition = (imageLeftPosition + 20).clamp(
        0.0,
        MediaQuery.of(context).size.width - 200,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    imageLeftPosition = (MediaQuery.of(context).size.width - 400) / 2 - 20;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
      appBar: AppBar(
        title: const Text(
          'Emotion Therapy',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 1,
            left: imageLeftPosition,
            child: SizedBox(
              width: 510,
              height: 1230,
              child: Image.asset('assets/images/eappface.png'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 10.0, 16.0, 260.0),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green[900],
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 6,
                    ),
                    icon: const Icon(Icons.videogame_asset),
                    label: const Text(
                      'Play Games',
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/games');
                      /////link to games screen
                      // Navigate to games screen
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green[900],
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 6,
                    ),
                    icon: const Icon(Icons.music_note),
                    label: const Text(
                      'Music Therapy',
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/music');
                      // Navigate to music therapy screen
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
