import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:lottie/lottie.dart';

class AttentionScreen extends StatefulWidget {
  final String videoPath;

  const AttentionScreen({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  CameraController? _cameraController;
  Timer? _captureTimer;
  Timer? _videoPlaybackTimer; // New timer just for ensuring video playback
  bool _isCapturing = false;
  bool _showControls = false; // New variable to track if video controls are visible
  Timer? _controlsTimer; // Timer to auto-hide controls after a period of inactivity
  bool _userPaused = false; // New flag to track if user manually paused the video

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late AnimationController _scaleController;

  // Animation values
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _floatingAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _bounceAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  // UI state tracking
  bool _isFocused = true;
  bool _isVideoPlaying = false;
  double _videoProgress = 0.0;
  bool _showFocusedCelebration = false;
  int _focusedStreak = 0;

  // Sensory-friendly color modes  // Color options for sensory-friendly display
  final Color _backgroundColorWarm = const Color(0xFFFFF8E1);

  // Colors for visual aids
  final List<Color> _rainbowColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  int _colorIndex = 0;
  Timer? _colorChangeTimer;

  final AudioPlayer _audioPlayer =
      AudioPlayer()..setAudioContext(
        AudioContext(
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
        ),
      );

  @override
  void initState() {
    super.initState();

    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize animations
    _setupAnimations();

    // Start color cycling for interactive elements
    _startColorCycling();

    // Start camera and video player
    _initializeFrontCamera();
    _initializeVideoPlayer();
  }

  void _startColorCycling() {
    _colorChangeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _colorIndex = (_colorIndex + 1) % _rainbowColors.length;
      });
    });
  }

  void _setupAnimations() {
    // Pulsing animation for attention indicators
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Floating animation for elements
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.05),
    ).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Fade animation for alerts
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Bounce animation for celebrations
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _bounceAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.2),
    ).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Rotation animation for visual interest
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    // Scale animation for UI elements
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start scale-in animation for UI
    _scaleController.forward();
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
          throw TimeoutException(
            'Camera discovery timed out - browser permission issue detected',
          );
        },
      );

      if (cameras.isEmpty) {
        throw CameraException(
          'noCamerasAvailable',
          'No cameras found on device',
        );
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
        isWebPlatform
            ? ResolutionPreset.low
            : ResolutionPreset.medium, // Lower resolution for web
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize with timeout to prevent hanging on permission dialogs
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException(
            'Camera initialization timed out - check browser permissions',
          );
        },
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
    await _videoController!.initialize();    // Set up video progress tracking with enhanced continuous playback
    _videoController!.addListener(() {
      // Only force continuous playback if controls aren't showing and user hasn't manually paused
      if (!_showControls &&
          !_videoController!.value.isPlaying &&
          _videoController!.value.isInitialized &&
          !_videoController!.value.isCompleted &&
          !_userPaused) {
        _videoController!.play();
        print("Forcing video to continue playing");
      }

      // Only update _isVideoPlaying if it's different from current value to avoid rebuild loops
      if (_videoController!.value.isPlaying != _isVideoPlaying) {
        setState(() {
          _isVideoPlaying = _videoController!.value.isPlaying;
        });

        print(
          "Video playing state changed to: ${_videoController!.value.isPlaying}",
        );
      }

      // Update video progress
      if (_videoController!.value.isInitialized &&
          _videoController!.value.duration.inMilliseconds > 0) {
        final newProgress =
            _videoController!.value.position.inMilliseconds /
            _videoController!.value.duration.inMilliseconds;
        // Only update if progress has changed significantly to avoid unnecessary rebuilds
        if ((newProgress - _videoProgress).abs() > 0.01) {
          setState(() {
            _videoProgress = newProgress;
          });
        }
      }

      // Loop video when completed - improved to avoid multiple calls
      if (_videoController!.value.position >=
          _videoController!.value.duration -
              const Duration(milliseconds: 300)) {
        print("Video reached end - looping");
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      }
    });

    // Always set looping to true to ensure continuous playback
    _videoController!.setLooping(true);

    // Set a higher volume to ensure better audio experience
    _videoController!.setVolume(1.0);

    // Start playing and ensure it continues
    await _videoController!.play();
      // Setup a dedicated timer to ensure video keeps playing, but only when controls aren't showing
    _videoPlaybackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_videoController != null && 
          _videoController!.value.isInitialized && 
          !_videoController!.value.isPlaying && 
          !_videoController!.value.isCompleted &&
          !_showControls &&
          !_userPaused) {  // Don't force playback if user manually paused
        print("Continuous video check: Video not playing, restarting");
        _videoController!.play();
      }
    });
    
    _startPeriodicCapture();
    
    setState(() {
      _isVideoPlaying = true;
    });
    
    // Extra check to make sure video starts playing
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && !_showControls) {
        _ensureVideoIsPlaying();
      }
    });
    
    // Additional regular checks to ensure video keeps playing
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_showControls) {
        _ensureVideoIsPlaying();
      }
    });
  }

  void _startPeriodicCapture() {
    _captureTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Don't capture if already capturing
      if (_isCapturing) {
        print("Skipping capture: already capturing");
        return;
      }      // Force continuous video playback (highest priority)
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        print("Video not playing, restarting playback");
        _videoController!.play(); // No await to prevent blocking
      }

      _isCapturing = true;

      try {        // Another check to ensure video stays playing before camera capture
        if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
          _videoController!.play();
        }

        if (_cameraController != null &&
            _cameraController!.value.isInitialized) {
          // Camera is available, use real image capture
          final file = await _cameraController!.takePicture();
          final bytes = await File(file.path).readAsBytes();          // Check again after picture capture
          if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
            _videoController!.play();
          }

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
        _isCapturing = false;        // Final check to ensure video is still playing after all processing
        if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
          _videoController!.play();
        }
      }
    });
  }
  @override
  void dispose() {
    // Unregister from lifecycle events
    WidgetsBinding.instance.removeObserver(this);

    _videoController?.dispose();
    _cameraController?.dispose();
    _captureTimer?.cancel();
    _videoPlaybackTimer?.cancel(); // Cancel the video playback timer
    _controlsTimer?.cancel(); // Cancel the controls auto-hide timer
    _colorChangeTimer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // No changes needed to the didChangeAppLifecycleState method
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);    // Resume video playback when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      if (_videoController != null &&
          _videoController!.value.isInitialized &&
          !_videoController!.value.isPlaying &&
          !_userPaused) {
        print("App resumed - ensuring video is playing");
        _videoController!.play();
      }
    }
  }

  Future<void> _sendToFlaskAPI(Uint8List imageBytes) async {    // First ensure video keeps playing before API call
    if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
      _videoController!.play();
    }

    final uri = Uri.parse('http://192.168.1.5:5000/attention/track_focus');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      print("Response body: $resBody");
      final json = jsonDecode(resBody);

      final isFocused = json['focused'] == true;      // Ensure video is still playing after API response
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        _videoController!.play();
      }

      // Track focus streak
      if (isFocused && !_isFocused) {
        // Just regained focus
        setState(() {
          _focusedStreak = 1;
        });
      } else if (isFocused) {
        // Continued focus
        setState(() {
          _focusedStreak++;

          // Celebrate every 3 consecutive focused checks
          if (_focusedStreak % 3 == 0) {
            _showFocusedCelebration = true;
            _bounceController.reset();
            _bounceController.forward();

            // Hide celebration after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showFocusedCelebration = false;
                });                // Ensure video is still playing after celebration
                if (_videoController != null &&
                    !_videoController!.value.isPlaying &&
                    !_userPaused) {
                  _videoController!.play();
                }
              }
            });

            // Play a short positive sound
            _audioPlayer.stop();
            _audioPlayer.play(
              AssetSource('audio/good_job.mp3'),
              mode: PlayerMode.lowLatency,
              volume: 0.7,
            );
          }
        });
      } else {
        // Lost focus
        setState(() {
          _focusedStreak = 0;
          _showFocusedCelebration = false;
        });
      }

      setState(() {
        _isFocused = isFocused;
      });

      if (!isFocused) {
        await _playAttentionAlert();
      }      // Final check to ensure video is playing after all processing
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        _videoController!.play();
      }
    } catch (e, stack) {
      print("API error: $e");
      print("Stacktrace: $stack");

      // Even on error, ensure video is playing if not user-paused
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        _videoController!.play();
      }
    }
  }

  Future<void> _playAttentionAlert() async {
    try {
      await _audioPlayer.stop(); // avoid overlap
      await _audioPlayer.play(
        AssetSource('audio/pay_attention.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );      // Ensure video keeps playing
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        _videoController!.play();
      }

      // Trigger fade-in animation for alert
      _fadeController.forward(from: 0.0);

      // Visual stimulus to regain attention - pulse animation
      _pulseController.stop();
      _pulseController.reset();
      _pulseController.repeat(reverse: true);

      // Keep the alert visible for a while
      await Future.delayed(const Duration(seconds: 2));

      // Fade out the alert
      _fadeController.reverse();
    } catch (e) {
      print("Audio play error: $e");
    }
  }

  // Fallback method for testing in Chrome when camera access is problematic
  void _setupCameraFallbackForTesting() {
    final timestamp = DateTime.now();
    final formattedTime =
        '${timestamp.hour}:${timestamp.minute}:${timestamp.second}';

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
                  const Text(
                    'Running in Test Mode',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Camera access not available - using simulated data',
                  ),
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
      final formattedTime =
          '${requestTime.hour}:${requestTime.minute}:${requestTime.second}';

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

      print("Test mode active on $platformInfo platform at $formattedTime");      // Make sure video is playing before API simulation
      if (_videoController != null &&
          _videoController!.value.isInitialized &&
          !_videoController!.value.isPlaying &&
          !_userPaused) {
        print("Ensuring video is playing during test");
        _videoController!.play(); // No await to prevent blocking
      }

      // Generate a semi-realistic response with some randomness for testing
      final random = Random();
      // Add more randomness for web to match Chrome behavior
      final focused =
          isWebPlatform
              ? (random.nextInt(10) > 2)
              : // 80% chance of being focused on web
              random.nextBool() || random.nextBool(); // 75% chance on mobile

      // Simulate API response with platform-appropriate delay
      await Future.delayed(Duration(milliseconds: isWebPlatform ? 400 : 300));      // Make sure video is still playing after delay
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        _videoController!.play();
      }

      setState(() {
        _isFocused = focused;
      });

      if (!focused && mounted) {
        // Only play alert if not focused
        _playAttentionAlert();
      }      // Final check to ensure video is still playing
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        _videoController!.play();
      }
    } catch (e, stack) {
      print("API error in test mode: $e");
      print("Stacktrace: $stack");

      // Even on error, ensure video is playing if not user-paused
      if (_videoController != null && !_videoController!.value.isPlaying && !_userPaused) {
        _videoController!.play();
      }
    }
  }  // Helper method to ensure video is playing - can be called from anywhere
  void _ensureVideoIsPlaying() {
    if (_videoController != null && 
        _videoController!.value.isInitialized && 
        !_videoController!.value.isPlaying &&
        !_videoController!.value.isCompleted &&
        !_showControls &&
        !_userPaused) {  // Only force play if controls aren't showing and user didn't pause
      print("Manual check - ensuring video is playing");
      _videoController!.play();
      
      // Schedule another check in the near future for robustness
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _videoController != null && !_videoController!.value.isPlaying && !_showControls && !_userPaused) {
            _videoController!.play();
          }
        });
      }
    }
  }

  // Reset the controls auto-hide timer
  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  // Helper method to build a control button with animations
  Widget _buildControlButton(
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Icon(
            icon,
            size: size * 0.7,
            color: color,
          ),
        ),
      ),
    );
  }

  // Custom video progress bar with interactive seeking
  Widget _buildCustomProgressBar() {
    final duration = _videoController!.value.duration;
    final position = _videoController!.value.position;
    
    // Format the position and duration
    final positionText = _formatDuration(position);
    final durationText = _formatDuration(duration);
    
    return Column(
      children: [
        // Time indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                positionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                durationText,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Slider for seeking
        SliderTheme(
          data: SliderThemeData(
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 4,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
            trackHeight: 8,
            activeTrackColor: _rainbowColors[_colorIndex],
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: _rainbowColors[_colorIndex],
            overlayColor: _rainbowColors[_colorIndex].withOpacity(0.3),
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble().clamp(
              0.0,
              duration.inMilliseconds.toDouble(),
            ),
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              final newPosition = Duration(milliseconds: value.toInt());
              _videoController!.seekTo(newPosition);
              _resetControlsTimer();
            },
          ),
        ),
      ],
    );
  }

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 600;
    final isPad = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      backgroundColor: _backgroundColorWarm,
      appBar: AppBar(
        backgroundColor: AppColors.Attention,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: isSmallScreen ? 24 : 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Watch Time!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 24 : 28,
                fontFamily: 'Comic Sans MS',
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: isSmallScreen ? 24 : 28,
              ),
            ),
          ],
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout adjustments
            final contentPadding =
                isSmallScreen
                    ? const EdgeInsets.all(12.0)
                    : (isPad
                        ? const EdgeInsets.all(24.0)
                        : const EdgeInsets.all(32.0));

            final videoHeight =
                isSmallScreen
                    ? constraints.maxHeight * 0.6
                    : (isPad
                        ? constraints.maxHeight * 0.7
                        : constraints.maxHeight * 0.75);

            return Stack(
              children: [
                // Background decoration with animated gradient
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(seconds: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _backgroundColorWarm,
                          _backgroundColorWarm.withOpacity(0.8),
                          Colors.white.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // Animated bubbles in background for visual stimulation
                if (!isSmallScreen) ..._buildBackgroundBubbles(),

                // Main content
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: contentPadding,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          // Video container with rounded corners and enhanced shadow
                          if (_videoController != null &&
                              _videoController!.value.isInitialized)
                            Container(
                              height: videoHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.Attention.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [                                    // Video player with tap to toggle controls
                                    GestureDetector(                                      onTap: () {
                                        setState(() {
                                          _showControls = !_showControls;
                                          
                                          // Cancel previous timer if exists
                                          _controlsTimer?.cancel();
                                          
                                          // Auto-hide controls after 5 seconds of inactivity
                                          if (_showControls) {
                                            _controlsTimer = Timer(const Duration(seconds: 5), () {
                                              if (mounted) {
                                                setState(() {
                                                  _showControls = false;
                                                });
                                              }
                                            });
                                          }
                                        });
                                        
                                        // Also ensure video plays when tapped, unless user manually paused
                                        if (!_userPaused) {
                                          _ensureVideoIsPlaying();
                                        }
                                      },
                                      child: VideoPlayer(_videoController!),
                                    ),                                    // Video controls overlay with animations
                                    AnimatedOpacity(
                                      opacity: _showControls ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 300),
                                      child: _showControls 
                                        ? Container(
                                            color: Colors.black.withOpacity(0.4),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  // Main control buttons row
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      // Backward 10 seconds
                                                      TweenAnimationBuilder<double>(
                                                        tween: Tween<double>(begin: 0.0, end: 1.0),
                                                        duration: const Duration(milliseconds: 500),
                                                        curve: Curves.elasticOut,
                                                        builder: (context, value, child) {
                                                          return Transform.scale(
                                                            scale: value,
                                                            child: _buildControlButton(
                                                              Icons.replay_10_rounded,
                                                              Colors.white,
                                                              () {
                                                                final currentPosition = _videoController!.value.position;
                                                                final newPosition = currentPosition - const Duration(seconds: 10);
                                                                _videoController!.seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                                                                _resetControlsTimer();
                                                              },
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      
                                                      const SizedBox(width: 24),
                                                      
                                                      // Play/Pause button (larger)
                                                      TweenAnimationBuilder<double>(
                                                        tween: Tween<double>(begin: 0.0, end: 1.0),
                                                        duration: const Duration(milliseconds: 700),
                                                        curve: Curves.elasticOut,
                                                        builder: (context, value, child) {
                                                          return Transform.scale(
                                                            scale: value,
                                                            child: _buildControlButton(
                                                              _videoController!.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                                              _rainbowColors[_colorIndex],                                                              () {
                                                                if (_videoController!.value.isPlaying) {
                                                                  _videoController!.pause();
                                                                  setState(() {
                                                                    _userPaused = true; // Track that user manually paused
                                                                  });
                                                                } else {
                                                                  _videoController!.play();
                                                                  setState(() {
                                                                    _userPaused = false; // Clear the flag when user manually plays
                                                                  });
                                                                }
                                                                _resetControlsTimer();
                                                              },
                                                              size: 80,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      
                                                      const SizedBox(width: 24),
                                                      
                                                      // Forward 10 seconds
                                                      TweenAnimationBuilder<double>(
                                                        tween: Tween<double>(begin: 0.0, end: 1.0),
                                                        duration: const Duration(milliseconds: 500),
                                                        curve: Curves.elasticOut,
                                                        builder: (context, value, child) {
                                                          return Transform.scale(
                                                            scale: value,
                                                            child: _buildControlButton(
                                                              Icons.forward_10_rounded,
                                                              Colors.white,
                                                              () {
                                                                final currentPosition = _videoController!.value.position;
                                                                final newPosition = currentPosition + const Duration(seconds: 10);
                                                                if (newPosition < _videoController!.value.duration) {
                                                                  _videoController!.seekTo(newPosition);
                                                                }
                                                                _resetControlsTimer();
                                                              },
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  
                                                  const SizedBox(height: 32),
                                                  
                                                  // Custom video progress bar with slide-up animation
                                                  TweenAnimationBuilder<double>(
                                                    tween: Tween<double>(begin: 40.0, end: 0.0),
                                                    duration: const Duration(milliseconds: 400),
                                                    curve: Curves.easeOutCubic,
                                                    builder: (context, value, child) {
                                                      return Transform.translate(
                                                        offset: Offset(0, value),
                                                        child: Opacity(
                                                          opacity: 1 - (value / 40.0).clamp(0.0, 1.0),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 24),
                                                            child: _buildCustomProgressBar(),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : null,
                                    ),

                                    // Animated frame decoration
                                    IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _rainbowColors[_colorIndex]
                                                .withOpacity(0.7),
                                            width: 8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                    ),                                    // Video progress indicator with rainbow effect
                                    // Only show the simple progress bar when controls are not visible
                                    if (!_showControls)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 10,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _rainbowColors,
                                              stops: List.generate(
                                                _rainbowColors.length,
                                                (index) =>
                                                    index /
                                                    (_rainbowColors.length - 1),
                                              ),
                                            ),
                                          ),
                                          width:
                                              constraints.maxWidth *
                                              _videoProgress,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Focus celebration animation
                          if (_showFocusedCelebration)
                            SlideTransition(
                              position: _bounceAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/eappface.png',
                                      height: 60,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Amazing Focus!',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                        fontFamily: 'Comic Sans MS',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Lottie.asset(
                                      'assets/animations/celebration.json',
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (_showFocusedCelebration)
                            SizedBox(height: isSmallScreen ? 16 : 24),

                          // Attention status indicator with adaptive colors and animations
                          SlideTransition(
                            position: _floatingAnimation,
                            child: Container(
                              width: constraints.maxWidth,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 16,
                                horizontal: isSmallScreen ? 16 : 24,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _isFocused
                                        ? const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.9)
                                        : const Color(
                                          0xFFFF5252,
                                        ).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _isFocused
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.red.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ScaleTransition(
                                    scale: _pulseAnimation,
                                    child:
                                        _isFocused
                                            ? Lottie.asset(
                                              'assets/animations/focused.json',
                                              height: isSmallScreen ? 50 : 60,
                                              width: isSmallScreen ? 50 : 60,
                                              fit: BoxFit.cover,
                                            )
                                            : Lottie.asset(
                                              'assets/animations/attention.json',
                                              height: isSmallScreen ? 50 : 60,
                                              width: isSmallScreen ? 50 : 60,
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isFocused
                                              ? 'Great Watching!'
                                              : 'Look Here!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 18 : 22,
                                            fontFamily: 'Comic Sans MS',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isFocused
                                              ? 'You\'re doing awesome watching the video!'
                                              : 'Can you look at the friendly video?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Camera status with animation
                          if (_cameraController != null &&
                              _cameraController!.value.isInitialized)
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _rainbowColors[_colorIndex]
                                      .withOpacity(0.5),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  RotationTransition(
                                    turns: _rotateAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _rainbowColors[_colorIndex],
                                          width: 2,
                                        ),
                                      ),
                                      child: ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: const Icon(
                                          Icons.visibility,
                                          color: Color(0xFF1976D2),
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Magic Eyes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 16 : 18,
                                            color: Color(0xFF424242),
                                            fontFamily: 'Comic Sans MS',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'I\'m your friendly helper watching you enjoy the video!',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 13 : 15,
                                            color: Color(0xFF757575),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Bottom space for scrolling
                          SizedBox(height: isSmallScreen ? 16 : 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Focus alert overlay with animation
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return !_isFocused
                        ? Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _fadeAnimation.value < 0.1,
                            child: Opacity(
                              opacity: _fadeAnimation.value * 0.7,
                              child: Container(
                                color: Colors.red.withOpacity(0.3),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ScaleTransition(
                                          scale: _pulseAnimation,
                                          child: Icon(
                                            Icons.visibility,
                                            color: Colors.red,
                                            size: isSmallScreen ? 60 : 80,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Please Look!',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 24 : 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                            fontFamily: 'Comic Sans MS',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper method to create animated background bubbles
  List<Widget> _buildBackgroundBubbles() {
    final random = Random();
    return List.generate(12, (index) {
      final size = 20.0 + random.nextDouble() * 60;
      final left =
          random.nextDouble() * (MediaQuery.of(context).size.width - size);
      final top =
          random.nextDouble() * (MediaQuery.of(context).size.height - size);
      final color = _rainbowColors[random.nextInt(_rainbowColors.length)];

      return Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final offset =
                  sin(_floatingController.value * 2 * pi + index) * 10;
              return Transform.translate(
                offset: Offset(0, offset),
                child: Opacity(
                  opacity: 0.1 + (random.nextDouble() * 0.1),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
