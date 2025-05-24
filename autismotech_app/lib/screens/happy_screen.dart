import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:autismotech_app/screens/pdf_preview_screen.dart';

// Helper extension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

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

  // Adding a flag to prevent overlapping camera captures
  bool _isProcessingImage = false;

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
      if (cameras.isEmpty) {
        print('No cameras available on this device');
        setState(() {
          _emotion = 'No camera detected';
        });
        return;
      }

      // Find the front-facing camera
      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      if (frontCamera == null) {
        print('No front camera available');
        setState(() {
          _emotion = 'No front camera detected';
        });
        return;
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _startEmotionDetection();
    } catch (e) {
      print('Camera initialization error: $e');
      setState(() {
        _emotion = 'Camera error: Cannot detect face';
      });
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

    // Check if we're already processing an image
    if (_isProcessingImage) {
      print('Skipping emotion detection - previous capture still processing');
      return;
    }

    try {
      _isProcessingImage = true;
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Using 10.0.2.2 which maps to the host machine's localhost when running in an Android emulator
      // For physical devices, use your actual server IP address
      final String apiUrl = '172.20.10.9:5001'; // For Android emulator

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
    } finally {
      _isProcessingImage =
          false; // Reset flag when done, regardless of success/failure
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

    // Save session data for professional reports
    _saveSessionData(
      dominantEmotion: dominantEmotion,
      emotionPercentages: emotionPercentages,
      sessionDuration: sessionDurationSeconds,
      observations: observations,
    );

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

    // Save session data for professional reports
    _saveSessionData(
      dominantEmotion: dominantEmotion,
      emotionPercentages: emotionPercentages,
      sessionDuration: sessionDurationSeconds,
      observations: observations,
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
                  onPressed: () async {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 20),
                                Text('Generating PDF Report...'),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    // Generate PDF
                    try {
                      final pdfFile = await _generatePDF(
                        dateFormatted: dateFormatted,
                        startTimeFormatted: startTimeFormatted,
                        sessionDurationSeconds: sessionDurationSeconds,
                        dominantEmotion: dominantEmotion,
                        emotionPercentages: emotionPercentages,
                        observations: observations,
                      );

                      // Close loading dialog
                      Navigator.pop(context);

                      if (pdfFile != null) {
                        // Show options dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('PDF Report Ready'),
                              content: const Text(
                                'What would you like to do with the report?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PdfPreviewScreen(
                                              pdfFile: pdfFile,
                                              dateFormatted: dateFormatted,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text('Preview'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context); // Close dialog
                                    final result = await Share.shareXFiles(
                                      [XFile(pdfFile.path)],
                                      subject:
                                          'Happy Hills Emotion Report - $dateFormatted',
                                      text:
                                          'Here is the emotion report from the Happy Hills game session.',
                                    );
                                    print('Share result: ${result.status}');
                                  },
                                  child: const Text('Share Now'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } catch (e) {
                      // Close loading dialog
                      Navigator.pop(context);

                      print('Error generating PDF: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to generate PDF: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF Report'),
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

              // Camera preview for emotion detection
              if (_cameraController != null &&
                  _cameraController!.value.isInitialized)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    height: 100,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CameraPreview(_cameraController!),
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

  // Save session data for professional reports
  Future<void> _saveSessionData({
    required String dominantEmotion,
    required Map<String, double> emotionPercentages,
    required int sessionDuration,
    required List<String> observations,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create report data
      final Map<String, dynamic> reportData = {
        'id': 'AUX-${Random().nextInt(9000) + 1000}',
        'date': DateTime.now().millisecondsSinceEpoch,
        'game': 'Happy Hills',
        'duration': sessionDuration / 60, // Convert to minutes
        'dominantEmotion': dominantEmotion,
        'emotionMetrics': emotionPercentages,
        'notes': observations.join(" "),
        'score': score,
        'emotionTimeline': _emotionTimeline,
      };

      // Get existing reports or create empty list
      List<String> reports = prefs.getStringList('happy_hills_reports') ?? [];

      // Add new report
      reports.add(jsonEncode(reportData));

      // Store limited number of reports (keep last 10)
      if (reports.length > 10) {
        reports = reports.sublist(reports.length - 10);
      }

      // Save to shared preferences
      await prefs.setStringList('happy_hills_reports', reports);

      print('Happy Hills session data saved for professional reports');
    } catch (e) {
      print('Error saving Happy Hills session data: $e');
    }
  }

  // Generate PDF document
  Future<File?> _generatePDF({
    required String dateFormatted,
    required String startTimeFormatted,
    required int sessionDurationSeconds,
    required String dominantEmotion,
    required Map<String, double> emotionPercentages,
    required List<String> observations,
  }) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Load fonts for better styling
      final regularFont = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();
      final titleFont = await PdfGoogleFonts.robotoCondensedBold();
      final headingFont = await PdfGoogleFonts.quicksandBold();
      final subtitleFont = await PdfGoogleFonts.quicksandMedium();

      // Define theme colors
      final primaryColor = PdfColor.fromInt(0xFF3366FF);
      final secondaryColor = PdfColor.fromInt(0xFFFF9500);
      final accentColor = PdfColor.fromInt(0xFF62BBD3);
      final bgColor = PdfColor.fromInt(0xFFF5F5F5);
      final textColor = PdfColor.fromInt(0xFF333333);
      final lightTextColor = PdfColor.fromInt(0xFF666666);

      // Sort the emotion percentages for visualization
      final sortedEmotions =
          emotionPercentages.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      // Add pages to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: accentColor, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Happy Hills',
                        style: pw.TextStyle(
                          font: titleFont,
                          fontSize: 24,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Emotion Intelligence Report',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 12,
                          color: lightTextColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Text(
                      dateFormatted,
                      style: pw.TextStyle(
                        font: boldFont,
                        color: PdfColor.fromInt(0xFFFFFFFF),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 10),
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE0E0E0),
                    width: 0.5,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by AutismoTech',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF999999),
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF999999),
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Header Section with Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: bgColor,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left side summary stats
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'SESSION SUMMARY',
                                style: pw.TextStyle(
                                  font: headingFont,
                                  fontSize: 16,
                                  color: primaryColor,
                                ),
                              ),
                              pw.SizedBox(height: 10),
                              _buildPdfInfoRow(
                                'Session Date',
                                dateFormatted,
                                regularFont,
                                boldFont,
                                textColor,
                              ),
                              _buildPdfInfoRow(
                                'Start Time',
                                startTimeFormatted,
                                regularFont,
                                boldFont,
                                textColor,
                              ),
                              _buildPdfInfoRow(
                                'Duration',
                                '${sessionDurationSeconds ~/ 60} minutes',
                                regularFont,
                                boldFont,
                                textColor,
                              ),
                              _buildPdfInfoRow(
                                'Game',
                                'Happy Hills - Color Match',
                                regularFont,
                                boldFont,
                                textColor,
                              ),
                              _buildPdfInfoRow(
                                'Final Score',
                                score.toString(),
                                regularFont,
                                boldFont,
                                textColor,
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        // Right side emotion summary
                        pw.Expanded(
                          flex: 2,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(15),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFFFFFFF),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(10),
                              ),
                              border: pw.Border.all(
                                color: accentColor,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'PRIMARY EMOTION',
                                  style: pw.TextStyle(
                                    font: subtitleFont,
                                    fontSize: 10,
                                    color: primaryColor,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  _getEmotionText(dominantEmotion),
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 20,
                                    color: _getPdfEmotionColor(dominantEmotion),
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  '${emotionPercentages[dominantEmotion]?.toStringAsFixed(1) ?? "0"}%',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 18,
                                    color: textColor,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'of session time',
                                  style: pw.TextStyle(
                                    font: regularFont,
                                    fontSize: 10,
                                    color: lightTextColor,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Emotion Distribution Section with chart
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFFFFF),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EMOTION DISTRIBUTION',
                      style: pw.TextStyle(
                        font: headingFont,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    // Horizontal bar chart
                    pw.Container(
                      height: 160,
                      child: pw.Row(
                        children: [
                          // Left side - emotion bars
                          pw.Expanded(
                            flex: 3,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                ...sortedEmotions.map((entry) {
                                  final barWidth =
                                      entry.value /
                                      100 *
                                      250; // Scale for page width
                                  return pw.Container(
                                    margin: const pw.EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Row(
                                          children: [
                                            pw.Container(
                                              width: 80,
                                              child: pw.Text(
                                                _getEmotionText(entry.key),
                                                style: pw.TextStyle(
                                                  font: boldFont,
                                                  fontSize: 10,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            pw.Expanded(
                                              child: pw.Stack(
                                                children: [
                                                  // Background track
                                                  pw.Container(
                                                    height: 12,
                                                    decoration: pw.BoxDecoration(
                                                      color: PdfColor.fromInt(
                                                        0xFFEEEEEE,
                                                      ),
                                                      borderRadius:
                                                          const pw.BorderRadius.all(
                                                            pw.Radius.circular(
                                                              6,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  // Value bar
                                                  pw.Container(
                                                    height: 12,
                                                    width: barWidth,
                                                    decoration: pw.BoxDecoration(
                                                      color:
                                                          _getPdfEmotionColor(
                                                            entry.key,
                                                          ),
                                                      borderRadius:
                                                          const pw.BorderRadius.all(
                                                            pw.Radius.circular(
                                                              6,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  // Value text
                                                  pw.Positioned(
                                                    right: 5,
                                                    top: 2,
                                                    child: pw.Text(
                                                      '${entry.value.toStringAsFixed(1)}%',
                                                      style: pw.TextStyle(
                                                        font: boldFont,
                                                        fontSize: 8,
                                                        color: PdfColor.fromInt(
                                                          0xFFFFFFFF,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Observations & Analysis
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFFFFF),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AI OBSERVATIONS & ANALYSIS',
                      style: pw.TextStyle(
                        font: headingFont,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    ...observations
                        .map(
                          (observation) => pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 10),
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: bgColor,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6),
                              ),
                            ),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 20,
                                  height: 20,
                                  decoration: pw.BoxDecoration(
                                    color: accentColor,
                                    shape: pw.BoxShape.circle,
                                  ),
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    '•',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFFFFFFFF),
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 10),
                                pw.Expanded(
                                  child: pw.Text(
                                    observation,
                                    style: pw.TextStyle(
                                      font: regularFont,
                                      fontSize: 10,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Recommendations Section
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [primaryColor, PdfColor.fromInt(0xFF5C84FF)],
                  ),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RECOMMENDATIONS',
                      style: pw.TextStyle(
                        font: headingFont,
                        fontSize: 16,
                        color: PdfColor.fromInt(0xFFFFFFFF),
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // Recommendation items
                    _buildRecommendationItem(
                      'Share this report with a therapist or educator.',
                      regularFont,
                      PdfColor.fromInt(0xFFFFFFFF),
                    ),
                    _buildRecommendationItem(
                      'Use emotion pattern insights to guide future sessions.',
                      regularFont,
                      PdfColor.fromInt(0xFFFFFFFF),
                    ),
                    _buildRecommendationItem(
                      'Encourage use of reward-based tasks to sustain engagement.',
                      regularFont,
                      PdfColor.fromInt(0xFFFFFFFF),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),

              // Report footer with signature
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  decoration: pw.BoxDecoration(
                    color: bgColor,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(10),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Report generated by AutismoTech Happy Hills',
                        style: pw.TextStyle(
                          font: subtitleFont,
                          fontSize: 10,
                          color: lightTextColor,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Session ID: AUX-${Random().nextInt(9000) + 1000}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to a file
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String path =
          '$dir/happy_hills_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());

      // Navigate to preview screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfPreviewScreen(
                  pdfFile: file,
                  dateFormatted: dateFormatted,
                ),
          ),
        );
      }

      return file;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  // Helper method to build an info row in the PDF
  pw.Widget _buildPdfInfoRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
    PdfColor textColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
                color: textColor,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a recommendation item in the PDF
  pw.Widget _buildRecommendationItem(
    String text,
    pw.Font font,
    PdfColor textColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '•',
            style: pw.TextStyle(font: font, fontSize: 14, color: textColor),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: font, fontSize: 10, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get emotion name with capitalization
  String _getEmotionText(String emotion) {
    return emotion.capitalize();
  }

  // Helper method to get color for an emotion in the PDF
  PdfColor _getPdfEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return PdfColor.fromInt(0xFFFFD747); // Bright yellow
      case 'sad':
        return PdfColor.fromInt(0xFF4B89DC); // Blue
      case 'angry':
        return PdfColor.fromInt(0xFFFF5252); // Red
      case 'surprised':
        return PdfColor.fromInt(0xFFAC92EB); // Purple
      case 'neutral':
        return PdfColor.fromInt(0xFF8CC152); // Green
      case 'fear':
        return PdfColor.fromInt(0xFF5D9CEC); // Light blue
      case 'disgust':
        return PdfColor.fromInt(0xFFBF5B51); // Brownish red
      default:
        return PdfColor.fromInt(0xFFCCD1D9); // Gray
    }
  }
}
