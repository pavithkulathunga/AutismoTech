import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  // Track emotion data for report
  final Map<String, int> _emotionSeconds = {
    'happy': 0,
    'sad': 0,
    'angry': 0,
    'surprised': 0,
    'neutral': 0,
    'fear': 0,
    'disgust': 0,
  };
  final List<Map<String, dynamic>> _emotionTimeline = [];
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _generateNewTarget();
    _sessionStartTime = DateTime.now(); // Track session start time
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
          final newEmotion = data['dominant_emotion'] ?? '';
          setState(() {
            _emotion = newEmotion;
            _emotionConfidence = (data['confidence'] ?? 0).toDouble();
          });

          // Track emotion for report
          if (_emotion.isNotEmpty &&
              _emotionSeconds.containsKey(_emotion.toLowerCase())) {
            _emotionSeconds[_emotion.toLowerCase()] =
                (_emotionSeconds[_emotion.toLowerCase()] ?? 0) + 2;
          }

          // Add to timeline at 2-minute intervals or on emotion changes
          if (_emotionTimeline.isEmpty ||
              _emotionTimeline.last['emotion'] != _emotion.toLowerCase()) {
            _emotionTimeline.add({
              'time': DateTime.now().difference(_sessionStartTime!).inSeconds,
              'emotion': _emotion.toLowerCase(),
            });
          }
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

      // Fast feedback for correct selection - using overlay instead of SnackBar
      _showQuickFeedback('🎉 Great job! 🎉', Colors.green);
    } else {
      // Fast feedback for incorrect choice
      _showQuickFeedback('Try again! 😊', Colors.orange);
    }
    _generateNewTarget();
  }

  // New method for instant feedback
  void _showQuickFeedback(String message, Color backgroundColor) {
    final overlay = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            width: MediaQuery.of(context).size.width,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    // Show and then quickly remove the feedback
    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(milliseconds: 500), () {
      overlay.remove();
    });
  }

  void _showGameOver() {
    // Calculate session duration
    final sessionDuration =
        DateTime.now().difference(_sessionStartTime!).inSeconds;

    // Show emotion report
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: _buildEmotionReport(sessionDuration),
        );
      },
    );
  }

  Widget _buildEmotionReport(int sessionDurationSeconds) {
    // Format the start time
    final startTimeFormatted = DateFormat('h:mm a').format(_sessionStartTime!);
    final dateFormatted = DateFormat('MMMM d, y').format(DateTime.now());

    // Calculate percentages
    final totalEmotionSeconds = _emotionSeconds.values.fold(
      0,
      (sum, duration) => sum + duration,
    );
    final Map<String, double> emotionPercentages = {};
    _emotionSeconds.forEach((emotion, seconds) {
      emotionPercentages[emotion] =
          totalEmotionSeconds > 0 ? (seconds / totalEmotionSeconds * 100) : 0.0;
    });

    // Find dominant and least observed emotions
    String dominantEmotion = 'neutral';
    String leastEmotion = 'neutral';
    int maxSeconds = -1;
    int minSeconds = 999999;

    _emotionSeconds.forEach((emotion, seconds) {
      if (seconds > 0) {
        if (seconds > maxSeconds) {
          maxSeconds = seconds;
          dominantEmotion = emotion;
        }
        if (seconds < minSeconds) {
          minSeconds = seconds;
          leastEmotion = emotion;
        }
      }
    });

    // Generate AI observations
    List<String> observations = [
      "The child showed an overall ${dominantEmotion.toLowerCase()} emotional state during the game.",
    ];

    if (_emotionTimeline.length >= 2) {
      observations.add(
        "Emotional changes were detected ${_emotionTimeline.length - 1} times during gameplay.",
      );
    }

    if (_emotionSeconds.containsKey('happy') &&
        _emotionSeconds['happy']! > 0 &&
        _emotionSeconds['happy']! >= totalEmotionSeconds * 0.4) {
      observations.add(
        "The child maintained a positive emotional state for a significant portion of the game.",
      );
    }

    // Fix: Check if angry exists before accessing it
    final bool showedFrustration =
        _emotionSeconds.containsKey('angry') && _emotionSeconds['angry']! > 0;
    if (showedFrustration) {
      observations.add(
        "Some moments of frustration or difficulty were detected, suggesting cognitive challenge.",
      );
    }

    // Add score observation
    observations.add(
      "Final game score was $score points, showing good engagement with the activity.",
    );

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📄 Emotion Summary Report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.pop(context); // Go back to the previous screen
                  },
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),

            // Basic Info Section
            _buildReportSection(
              children: [
                _buildInfoRow('Date', dateFormatted),
                _buildInfoRow('Session Start Time', startTimeFormatted),
                _buildInfoRow(
                  'Session Duration',
                  '${sessionDurationSeconds ~/ 60} minutes',
                ),
                _buildInfoRow('Game Played', 'Happy Hills - Color Match'),
                _buildInfoRow('Final Score', score.toString()),
              ],
            ),

            const Divider(height: 30, thickness: 1),

            // Emotion Distribution Section
            Text(
              '🎯 Emotion Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 15),
            _buildEmotionDistributionTable(emotionPercentages),
            const SizedBox(height: 15),
            _buildInfoRow(
              'Most dominant emotion',
              _getEmotionWithEmoji(dominantEmotion),
            ),
            _buildInfoRow(
              'Least observed emotion',
              _getEmotionWithEmoji(leastEmotion),
            ),

            const Divider(height: 30, thickness: 1),

            // Emotion Timeline Section
            Text(
              '📈 Emotion Timeline (Simplified View)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 15),
            _buildEmotionTimeline(),

            const Divider(height: 30, thickness: 1),

            // AI Observations Section
            Text(
              '🧠 AI Observations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 15),
            ...observations
                .map(
                  (obs) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            obs,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            const Divider(height: 30, thickness: 1),

            // Next Steps Section
            Text(
              '📬 Next Steps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 15),
            ...[
                  'Share this report with a therapist or educator.',
                  'Use emotion pattern insights to guide future sessions.',
                  'Encourage use of reward-based tasks to sustain engagement.',
                ]
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            const Divider(height: 30, thickness: 1),

            // Export info
            Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '📤 Exported By:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'App: AutismoTech Mobile',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Session ID: #AUX-${Random().nextInt(9000) + 1000}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Bottom buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // This would share the report in a real app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Report sharing would be implemented here',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to previous screen
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Return Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildEmotionDistributionTable(Map<String, double> percentages) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[100]),
            children: [
              _buildTableCell('Emotion', isHeader: true),
              _buildTableCell('Duration', isHeader: true),
              _buildTableCell('Percentage', isHeader: true),
            ],
          ),
          ...percentages.entries
              .where((entry) => entry.value > 0)
              .map(
                (entry) => TableRow(
                  children: [
                    _buildTableCell(_getEmotionWithEmoji(entry.key)),
                    _buildTableCell(
                      '${(entry.value * sessionDurationSeconds() / 100).round()} s',
                    ),
                    _buildTableCell('${entry.value.toStringAsFixed(1)}%'),
                  ],
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmotionTimeline() {
    if (_emotionTimeline.isEmpty) {
      return const Text('No emotion timeline data available');
    }

    // Group timeline entries into time ranges
    final List<Map<String, dynamic>> timelineRanges = [];

    for (int i = 0; i < _emotionTimeline.length; i++) {
      final endTime =
          i < _emotionTimeline.length - 1
              ? _emotionTimeline[i + 1]['time']
              : sessionDurationSeconds();

      timelineRanges.add({
        'startTime': _emotionTimeline[i]['time'],
        'endTime': endTime,
        'emotion': _emotionTimeline[i]['emotion'],
      });
    }

    return Column(
      children:
          timelineRanges.map((range) {
            final startMin = (range['startTime'] / 60).floor();
            final startSec = range['startTime'] % 60;
            final endMin = (range['endTime'] / 60).floor();
            final endSec = range['endTime'] % 60;

            final timeText =
                '$startMin:${startSec.toString().padLeft(2, '0')} - '
                '$endMin:${endSec.toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      timeText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _getEmotionEmojiText(range['emotion']),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    range['emotion'].toString().capitalize(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // Add a new helper method for emoji text by emotion name
  String _getEmotionEmojiText(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😃';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'surprised':
        return '😲';
      case 'neutral':
        return '😐';
      case 'fear':
        return '😨';
      case 'disgust':
        return '🤢';
      default:
        return '🙂';
    }
  }

  // Keep the original method for the current emotion display
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

  // Add the build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Happy Hills',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange.shade400,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade200, Colors.purple.shade100],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main game content
              Column(
                children: [
                  // Timer and Score Display
                  Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Score: $score',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_secondsLeft',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    _secondsLeft <= 10
                                        ? Colors.red
                                        : Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Emotion display
                  if (_emotion.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getEmotionEmoji(),
                          const SizedBox(width: 8),
                          Text(
                            'You look ${_emotion.capitalize()}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Game area
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.orange.shade300,
                                width: 3,
                              ),
                            ),
                            child: const Text(
                              'Tap the matching color!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Target color display with animation
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: targetColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Color choices
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Wrap(
                              spacing: 25,
                              runSpacing: 25,
                              alignment: WrapAlignment.center,
                              children:
                                  colors.map((color) {
                                    return GestureDetector(
                                      onTap: () => _checkMatch(color),
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.6),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              45,
                                            ),
                                            splashColor: Colors.white24,
                                            onTap: () => _checkMatch(color),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 1,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  colors: const [
                    Colors.pink,
                    Colors.purple,
                    Colors.orange,
                    Colors.yellow,
                    Colors.blue,
                    Colors.green,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add missing method to get emotion with emoji
  String _getEmotionWithEmoji(String emotion) {
    return '${_getEmotionEmojiText(emotion)} ${emotion.capitalize()}';
  }

  // Add missing method to calculate session duration in seconds
  int sessionDurationSeconds() {
    return _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;
  }
}

// Helper extension
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
