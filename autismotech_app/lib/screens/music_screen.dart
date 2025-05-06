import 'package:flutter/material.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/models/track.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  List<Map<String, String>> playlist = [
    {
      'song': 'Peaceful Piano',
      'artist': 'Calm Collective',
      'image': 'assets/song1.jpg',
      'spotifyUrl': 'spotify:track:4iV5W9uYEdYUVa79Axb7Rh',
    },
    {
      'song': 'Gentle Guitar',
      'artist': 'Acoustic Healing',
      'image': 'assets/song2.jpg',
      'spotifyUrl': 'spotify:track:1301WleyT98MSxVHPZCA6M',
    },
    {
      'song': 'Ocean Breeze',
      'artist': 'Nature Sound',
      'image': 'assets/song3.jpg',
      'spotifyUrl': 'spotify:track:2TpxZ7JUBn3uw46aR7qd6V',
    },
    {
      'song': 'Starry Night',
      'artist': 'Lullaby Sounds',
      'image': 'assets/song4.jpg',
      'spotifyUrl': 'spotify:track:5CtI0qwDJkDQGwXD1H1cLb',
    },
    {
      'song': 'Rainbow Flow',
      'artist': 'Mind Calm',
      'image': 'assets/song5.jpg',
      'spotifyUrl': 'spotify:track:6habFhsOp2NvshLv26DqMb',
    },
    {
      'song': 'Soothing Sky',
      'artist': 'Zen Waves',
      'image': 'assets/song6.jpg',
      'spotifyUrl': 'spotify:track:7GhIk7Il098yCjg4BQjzvb',
    },
  ];

  int? currentlyPlayingIndex; // Track index of currently playing song

  Future<void> _launchSpotifyTrack(String spotifyUri) async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId:
            '2d6de2db9a7e4d6b9964f74350676154', // Replace with actual client ID
        redirectUrl:
            'com.autismotech.app://callback', // Replace with actual redirect URI
      );
      await SpotifySdk.play(spotifyUri: spotifyUri);
    } catch (e) {
      print('Could not play track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Music Therapy for Kids",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Autism Music Therapy Playlist",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: playlist.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(playlist[index]['image']!),
                      ),
                      title: Text(playlist[index]['song']!),
                      subtitle: Text(playlist[index]['artist']!),
                      trailing: IconButton(
                        icon: Icon(
                          currentlyPlayingIndex == index
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          setState(() {
                            currentlyPlayingIndex = index;
                          });
                          _launchSpotifyTrack(playlist[index]['spotifyUrl']!);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
