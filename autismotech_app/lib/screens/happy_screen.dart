import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class HappyScreen extends StatefulWidget {
  const HappyScreen({super.key});

  @override
  State<HappyScreen> createState() => _HappyScreenState();
}

class _HappyScreenState extends State<HappyScreen>
    with TickerProviderStateMixin {
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    const Color.fromARGB(239, 255, 176, 17),
  ];
  late Color targetColor;
  int score = 0;

  Timer? _timer;
  int _secondsLeft = 60;
  final bool _gameStarted = true;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late ConfettiController _confettiController;

  // Camera and emotion detection
  CameraController? _cameraController;
  Timer? _emotionTimer;
  String _emotion = '';
  double _emotionConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _generateNewTarget();
    _startTimer();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.low,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        _startEmotionDetection();
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  void _startEmotionDetection() {
    _emotionTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _detectEmotion(),
    );
  }

  Future<void> _detectEmotion() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Using 10.0.2.2 which maps to the host machine's localhost when running in an Android emulator
      // For physical devices, use your actual server IP address
      final String apiUrl = '10.0.2.2:8080'; // For Android emulator

      final response = await http
          .post(
            Uri.parse('http://$apiUrl/emotion/mobile_predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'frame': base64Image}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Emotion detection request timed out');
              return http.Response('{"error": "timeout"}', 408);
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['face_detected'] == true) {
          setState(() {
            _emotion = data['dominant_emotion'] ?? '';
            _emotionConfidence = (data['confidence'] ?? 0).toDouble();
          });
        } else {
          setState(() {
            _emotion = '';
            _emotionConfidence = 0.0;
          });
        }
      } else {
        print(
          'Error in emotion detection: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Exception in emotion detection: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Time\'s up!')));
        _showGameOver();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emotionTimer?.cancel();
    _cameraController?.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateNewTarget() {
    setState(() {
      targetColor = colors[Random().nextInt(colors.length)];
    });
  }

  void _checkMatch(Color selectedColor) {
    _scaleController.forward().then((_) => _scaleController.reverse());

    if (selectedColor == targetColor) {
      setState(() {
        score++;
      });
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Great job! You matched the color! 🎉')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Oops! Try again 😊')));
    }
    _generateNewTarget();
  }

  void _showGameOver() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your score is: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Go back to the previous screen
              },
              child: const Text('Go to Previous Page'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Happy Hills - Color Match",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'Comic Sans MS',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF9100),
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE0B2), Color(0xFFFFFFFF)],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      maxBlastForce: 7,
                      minBlastForce: 3,
                      emissionFrequency: 0.05,
                      numberOfParticles: 30,
                      gravity: 0.2,
                      colors: const [
                        Colors.red,
                        Colors.green,
                        Colors.blue,
                        Colors.yellow,
                        Colors.pink,
                        Colors.purple,
                      ],
                    ),
                  ),
                  if (_gameStarted)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer,
                                color: Color(0xFFFF9100),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Time: $_secondsLeft s',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                  fontFamily: 'Comic Sans MS',
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Icon(
                                Icons.stars,
                                color: Color(0xFFFF9100),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Score: $score',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                  fontFamily: 'Comic Sans MS',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Can you tap the matching color?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                            fontFamily: 'Comic Sans MS',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Find this color:",
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Comic Sans MS',
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: targetColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: targetColor.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Wrap(
                            spacing: 25,
                            runSpacing: 25,
                            alignment: WrapAlignment.center,
                            children:
                                colors.map((color) {
                                  return GestureDetector(
                                    onTap: () => _checkMatch(color),
                                    child: MouseRegion(
                                      onEnter: (_) {
                                        setState(() {});
                                      },
                                      onExit: (_) {
                                        setState(() {});
                                      },
                                      child: AnimatedBuilder(
                                        animation: _scaleController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _scaleAnimation.value,
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: 3,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: color.withOpacity(
                                                      0.5,
                                                    ),
                                                    spreadRadius: 2,
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Emotion display with emoji in top-left corner
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _getEmotionEmoji(),
                    const SizedBox(width: 8),
                    Text(
                      _emotion.isNotEmpty ? _emotion : 'No emotion',
                      style: const TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comic Sans MS',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to display appropriate emoji based on detected emotion
  Widget _getEmotionEmoji() {
    switch (_emotion.toLowerCase()) {
      case 'happy':
        return const Text('😃', style: TextStyle(fontSize: 24));
      case 'sad':
        return const Text('😢', style: TextStyle(fontSize: 24));
      case 'angry':
        return const Text('😠', style: TextStyle(fontSize: 24));
      case 'surprised':
        return const Text('😲', style: TextStyle(fontSize: 24));
      case 'neutral':
        return const Text('😐', style: TextStyle(fontSize: 24));
      case 'fear':
        return const Text('😨', style: TextStyle(fontSize: 24));
      case 'disgust':
        return const Text('🤢', style: TextStyle(fontSize: 24));
      default:
        return const Text('🙂', style: TextStyle(fontSize: 24));
    }
  }
}
