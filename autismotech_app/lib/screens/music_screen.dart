import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, String>> playlist = [
    {
      'song': 'Rainbow Journey',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon1.png',
      'file': 'assets/music/m1.mp3',
    },
    {
      'song': 'Gentle Breeze',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon2.png',
      'file': 'assets/music/m2.mp3',
    },
    {
      'song': 'Ocean Whispers',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon3.png',
      'file': 'assets/music/m3.mp3',
    },
    {
      'song': 'Starlight Dreams',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon4.png',
      'file': 'assets/music/m4.mp3',
    },
    {
      'song': 'Peaceful Meadow',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon5.png',
      'file': 'assets/music/m5.mp3',
    },
    {
      'song': 'Magic Clouds',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon6.png',
      'file': 'assets/music/m6.mp3',
    },
    {
      'song': 'Sunny Smiles',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon1.png',
      'file': 'assets/music/m7.mp3',
    },
    {
      'song': 'Moonlight Hugs',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon2.png',
      'file': 'assets/music/m8.mp3',
    },
    {
      'song': 'Happy Heartbeats',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon3.png',
      'file': 'assets/music/m9.mp3',
    },
    {
      'song': 'Calm Forest',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon4.png',
      'file': 'assets/music/m10.mp3',
    },
    {
      'song': 'Bubble Parade',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon5.png',
      'file': 'assets/music/m11.mp3',
    },
    {
      'song': 'Cozy Cuddles',
      'artist': 'AutismoTech',
      'image': 'assets/icons/app_icon6.png',
      'file': 'assets/music/m12.mp3',
    },
  ];

  int? currentlyPlayingIndex; // Track index of currently playing song
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  Future<void> _playLocalTrack(String filePath, int index) async {
    final fileName = filePath.split('/').last;
    if (currentlyPlayingIndex == index && isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('music/$fileName'));
      setState(() {
        currentlyPlayingIndex = index;
        isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 30, 30, 30),
              Color.fromARGB(255, 43, 43, 43),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Autism Music Therapy Playlist",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color:
                          [
                            Color.from(
                              alpha: 1,
                              red: 0,
                              green: 0.392,
                              blue: 0.098,
                            ),
                            Color.from(
                              alpha: 1,
                              red: 0,
                              green: 0.392,
                              blue: 0.098,
                            ),
                            Color.from(
                              alpha: 1,
                              red: 0,
                              green: 0.392,
                              blue: 0.098,
                            ),
                          ][index % 3],
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
                          backgroundImage: AssetImage(
                            playlist[index]['image']!,
                          ),
                        ),
                        title: Text(
                          playlist[index]['song']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist[index]['artist']!,
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              currentlyPlayingIndex == index
                                  ? "${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}"
                                  : "",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                              ),
                              onPressed:
                                  index > 0
                                      ? () => _playLocalTrack(
                                        playlist[index - 1]['file']!,
                                        index - 1,
                                      )
                                      : null,
                            ),
                            IconButton(
                              icon: Icon(
                                currentlyPlayingIndex == index && isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _playLocalTrack(
                                  playlist[index]['file']!,
                                  index,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                              ),
                              onPressed:
                                  index < playlist.length - 1
                                      ? () => _playLocalTrack(
                                        playlist[index + 1]['file']!,
                                        index + 1,
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
