import 'package:flutter/material.dart';

class HappyScreen extends StatefulWidget {
  const HappyScreen({super.key});

  @override
  State<HappyScreen> createState() => _HappyScreenState();
}

class _HappyScreenState extends State<HappyScreen> {
  List<Map<String, String>> playlist = [
    {
      'song': 'Happy Vibes',
      'artist': 'Calm Beats',
      'image': 'assets/song1.jpg',
    },
    {
      'song': 'Relaxing Waves',
      'artist': 'Nature Tones',
      'image': 'assets/song2.jpg',
    },
    {
      'song': 'Peaceful Mind',
      'artist': 'Zen Sounds',
      'image': 'assets/song3.jpg',
    },
  ];

  bool isPlaying = false; // Variable to track play/pause state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Happy Hills",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.yellowAccent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: ListView.builder(
          itemCount: playlist.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                leading: CircleAvatar(
                  backgroundImage: AssetImage(playlist[index]['image']!),
                  radius: 35,
                ),
                title: Text(
                  playlist[index]['song']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  playlist[index]['artist']!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.deepPurple,
                    size: 35,
                  ),
                  onPressed: () {
                    setState(() {
                      isPlaying = !isPlaying;
                    });
                    // Add functionality to play/pause music here
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
