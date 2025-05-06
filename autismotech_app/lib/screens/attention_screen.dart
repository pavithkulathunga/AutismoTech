import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class AttentionScreen extends StatefulWidget {
  final String videoPath;

  const AttentionScreen({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen> {
  VideoPlayerController? _videoController;
  CameraController? _cameraController;
  Timer? _captureTimer;
  bool _isCapturing = false;
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: [AVAudioSessionOptions.mixWithOthers],
      ),
    ));

  @override
  void initState() {
    super.initState();
    _initializeFrontCamera();
    _initializeVideoPlayer();
  }

  Future<void> _initializeFrontCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.asset(widget.videoPath);
    await _videoController!.initialize();
    await _videoController!.play();
    _startPeriodicCapture();
    setState(() {});
  }

  void _startPeriodicCapture() {
    _captureTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (_isCapturing || !_videoController!.value.isPlaying) return;
      _isCapturing = true;

      try {
        final file = await _cameraController!.takePicture();
        final bytes = await File(file.path).readAsBytes();
        await _sendToFlaskAPI(bytes);
      } catch (e) {
        print("Capture error: $e");
      } finally {
        _isCapturing = false;
      }
    });
  }

  Future<void> _sendToFlaskAPI(Uint8List imageBytes) async {
    final uri = Uri.parse('http://192.168.236.158:5600/track_focus');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'image.jpg'));

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      print("Response body: $resBody");
      final json = jsonDecode(resBody);

      final isFocused = json['focused'] == true;
      if (!isFocused) {
        await _playAttentionAlert();
      }
    } catch (e, stack) {
      print("API error: $e");
      print("Stacktrace: $stack");
    }
  }

  Future<void> _playAttentionAlert() async {
    try {
      await _audioPlayer.stop(); // avoid overlap
      await _audioPlayer.play(
        AssetSource('audio/pay_attention.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (e) {
      print("Audio play error: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _cameraController?.dispose();
    _captureTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attention Enhancing')),
      body: Column(
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Front camera is active and monitoring attention...',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
        ],
      ),
    );
  }
}
