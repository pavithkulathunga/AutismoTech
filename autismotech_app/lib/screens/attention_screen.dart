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
import 'package:autismotech_app/constants/colors.dart';
import 'package:lottie/lottie.dart';

class AttentionScreen extends StatefulWidget {
  final String videoPath;

  const AttentionScreen({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  CameraController? _cameraController;
  Timer? _captureTimer;
  bool _isCapturing = false;
  
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
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Floating animation for elements
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _floatingAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.05),
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    // Fade animation for alerts
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Bounce animation for celebrations
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _bounceAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.2),
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    // Rotation animation for visual interest
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));
    
    // Scale animation for UI elements
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    
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
    
    // Set up video progress tracking
    _videoController!.addListener(() {
      if (_videoController!.value.isPlaying != _isVideoPlaying) {
        setState(() {
          _isVideoPlaying = _videoController!.value.isPlaying;
        });
      }
      
      // Update video progress
      if (_videoController!.value.isInitialized && _videoController!.value.duration.inMilliseconds > 0) {
        setState(() {
          _videoProgress = _videoController!.value.position.inMilliseconds / 
                          _videoController!.value.duration.inMilliseconds;
        });
      }
      
      // Loop video when completed
      if (_videoController!.value.position >= _videoController!.value.duration) {
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      }
    });
    
    setState(() {
      _isVideoPlaying = true;
    });
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
    final uri = Uri.parse('http://192.168.1.5:5000/attention/track_focus');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'image.jpg'));

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      print("Response body: $resBody");
      final json = jsonDecode(resBody);

      final isFocused = json['focused'] == true;
      
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
                });
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
      
      setState(() {
        _isFocused = focused;
      });
      
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
  
  @override
  Widget build(BuildContext context) {    final mediaQuery = MediaQuery.of(context);
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
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout adjustments
            final contentPadding = isSmallScreen 
                ? const EdgeInsets.all(12.0)
                : (isPad 
                    ? const EdgeInsets.all(24.0)
                    : const EdgeInsets.all(32.0));
            
            final videoHeight = isSmallScreen
                ? constraints.maxHeight * 0.4
                : (isPad
                    ? constraints.maxHeight * 0.5
                    : constraints.maxHeight * 0.6);
                    
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
                          if (_videoController != null && _videoController!.value.isInitialized)
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
                                  children: [
                                    // Video player
                                    VideoPlayer(_videoController!),
                                    
                                    // Animated frame decoration
                                    IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _rainbowColors[_colorIndex].withOpacity(0.7),
                                            width: 8,
                                          ),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                    
                                    // Video progress indicator with rainbow effect
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
                                              (index) => index / (_rainbowColors.length - 1),
                                            ),
                                          ),
                                        ),
                                        width: constraints.maxWidth * _videoProgress,
                                      ),
                                    ),
                                    
                                    // Video controls with improved accessibility
                                    Positioned.fill(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          splashColor: AppColors.Attention.withOpacity(0.3),
                                          highlightColor: Colors.transparent,
                                          onTap: () {
                                            if (_isVideoPlaying) {
                                              _videoController!.pause();
                                            } else {
                                              _videoController!.play();
                                            }
                                          },
                                          child: Center(
                                            child: AnimatedOpacity(
                                              opacity: _isVideoPlaying ? 0.0 : 1.0,
                                              duration: const Duration(milliseconds: 300),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black38,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(24),
                                                child: ScaleTransition(
                                                  scale: _pulseAnimation,
                                                  child: Icon(
                                                    _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: isSmallScreen ? 36 : 48,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
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
                                    const SizedBox(width: 12),                                    Text(
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
                                horizontal: isSmallScreen ? 16 : 24
                              ),
                              decoration: BoxDecoration(
                                color: _isFocused 
                                  ? const Color(0xFF4CAF50).withOpacity(0.9)
                                  : const Color(0xFFFF5252).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isFocused
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
                                    scale: _pulseAnimation,                                    child: _isFocused
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isFocused ? 'Great Watching!' : 'Look Here!',
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
                          if (_cameraController != null && _cameraController!.value.isInitialized)
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _rainbowColors[_colorIndex].withOpacity(0.5),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          
                          SizedBox(height: isSmallScreen ? 12 : 20),
                          
                          // Video controls with enhanced tactile experience
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 16, 
                              horizontal: isSmallScreen ? 12 : 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.Attention.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [                                _buildControlButton(
                                  Icons.replay_10,
                                  'Back 10s',
                                  () {
                                    if (_videoController != null) {
                                      final currentPosition = _videoController!.value.position;
                                      final newPosition = currentPosition - const Duration(seconds: 10);
                                      _videoController!.seekTo(newPosition);
                                    }
                                  },
                                  colors: [Colors.purple.shade300, Colors.purple.shade500],
                                  size: isSmallScreen ? 50 : 60,
                                ),
                                _buildControlButton(
                                  _isVideoPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  _isVideoPlaying ? 'Pause' : 'Play',
                                  () {
                                    if (_isVideoPlaying) {
                                      _videoController?.pause();
                                    } else {
                                      _videoController?.play();
                                    }
                                  },
                                  isHighlighted: true,
                                  colors: [AppColors.Attention, Colors.deepOrange],
                                  size: isSmallScreen ? 70 : 80,
                                ),
                                _buildControlButton(
                                  Icons.forward_10,
                                  'Forward 10s',
                                  () {
                                    if (_videoController != null) {
                                      final currentPosition = _videoController!.value.position;
                                      final newPosition = currentPosition + const Duration(seconds: 10);
                                      _videoController!.seekTo(newPosition);
                                    }
                                  },
                                  colors: [Colors.teal.shade300, Colors.teal.shade500],
                                  size: isSmallScreen ? 50 : 60,
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
                    return !_isFocused ? Positioned.fill(
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
                    ) : const SizedBox.shrink();
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
      final left = random.nextDouble() * (MediaQuery.of(context).size.width - size);
      final top = random.nextDouble() * (MediaQuery.of(context).size.height - size);
      final color = _rainbowColors[random.nextInt(_rainbowColors.length)];
      
      return Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final offset = sin(_floatingController.value * 2 * pi + index) * 10;
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
  
  Widget _buildControlButton(
    IconData icon, 
    String label, 
    VoidCallback onPressed, 
    {bool isHighlighted = false, 
    List<Color> colors = const [Colors.blue, Colors.indigo],
    double size = 60}
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ScaleTransition(
              scale: isHighlighted ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: colors[1],
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Comic Sans MS',
            ),
          ),
        ],
      ),
    );
  }
}
