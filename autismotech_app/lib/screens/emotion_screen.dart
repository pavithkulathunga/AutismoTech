import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

// Custom painter for emotion timeline chart
class TimelineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define colors
    final happyColor = Colors.amber.shade600;
    final neutralColor = Colors.green.shade600;
    final sadColor = Colors.blue.shade600;

    // Define paint objects
    final linePaint =
        Paint()
          ..color = Colors.amber.shade400
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final dotPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final dotStrokePaint =
        Paint()
          ..color = Colors.amber.shade600
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    // Define emotional heights (y values)
    final happyY = size.height * 0.2;
    final neutralY = size.height * 0.5;
    final sadY = size.height * 0.8;

    // Define points
    final points = [
      Offset(size.width * 0.05, neutralY),
      Offset(size.width * 0.2, happyY),
      Offset(size.width * 0.3, happyY),
      Offset(size.width * 0.4, neutralY),
      Offset(size.width * 0.5, sadY),
      Offset(size.width * 0.6, neutralY),
      Offset(size.width * 0.75, happyY),
      Offset(size.width * 0.9, happyY),
    ];

    // Draw emotion zones (background)
    final zonePaint = Paint()..style = PaintingStyle.fill;

    // Happy zone
    zonePaint.color = happyColor.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, happyY + (neutralY - happyY) / 2),
      zonePaint,
    );

    // Neutral zone
    zonePaint.color = neutralColor.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        happyY + (neutralY - happyY) / 2,
        size.width,
        (neutralY - happyY) / 2 + (sadY - neutralY) / 2,
      ),
      zonePaint,
    );

    // Sad zone
    zonePaint.color = sadColor.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        neutralY + (sadY - neutralY) / 2,
        size.width,
        size.height - neutralY - (sadY - neutralY) / 2,
      ),
      zonePaint,
    );

    // Draw horizontal emotion lines
    final dashedPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..strokeWidth = 1;

    // Draw dashed horizontal lines
    _drawDashedLine(
      canvas,
      Offset(0, happyY),
      Offset(size.width, happyY),
      dashedPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, neutralY),
      Offset(size.width, neutralY),
      dashedPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, sadY),
      Offset(size.width, sadY),
      dashedPaint,
    );

    // Draw the emotional timeline
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];
      final controlPointX = p0.dx + (p1.dx - p0.dx) / 2;

      path.cubicTo(controlPointX, p0.dy, controlPointX, p1.dy, p1.dx, p1.dy);
    }

    canvas.drawPath(path, linePaint);

    // Draw dots at each point
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotStrokePaint);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 5,
    double dashSpace = 5,
  }) {
    // Create path for dashed line
    final path = Path()..moveTo(start.dx, start.dy);

    // Calculate length of line
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);

    // Calculate dash count
    final dashCount = (length / (dashLength + dashSpace)).floor();

    // Calculate step vector
    final stepX = dx / dashCount / (dashLength + dashSpace);
    final stepY = dy / dashCount / (dashLength + dashSpace);

    // Draw dashes
    double startX = start.dx;
    double startY = start.dy;

    for (int i = 0; i < dashCount; i++) {
      final endX = startX + stepX * dashLength;
      final endY = startY + stepY * dashLength;

      path.moveTo(startX, startY);
      path.lineTo(endX, endY);

      startX += stepX * (dashLength + dashSpace);
      startY += stepY * (dashLength + dashSpace);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _EmotionScreenState extends State<EmotionScreen> {
  double imageLeftPosition = 0.0;

  // Reports data - changed from final to allow updates
  List<Map<String, dynamic>> _sessionReports = [
    {
      'id': 'AUX-1234',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'game': 'Happy Hills',
      'duration': 7.5,
      'dominantEmotion': 'happy',
      'emotionMetrics': {'happy': 62, 'neutral': 25, 'surprised': 8, 'sad': 5},
      'notes':
          'Good emotional engagement, responded well to positive reinforcement.',
      'score': 85,
    },
    {
      'id': 'AUX-1235',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'game': 'Calm Forest',
      'duration': 5.2,
      'dominantEmotion': 'neutral',
      'emotionMetrics': {'neutral': 55, 'happy': 30, 'sad': 12, 'surprised': 3},
      'notes': 'Showed improved focus. Calming techniques were effective.',
      'score': 70,
    },
    {
      'id': 'AUX-1236',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'game': 'Angry Volcano',
      'duration': 6.8,
      'dominantEmotion': 'neutral',
      'emotionMetrics': {
        'neutral': 40,
        'happy': 28,
        'angry': 20,
        'surprised': 12,
      },
      'notes':
          'Successfully implemented breathing techniques during frustration moments.',
      'score': 65,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Load Happy Hills reports when accessing professional section
    _loadHappyHillsReports();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void moveImageLeft() {
    setState(() {
      imageLeftPosition = (imageLeftPosition - 20).clamp(
        0.0,
        MediaQuery.of(context).size.width - 200,
      );
    });
  }

  void moveImageRight() {
    setState(() {
      imageLeftPosition = (imageLeftPosition + 20).clamp(
        0.0,
        MediaQuery.of(context).size.width - 200,
      );
    });
  }

  // Happy Hills summary card

  // This is an implementation of a bar chart for emotion data
  // Currently using the _buildEnhancedEmotionChart with donut visualization instead
  /*
  Widget _buildEmotionChart(Map<String, dynamic> emotionData) {
    return Row(
      children: [
        // Bar chart
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      emotionData.entries.map((entry) {
                        final Color barColor = _getEmotionColor(entry.key);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Value label
                                Text(
                                  '${entry.value}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Animated bar
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Container(
                                      height: 120 * entry.value / 100 * value,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Emotion label
                                Text(
                                  _capitalizeFirst(entry.key),
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 1, color: Colors.grey.shade300),
            ],
          ),
        ),

        // Legend
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  emotionData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                            '${_capitalizeFirst(entry.key)}: ${entry.value}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  */

  // This is a basic info row layout, kept for potential future use
  // Currently using more specialized UI components for info display
  /*
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  */

  // This method was replaced by the more customizable _buildEnhancedObservationItem
  // Kept as reference for simpler observation layout
  /*
  Widget _buildObservationItem({
    required String title,
    required String value,
    required IconData iconData,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  */

  // This simplified recommendation item has been replaced by _buildEnhancedRecommendationItem
  // Keeping for reference in case we need to revert to a simpler design
  /*
  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
  */

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'surprised':
        return Colors.purple;
      case 'neutral':
        return Colors.green;
      case 'fear':
        return Colors.indigo;
      case 'disgust':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Method to load Happy Hills reports from shared preferences
  Future<void> _loadHappyHillsReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = prefs.getStringList('happy_hills_reports') ?? [];

      if (reports.isNotEmpty) {
        setState(() {
          // Process and add Happy Hills reports to session reports
          for (var reportJson in reports) {
            try {
              final Map<String, dynamic> data = jsonDecode(reportJson);

              // Convert timestamp back to DateTime
              data['date'] = DateTime.fromMillisecondsSinceEpoch(
                data['date'] as int,
              );

              // Make emotionMetrics values integers instead of doubles for consistency with mock data
              final Map<String, dynamic> emotionMetrics = {};
              (data['emotionMetrics'] as Map<String, dynamic>).forEach((
                emotion,
                value,
              ) {
                emotionMetrics[emotion] = (value as double).round();
              });
              data['emotionMetrics'] = emotionMetrics;

              // Add report to the beginning of the list (most recent first)
              _sessionReports.insert(0, data);
            } catch (e) {
              print('Error parsing Happy Hills report: $e');
            }
          }

          // Limit the number of reports if there are too many
          if (_sessionReports.length > 10) {
            _sessionReports = _sessionReports.sublist(0, 10);
          }
        });
      }
    } catch (e) {
      print('Error loading Happy Hills reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the image position to center it horizontally
    imageLeftPosition = (MediaQuery.of(context).size.width - 400) / 2 - 20;
    // Calculate appropriate image sizes based on screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    // We're only using screenHeight for image size calculations

    // Change this line to increase the image size
    final imageHeight =
        screenHeight * 1.25; // Increased from 0.7 to 0.85 - makes image bigger
    final imageWidth = imageHeight * (510 / 1230); // Maintain aspect ratio

    return Scaffold(
      backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
      appBar: AppBar(
        title: const Text(
          'Emotion Therapy',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          Stack(
            children: [
              // Full screen bottom-aligned background image with 30px offset
              Positioned(
                bottom:
                    -60, // Increased to move image further down to the bottom
                left: 0,
                right: 0,
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Image.asset(
                    'assets/images/eappface.png',
                    fit: BoxFit.contain,
                    alignment:
                        Alignment.bottomCenter, // Ensure image aligns to bottom
                  ),
                ),
              ),

              // Content Container - Adjusted padding and layout
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kid-friendly title moved up slightly
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 15),
                      child: Text(
                        "Let's Have Fun!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(1, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Activity buttons moved up
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Play Games Button - Smaller and more professional
                          _buildKidFriendlyButton(
                            icon: Icons.videogame_asset,
                            label: 'Play Games',
                            color: const Color(
                              0xFF3F51B5,
                            ), // Professional indigo
                            onPressed: () {
                              Navigator.pushNamed(context, '/games');
                            },
                          ),

                          const SizedBox(
                            height: 20,
                          ), // Reduced space between buttons
                          // Music Therapy Button - Smaller and more professional
                          _buildKidFriendlyButton(
                            icon: Icons.music_note,
                            label: 'Music Therapy',
                            color: const Color(0xFF00796B), // Professional teal
                            onPressed: () {
                              Navigator.pushNamed(context, '/music');
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Updated method for smaller, more professional buttons
  Widget _buildKidFriendlyButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 85, // Reduced height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.85)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Icon with refined styling
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28, // Smaller icon
                  ),
                ),
                const SizedBox(width: 16),
                // Button text with more professional styling
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 20, // Smaller text
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        label == 'Play Games'
                            ? 'Learn emotions through fun activities'
                            : 'Relax with calming sounds',
                        style: TextStyle(
                          fontSize: 11, // Smaller subtitle
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // This method is kept for future use when implementing report status chips
  // Currently using _buildFilterChip for similar functionality
  /*
  Widget _buildReportChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }
  */
}
