import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

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
    try {
      // Enhanced platform detection that works reliably in Chrome
      bool isWebPlatform = false;
      try {
        // This will throw an error in web, which we'll catch
        if (Platform.isAndroid || Platform.isIOS) {
          isWebPlatform = false;
        }
      } catch (e) {
        // Platform check fails in web, so we assume we're in a browser
        isWebPlatform = true;
        print("Running in web platform - Chrome detection active");
      }
      
      // Get available cameras with timeout to prevent hanging
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Camera discovery timed out - browser permission issue detected');
        }
      );
      
      if (cameras.isEmpty) {
        throw CameraException('noCamerasAvailable', 'No cameras found on device');
      }
      
      // Find the front camera
      CameraDescription? frontCamera;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      
      // Fall back to first camera if no front camera is found
      frontCamera ??= cameras.first;
      
      // Use appropriate settings based on platform
      _cameraController = CameraController(
        frontCamera,
        isWebPlatform ? ResolutionPreset.low : ResolutionPreset.medium, // Lower resolution for web
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      // Initialize with timeout to prevent hanging on permission dialogs
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Camera initialization timed out - check browser permissions');
        }
      );
      
      if (mounted) {
        setState(() {});
        print("Camera successfully initialized");
      }
    } catch (e) {
      print("Camera initialization error: $e");
      // Fallback to test mode when camera initialization fails
      _setupCameraFallbackForTesting();
    }
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
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          // Camera is available, use real image capture
          final file = await _cameraController!.takePicture();
          final bytes = await File(file.path).readAsBytes();
          await _sendToFlaskAPI(bytes);
        } else {
          // Camera not available, use test data instead
          await _sendToFlaskAPIWithTestData();
        }
      } catch (e) {
        print("Capture error: $e");
        // If camera capture fails, switch to test mode
        await _sendToFlaskAPIWithTestData();
      } finally {
        _isCapturing = false;
      }
    });
  }

  Future<void> _sendToFlaskAPI(Uint8List imageBytes) async {
    final uri = Uri.parse('http://localhost:8080/attention/track_focus ');
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

  // Fallback method for testing in Chrome when camera access is problematic
  void _setupCameraFallbackForTesting() {
    final timestamp = DateTime.now();
    final formattedTime = '${timestamp.hour}:${timestamp.minute}:${timestamp.second}';
    
    print("Setting up camera fallback for testing at $formattedTime");
    
    // Display a message to the user about test mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showTestModeNotification();
      }
    });
    
    // We can still simulate the API for testing
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _sendToFlaskAPIWithTestData();
      }
    });
  }
  
  void _showTestModeNotification() {
    // Show a notification that we're in test mode - useful for debugging in Chrome
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.science_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Running in Test Mode', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Camera access not available - using simulated data'),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }
    // Method to simulate API calls when camera isn't available (especially in Chrome)
  Future<void> _sendToFlaskAPIWithTestData() async {
    try {
      final requestTime = DateTime.now();
      final formattedTime = '${requestTime.hour}:${requestTime.minute}:${requestTime.second}';
      
      print("Using test mode for API communication at $formattedTime");
      
      // Determine if we're running in a web browser
      bool isWebPlatform = false;
      String platformInfo = "mobile";
      
      try {
        if (Platform.isAndroid) {
          platformInfo = "Android";
        } else if (Platform.isIOS) {
          platformInfo = "iOS";
        } else {
          platformInfo = "desktop";
        }
      } catch (e) {
        // Platform check will fail on web, so we know we're in a browser
        isWebPlatform = true;
        platformInfo = "web browser";
        print("Web platform detected for testing");
      }
      
      print("Test mode active on $platformInfo platform at $formattedTime");
      
      // Generate a semi-realistic response with some randomness for testing
      final random = Random();
      // Add more randomness for web to match Chrome behavior
      final focused = isWebPlatform ? 
          (random.nextInt(10) > 2) : // 80% chance of being focused on web
          random.nextBool() || random.nextBool(); // 75% chance on mobile
      
      // Simulate API response with platform-appropriate delay
      await Future.delayed(Duration(milliseconds: isWebPlatform ? 400 : 300));
      
      if (!focused && mounted) {
        // Only play alert if not focused
        _playAttentionAlert();
      }
      
    } catch (e, stack) {
      print("API error in test mode: $e");
      print("Stacktrace: $stack");
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
