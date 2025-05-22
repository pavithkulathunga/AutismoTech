import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
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

    // Show emotion report with modern UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: _buildModernEmotionReport(sessionDuration),
        );
      },
    );
  }

  Widget _buildModernEmotionReport(int sessionDurationSeconds) {
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

    final bool showedFrustration =
        _emotionSeconds.containsKey('angry') && _emotionSeconds['angry']! > 0;
    if (showedFrustration) {
      observations.add(
        "Some moments of frustration or difficulty were detected, suggesting cognitive challenge.",
      );
    }

    observations.add(
      "Final game score was $score points, showing good engagement with the activity.",
    );

    // Generate session ID
    final sessionId = 'AUX-${Random().nextInt(9000) + 1000}';

    // Create report container with modern design
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
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
      child: Column(
        children: [
          // Report Header - Professional gradient design
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emotional Intelligence Report',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderButton(
                          icon: Icons.download_rounded,
                          tooltip: 'Download Report',
                          onTap: () => _downloadReport(sessionId),
                        ),
                        const SizedBox(width: 12),
                        _buildHeaderButton(
                          icon: Icons.close,
                          tooltip: 'Close',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Key metrics bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem(
                        label: 'Session ID',
                        value: '#$sessionId',
                        icon: Icons.badge_outlined,
                      ),
                      _buildVerticalDivider(),
                      _buildMetricItem(
                        label: 'Duration',
                        value: '${sessionDurationSeconds ~/ 60} min',
                        icon: Icons.timer_outlined,
                      ),
                      _buildVerticalDivider(),
                      _buildMetricItem(
                        label: 'Score',
                        value: score.toString(),
                        icon: Icons.emoji_events_outlined,
                      ),
                      _buildVerticalDivider(),
                      _buildMetricItem(
                        label: 'Main Emotion',
                        value: dominantEmotion.capitalize(),
                        icon: Icons.face_outlined,
                        emoji: _getEmotionEmojiText(dominantEmotion),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Report content - Scrollable section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Emotion Distribution Section
                  _buildSectionHeader('Emotion Distribution'),
                  const SizedBox(height: 16),

                  // Emotion donut chart visualization
                  SizedBox(
                    height: 220,
                    child: _buildEmotionChartSection(emotionPercentages),
                  ),

                  const SizedBox(height: 32),

                  // Emotion Timeline Section
                  _buildSectionHeader('Emotion Timeline'),
                  const SizedBox(height: 16),
                  _buildTimelineSection(),

                  const SizedBox(height: 32),

                  // AI Insights Section
                  _buildSectionHeader('AI Analysis & Insights'),
                  const SizedBox(height: 16),
                  _buildInsightsSection(observations),

                  const SizedBox(height: 32),

                  // Recommendations Section
                  _buildSectionHeader('Recommendations'),
                  const SizedBox(height: 16),
                  _buildRecommendationsSection(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Footer with action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadReport(sessionId),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF3366FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sharing report...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF3366FF),
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF3366FF)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header action button
  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // Metric item with icon
  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    String? emoji,
  }) {
    return Column(
      children: [
        emoji != null
            ? Text(emoji, style: const TextStyle(fontSize: 24))
            : Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  // Vertical divider for metrics bar
  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  // Section header with modern design
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF3366FF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  // Emotion chart visualization
  Widget _buildEmotionChartSection(Map<String, double> emotionPercentages) {
    // Filter out emotions with 0%
    final nonZeroEmotions =
        emotionPercentages.entries.where((entry) => entry.value > 0).toList();

    if (nonZeroEmotions.isEmpty) {
      return const Center(
        child: Text('No emotion data available for this session'),
      );
    }

    return Row(
      children: [
        // Chart area (left side)
        Expanded(
          flex: 3,
          child: CustomPaint(
            size: const Size(double.infinity, 200),
            painter: DonutChartPainter(
              emotionData:
                  nonZeroEmotions
                      .map(
                        (entry) => {
                          'emotion': entry.key,
                          'percentage': entry.value,
                          'color': _getEmotionColor(entry.key),
                        },
                      )
                      .toList(),
            ),
          ),
        ),

        // Legend area (right side)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                nonZeroEmotions.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getEmotionColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key.capitalize()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${entry.value.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // Timeline visualization
  Widget _buildTimelineSection() {
    if (_emotionTimeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: Text('No emotion timeline data available')),
      );
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timeline header
          Row(
            children: const [
              SizedBox(
                width: 70,
                child: Text(
                  'Time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Emotion State',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Timeline items
          ...timelineRanges.map((range) {
            final startMin = (range['startTime'] / 60).floor();
            final startSec = range['startTime'] % 60;
            final endMin = (range['endTime'] / 60).floor();
            final endSec = range['endTime'] % 60;

            final timeText =
                '$startMin:${startSec.toString().padLeft(2, '0')} - '
                '$endMin:${endSec.toString().padLeft(2, '0')}';

            // Calculate duration percentage for the timeline bar
            final totalDuration = sessionDurationSeconds();
            final itemDuration = range['endTime'] - range['startTime'];
            final percentage =
                totalDuration > 0 ? (itemDuration / totalDuration) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  SizedBox(
                    width: 70,
                    child: Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5C5C5C),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Emotion progress bar column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getEmotionEmojiText(range['emotion']),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              range['emotion'].toString().capitalize(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5C5C5C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            // Background track
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            // Colored progress
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getEmotionColor(range['emotion']),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // AI Insights section
  Widget _buildInsightsSection(List<String> observations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            observations.map((observation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF3366FF),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        observation,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  // Recommendations section
  Widget _buildRecommendationsSection() {
    final recommendations = [
      {
        'title': 'Share with specialist',
        'description':
            'Provide this report to therapists or educators to guide future interventions',
        'icon': Icons.people_outline,
      },
      {
        'title': 'Track progress',
        'description':
            'Compare with future sessions to monitor emotional development patterns',
        'icon': Icons.analytics_outlined,
      },
      {
        'title': 'Try similar activities',
        'description':
            'Continue with activities that promote positive emotional engagement',
        'icon': Icons.extension_outlined,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            recommendations.map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3366FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        recommendation['icon'] as IconData,
                        color: const Color(0xFF3366FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation['description'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  // Function to get color for an emotion
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFD747); // Bright yellow
      case 'sad':
        return const Color(0xFF4B89DC); // Blue
      case 'angry':
        return const Color(0xFFFF5252); // Red
      case 'surprised':
        return const Color(0xFFAC92EB); // Purple
      case 'neutral':
        return const Color(0xFF8CC152); // Green
      case 'fear':
        return const Color(0xFF5D9CEC); // Light blue
      case 'disgust':
        return const Color(0xFFBF5B51); // Brownish red
      default:
        return const Color(0xFFCCD1D9); // Gray
    }
  }

  // Download report functionality
  void _downloadReport(String sessionId) {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Preparing PDF report...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF3366FF),
      ),
    );

    // Simulate download process
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Report downloaded successfully'),
            ],
          ),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () {
              // In a real app, this would open the PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening PDF report...')),
              );
            },
            textColor: Colors.white,
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
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
}

// Custom painter for donut chart
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> emotionData;

  DonutChartPainter({required this.emotionData});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.8 / 2;
    final innerRadius = radius * 0.6;

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // Start from the top

    for (final data in emotionData) {
      final percentage = data['percentage'] as double;
      final sweepAngle = 2 * pi * (percentage / 100);

      final paint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = data['color'] as Color;

      // Draw arc segment
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Update the startAngle for the next segment
      startAngle += sweepAngle;
    }

    // Draw white circle in the middle for donut hole
    final holePaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius, holePaint);

    // Draw center text with total seconds - fixing the TextPainter configuration
    final textSpan = TextSpan(
      text: '${emotionData.length}\nEmotions',
      style: const TextStyle(
        color: Color(0xFF2C3E50),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Force layout with proper constraints to handle multiline text
    textPainter.layout(minWidth: 0, maxWidth: innerRadius * 2);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper extension
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
