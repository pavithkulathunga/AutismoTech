import 'package:flutter/material.dart';
import 'attention_screen.dart';

class VideoListScreen extends StatelessWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> videoAssets = const [
    {'name': 'Fairy Tale', 'path': 'assets/videos/video1.mp4'},
    {'name': 'Peter Pan', 'path': 'assets/videos/video2.mp4'},
    {'name': 'The Lazy Girl', 'path': 'assets/videos/video3.mp4'},
    {'name': 'The Tale of Rapunzel', 'path': 'assets/videos/video4.mp4'},
    {'name': 'The Lost Child', 'path': 'assets/videos/video5.mp4'},
    {'name': 'The Mermaid and the Prince', 'path': 'assets/videos/video6.mp4'},
    {'name': 'The Old Man', 'path': 'assets/videos/video7.mp4'},
    {'name': 'Mermaid and the Red Fish', 'path': 'assets/videos/video8.mp4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Video')),
      body: ListView.builder(
        itemCount: videoAssets.length,
        itemBuilder: (context, index) {
          final video = videoAssets[index];
          return ListTile(
            leading: const Icon(Icons.play_circle_fill),
            title: Text(video['name']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AttentionScreen(videoPath: video['path']!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
