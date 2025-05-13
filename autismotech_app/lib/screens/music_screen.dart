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

  List<Map<String, String>> playlist = List.generate(12, (index) {
    return {
      'song': 'Track ${index + 1}',
      'artist': 'AutismoTech',
      'image': 'assets/song${(index % 6) + 1}.jpg',
      'file': 'assets/music/m${index + 1}.mp3',
    };
  });

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
              Color.fromARGB(255, 0, 255, 55),
              Color.fromARGB(255, 0, 92, 26),
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
                            Color.fromARGB(255, 5, 209, 255),
                            Color.fromARGB(255, 255, 242, 0),
                            Color.fromARGB(255, 241, 0, 165),
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
                        title: Text(playlist[index]['song']!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(playlist[index]['artist']!),
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
                              icon: const Icon(Icons.skip_previous),
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
                              ),
                              onPressed: () {
                                _playLocalTrack(
                                  playlist[index]['file']!,
                                  index,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
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
