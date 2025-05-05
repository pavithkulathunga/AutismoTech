import 'package:flutter/material.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  List<Map<String, String>> playlist = [
    {'song': 'Song 1', 'artist': 'Artist 1', 'image': 'assets/song1.jpg'},
    {'song': 'Song 2', 'artist': 'Artist 2', 'image': 'assets/song2.jpg'},
    {'song': 'Song 3', 'artist': 'Artist 3', 'image': 'assets/song3.jpg'},
    // Add more songs
  ];

  bool isPlaying = false; // Variable to track play/pause state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Music Playlist",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
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
