import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

class _EmotionScreenState extends State<EmotionScreen>
    with SingleTickerProviderStateMixin {
  double imageLeftPosition = 0.0;
  bool _showProfessionalSection = false;
  late TabController _tabController;
  bool _isLoading = false;

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
    _tabController = TabController(length: 3, vsync: this);
    // Load Happy Hills reports when accessing professional section
    _loadHappyHillsReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _toggleProfessionalSection() {
    setState(() {
      _showProfessionalSection = !_showProfessionalSection;
    });
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) =>
                    _buildDetailedReportSheet(report, controller),
          ),
    );
  }

  Widget _buildDetailedReportSheet(
    Map<String, dynamic> report,
    ScrollController controller,
  ) {
    final dateFormatted = DateFormat('MMMM d, y').format(report['date']);
    final isHappyHills = report['game'] == 'Happy Hills';

    // Define color scheme based on game
    final List<Color> headerColors =
        isHappyHills
            ? [Colors.amber.shade600, Colors.amber.shade800]
            : [Colors.green.shade700, Colors.green.shade900];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Enhanced report header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              gradient: LinearGradient(
                colors: headerColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerColors[1].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isHappyHills ? Icons.psychology : Icons.analytics,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Clinical Analysis',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isHappyHills)
                            TextSpan(
                              text: ' • Happy Hills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Report metadata bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHeaderStat(
                        Icons.calendar_today_rounded,
                        dateFormatted,
                      ),
                      _buildHeaderStat(
                        Icons.access_time_rounded,
                        '${report['duration']} min',
                      ),
                      _buildHeaderStat(Icons.tag_rounded, report['id']),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),

          // Report content
          Expanded(
            child: ListView(
              controller: controller,
              padding:
                  isHappyHills ? EdgeInsets.zero : const EdgeInsets.all(20),
              children: [
                if (isHappyHills) _buildHappyHillsSummaryCard(report),

                // Performance summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Professional performance cards row
                      Row(
                        children: [
                          _buildPerformanceCard(
                            title: 'Score',
                            value: '${report['score']}',
                            subtitle: _getScoreLabel(report['score']),
                            icon: Icons.leaderboard_rounded,
                            color: _getScoreColor(report['score']),
                            isLarge: true,
                            units: '/100',
                          ),
                          const SizedBox(width: 12),
                          _buildPerformanceCard(
                            title: 'Engagement',
                            value: _getEngagementLevel(report['score']),
                            icon: Icons.insights_rounded,
                            color: _getEngagementColor(
                              _getEngagementLevel(report['score']),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Emotion-based metrics
                      Row(
                        children: [
                          _buildPerformanceCard(
                            title: 'Primary Emotion',
                            value: _capitalizeFirst(report['dominantEmotion']),
                            icon: Icons.emoji_emotions_rounded,
                            color: _getEmotionColor(report['dominantEmotion']),
                            subtitle:
                                '${report['emotionMetrics'][report['dominantEmotion']]}% of session',
                            showEmoji: true,
                            emotion: report['dominantEmotion'],
                          ),
                          const SizedBox(width: 12),
                          _buildPerformanceCard(
                            title: 'Emotional Range',
                            value: _getEmotionalRangeValue(
                              report['emotionMetrics'],
                            ),
                            icon: Icons.diversity_3_rounded,
                            color: _getEmotionalRangeColor(
                              _getEmotionalRangeValue(report['emotionMetrics']),
                            ),
                            subtitle: _getEmotionalRangeDescription(
                              _getEmotionalRangeValue(report['emotionMetrics']),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Enhanced emotion distribution chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        'Emotion Distribution',
                        Icons.pie_chart_rounded,
                        isHappyHills
                            ? Colors.amber.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border:
                              isHappyHills
                                  ? Border.all(
                                    color: Colors.amber.shade200,
                                    width: 1.5,
                                  )
                                  : null,
                        ),
                        child: _buildEnhancedEmotionChart(
                          report['emotionMetrics'],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Clinical observations with improved design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        'Clinical Observations',
                        Icons.psychology_alt_rounded,
                        isHappyHills
                            ? Colors.amber.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border:
                              isHappyHills
                                  ? Border.all(
                                    color: Colors.amber.shade200,
                                    width: 1.5,
                                  )
                                  : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEnhancedObservationItem(
                              title: 'Emotional Response',
                              value:
                                  isHappyHills
                                      ? 'Consistent positive emotional state throughout most of the session with ${report['emotionMetrics'][report['dominantEmotion']]}% ${report['dominantEmotion']} responses'
                                      : '${_capitalizeFirst(report['dominantEmotion'])} was the primary emotional state observed during this session.',
                              iconData: Icons.face_retouching_natural,
                              iconColor: _getEmotionColor(
                                report['dominantEmotion'],
                              ),
                              isHappyHills: isHappyHills,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedObservationItem(
                              title: 'Attention & Engagement',
                              value:
                                  isHappyHills
                                      ? 'Demonstrated ${_getEngagementLevel(report['score']).toLowerCase()} levels of engagement with consistent focus on game activities'
                                      : 'Patient showed ${_getEngagementLevel(report['score']).toLowerCase()} engagement throughout the session.',
                              iconData: Icons.visibility,
                              iconColor: _getEngagementColor(
                                _getEngagementLevel(report['score']),
                              ),
                              isHappyHills: isHappyHills,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedObservationItem(
                              title: 'Clinical Assessment',
                              value: report['notes'],
                              iconData: Icons.note_alt,
                              iconColor:
                                  isHappyHills
                                      ? Colors.amber.shade700
                                      : Colors.green.shade700,
                              isMultiLine: true,
                              isHappyHills: isHappyHills,
                            ),

                            if (isHappyHills) ...[
                              const SizedBox(height: 20),
                              _buildEnhancedObservationItem(
                                title: 'Emotional Transitions',
                                value:
                                    'Patient showed smooth transitions between emotional states with minimal distress during changes in game difficulty.',
                                iconData: Icons.sync_alt,
                                iconColor: Colors.blue.shade700,
                                isHappyHills: isHappyHills,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Visual patterns section for Happy Hills
                if (isHappyHills)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Emotional Pattern Analysis',
                          Icons.ssid_chart,
                          Colors.amber.shade700,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Timeline visualization
                              SizedBox(
                                height: 100,
                                child: _buildEmotionTimelineVisualization(),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              // Analysis text
                              Text(
                                'The patient maintained consistent emotional states during similar activities, '
                                'suggesting good emotional regulation. Transitions between emotions were triggered '
                                'primarily by changes in game difficulty and reward events.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Recommendations with actionable insights
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        'Clinical Recommendations',
                        Icons.lightbulb_rounded,
                        isHappyHills
                            ? Colors.amber.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border:
                              isHappyHills
                                  ? Border.all(
                                    color: Colors.amber.shade200,
                                    width: 1.5,
                                  )
                                  : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEnhancedRecommendationItem(
                              'Continue with regular emotional recognition exercises focused on ${report['dominantEmotion'] == 'happy' ? 'maintaining positive emotional states' : 'improving ' + report['dominantEmotion'] + ' recognition'}',
                              priority: 'High',
                              isHappyHills: isHappyHills,
                            ),
                            _buildEnhancedRecommendationItem(
                              'Focus on transition scenarios that triggered ${report['dominantEmotion'] == 'happy' ? 'positive' : 'challenging'} emotions during gameplay to build emotional resilience',
                              priority: 'Medium',
                              isHappyHills: isHappyHills,
                            ),
                            _buildEnhancedRecommendationItem(
                              'Practice ${_getRecommendedActivity(report['dominantEmotion'])} to build on current progress and strengthen emotional intelligence',
                              priority: 'Medium',
                              isHappyHills: isHappyHills,
                            ),
                            if (isHappyHills)
                              _buildEnhancedRecommendationItem(
                                'Gradually increase game difficulty to challenge emotional regulation skills while maintaining engagement',
                                priority: 'Low',
                                isHappyHills: isHappyHills,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Actions with improved styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Download PDF functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Downloading clinical report as PDF...',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Export Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isHappyHills
                                    ? Colors.amber.shade700
                                    : Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                            // Share functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sharing report with healthcare team...',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                isHappyHills
                                    ? Colors.amber.shade700
                                    : Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isHappyHills
                                        ? Colors.amber.shade300
                                        : Colors.green.shade300,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Happy Hills summary card
  Widget _buildHappyHillsSummaryCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade500, Colors.amber.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Happy Hills Therapy Game',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Emotional intelligence training',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHappyHillsStatBox(
                'Engagement',
                '${report['score']}%',
                Colors.white,
              ),
              _buildHappyHillsStatBox(
                'Primary Emotion',
                _capitalizeFirst(report['dominantEmotion']),
                _getEmotionColor(report['dominantEmotion']),
                showEmoji: true,
                emotion: report['dominantEmotion'],
              ),
              _buildHappyHillsStatBox(
                'Emotional Range',
                _getEmotionalRangeValue(report['emotionMetrics']),
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Happy Hills stat box
  Widget _buildHappyHillsStatBox(
    String label,
    String value,
    Color textColor, {
    bool showEmoji = false,
    String emotion = '',
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (showEmoji)
              Text(
                _getEmotionEmoji(emotion),
                style: const TextStyle(fontSize: 18),
              ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Performance card widget
  Widget _buildPerformanceCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool isLarge = false,
    String units = '',
    bool showEmoji = false,
    String emotion = '',
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (showEmoji) ...[
                  Text(
                    _getEmotionEmoji(emotion),
                    style: TextStyle(fontSize: isLarge ? 22 : 18),
                  ),
                  const SizedBox(width: 6),
                ],
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: isLarge ? 24 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (units.isNotEmpty)
                        TextSpan(
                          text: units,
                          style: TextStyle(
                            fontSize: isLarge ? 16 : 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Header stat for report header
  Widget _buildHeaderStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
        ),
      ],
    );
  }

  // Modern section header
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Enhanced emotion chart
  Widget _buildEnhancedEmotionChart(Map<String, dynamic> emotionData) {
    // Create sorted list of emotions
    final List<MapEntry<String, dynamic>> sortedEmotions =
        emotionData.entries.toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Row(
      children: [
        // Modern donut chart - takes 60% of space
        Expanded(flex: 6, child: _buildModernDonutChart(sortedEmotions)),

        // Legend and statistics - takes 40% of space
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emotion Breakdown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                // Show top 5 emotions or all if less than 5
                ...sortedEmotions
                    .take(5)
                    .map(
                      (entry) => _buildEmotionLegendItem(
                        entry.key,
                        entry.value as int,
                        _getEmotionColor(entry.key),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Primary: ${_capitalizeFirst(sortedEmotions.first.key)} (${sortedEmotions.first.value}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getEmotionColor(sortedEmotions.first.key),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Emotion legend item
  Widget _buildEmotionLegendItem(String emotion, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Color indicator
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          // Emotion text
          Text(_getEmotionEmoji(emotion), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          // Emotion name and percentage
          Expanded(
            child: Row(
              children: [
                Text(
                  _capitalizeFirst(emotion),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                const Spacer(),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern donut chart placeholder
  Widget _buildModernDonutChart(
    List<MapEntry<String, dynamic>> sortedEmotions,
  ) {
    // This would ideally be implemented with a proper chart library
    // For now, we'll display a placeholder
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getEmotionEmoji(sortedEmotions.first.key),
                  style: const TextStyle(fontSize: 24),
                ),
                Text(
                  '${sortedEmotions.first.value}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  _capitalizeFirst(sortedEmotions.first.key),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // This would be replaced with actual chart segments
          ...List.generate(sortedEmotions.length, (index) {
            final startAngle = index * (2 * 3.14159 / sortedEmotions.length);
            final endAngle =
                (index + 1) * (2 * 3.14159 / sortedEmotions.length);
            final emotion = sortedEmotions[index].key;

            return Positioned(
              top: 75 + 60 * sin((startAngle + endAngle) / 2),
              left: 75 + 60 * cos((startAngle + endAngle) / 2),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getEmotionColor(emotion),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getEmotionEmoji(emotion),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Enhanced observation item
  Widget _buildEnhancedObservationItem({
    required String title,
    required String value,
    required IconData iconData,
    required Color iconColor,
    bool isMultiLine = false,
    bool isHappyHills = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      isHappyHills
                          ? Colors.amber.shade800
                          : Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced recommendation item
  Widget _buildEnhancedRecommendationItem(
    String text, {
    required String priority,
    required bool isHappyHills,
  }) {
    final Color priorityColor =
        priority == 'High'
            ? Colors.red.shade400
            : (priority == 'Medium'
                ? Colors.orange.shade400
                : Colors.blue.shade400);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: priorityColor.withOpacity(0.3)),
            ),
            child: Text(
              priority,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: priorityColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Emotion timeline visualization placeholder
  Widget _buildEmotionTimelineVisualization() {
    // This would be ideally implemented with a proper chart library
    // For now, creating a simplified visualization
    return Row(
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('😃', style: TextStyle(fontSize: 14)),
            Text('😐', style: TextStyle(fontSize: 14)),
            Text('😢', style: TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(width: 8),
        // Timeline chart
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: TimelineChartPainter(),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'End',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for emotional range calculation
  String _getEmotionalRangeValue(Map<String, dynamic> emotionMetrics) {
    int nonZeroEmotions = 0;
    emotionMetrics.forEach((emotion, value) {
      if ((value as int) > 5) nonZeroEmotions++;
    });

    if (nonZeroEmotions >= 4) return 'High';
    if (nonZeroEmotions >= 2) return 'Moderate';
    return 'Low';
  }

  // Helper for emotional range description
  String _getEmotionalRangeDescription(String range) {
    switch (range) {
      case 'High':
        return 'Wide variety of emotions';
      case 'Moderate':
        return 'Some emotional variation';
      case 'Low':
        return 'Limited emotional range';
      default:
        return '';
    }
  }

  // Helper for emotional range color
  Color _getEmotionalRangeColor(String range) {
    switch (range) {
      case 'High':
        return Colors.purple.shade600;
      case 'Moderate':
        return Colors.blue.shade600;
      case 'Low':
        return Colors.orange.shade600;
      default:
        return Colors.grey;
    }
  }

  // Helper for score color
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.amber.shade600;
    return Colors.red.shade600;
  }

  // Helper for engagement color
  Color _getEngagementColor(String engagement) {
    switch (engagement) {
      case 'High':
        return Colors.green.shade600;
      case 'Moderate':
        return Colors.blue.shade600;
      case 'Variable':
        return Colors.amber.shade600;
      case 'Low':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  String _getEngagementLevel(int score) {
    if (score >= 80) return 'High';
    if (score >= 60) return 'Moderate';
    if (score >= 40) return 'Variable';
    return 'Low';
  }

  String _getRecommendedActivity(String emotion) {
    switch (emotion) {
      case 'happy':
        return 'social storytelling activities';
      case 'neutral':
        return 'emotional identification exercises';
      case 'sad':
        return 'positive affirmation techniques';
      case 'angry':
        return 'self-regulation strategies';
      case 'surprised':
        return 'predictability enhancement methods';
      default:
        return 'structured emotional activities';
    }
  }

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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildAuthenticationDialog() {
    final TextEditingController _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text('Professional Access'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your professional access code:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Access Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter access code';
                }
                if (value != '1234') {
                  return 'Invalid access code';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Access code "1234" has been validated in the validator
              Navigator.pop(context);
              setState(() {
                _showProfessionalSection = true;
                _isLoading = true;
              });

              // Simulate loading data
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Access'),
        ),
      ],
    );
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
          AnimatedOpacity(
            opacity: _showProfessionalSection ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
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
                          Alignment
                              .bottomCenter, // Ensure image aligns to bottom
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
                              color: const Color(
                                0xFF00796B,
                              ), // Professional teal
                              onPressed: () {
                                Navigator.pushNamed(context, '/music');
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Professional access section - Kept at the bottom
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildProfessionalAccessButton(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Professional section overlay
          AnimatedOpacity(
            opacity: _showProfessionalSection ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child:
                _showProfessionalSection
                    ? _buildProfessionalSection()
                    : const SizedBox(),
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

  // New method to build professional access button
  Widget _buildProfessionalAccessButton() {
    return Opacity(
      opacity: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _buildAuthenticationDialog(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white.withOpacity(0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'For Professionals',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade800,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _toggleProfessionalSection,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Clinical Reports & Analysis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      onPressed: () {
                        // Show help info
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help section coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Reports'),
                      Tab(text: 'Progress'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingState()
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReportsTab(),
                        _buildProgressTab(),
                        _buildSettingsTab(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading clinical data...',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        // Professional Search and Filter UI with elevated design
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern dashboard header with insights
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade700, Colors.green.shade900],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with count
                    Row(
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Clinical Insights',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                size: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_sessionReports.length} Reports',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Quick stats
                    Row(
                      children: [
                        _buildQuickStat(
                          "Happy Hills",
                          "Primary Game",
                          Icons.videogame_asset_rounded,
                        ),
                        _buildQuickStat(
                          "Happy",
                          "Most Common Emotion",
                          Icons.sentiment_very_satisfied_rounded,
                        ),
                        _buildQuickStat(
                          "78%",
                          "Avg. Engagement",
                          Icons.show_chart_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Enhanced search with filters
              Row(
                children: [
                  // Search field with refined styling
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search reports by game or ID...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Filter button with modern styling
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Show filter options
                          _showFilterOptions();
                        },
                        child: Center(
                          child: Icon(
                            Icons.tune,
                            color: Colors.blueGrey.shade700,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Filter chips with improved design
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Last 7 Days',
                        isSelected: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'High Scores',
                        isSelected: false,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Happy Hills',
                        isSelected: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reports list with modern card design
        Expanded(
          child:
              _sessionReports.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _sessionReports.length,
                    itemBuilder: (context, index) {
                      final report = _sessionReports[index];
                      final dateFormatted = DateFormat(
                        'MMM d, y',
                      ).format(report['date']);

                      // Determine status color based on score
                      final score = report['score'] as int;
                      final Color statusColor =
                          score > 80
                              ? Colors.green
                              : (score > 60 ? Colors.orange : Colors.red);

                      // Highlight Happy Hills game with special styling
                      final bool isHappyHills = report['game'] == 'Happy Hills';

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: isHappyHills ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  isHappyHills
                                      ? Colors.amber.shade300
                                      : Colors.grey.shade200,
                              width: isHappyHills ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showReportDetails(report),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration:
                                  isHappyHills
                                      ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [
                                            Colors.amber.shade50,
                                            Colors.white,
                                          ],
                                        ),
                                      )
                                      : null,
                              child: Column(
                                children: [
                                  // Report header with game and ID
                                  Row(
                                    children: [
                                      // Game icon with styled container
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _getGameColor(
                                            report['game'],
                                          ).withOpacity(
                                            isHappyHills ? 0.15 : 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow:
                                              isHappyHills
                                                  ? [
                                                    BoxShadow(
                                                      color: Colors.amber
                                                          .withOpacity(0.2),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        child: Icon(
                                          _getGameIcon(report['game']),
                                          color: _getGameColor(report['game']),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Game details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  report['game'] as String,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color:
                                                        isHappyHills
                                                            ? Colors
                                                                .amber
                                                                .shade800
                                                            : Colors
                                                                .blueGrey
                                                                .shade800,
                                                  ),
                                                ),
                                                if (isHappyHills) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.amber.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Latest',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors
                                                                .amber
                                                                .shade900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'ID: ${report['id']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Score indicator
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: statusColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${report['score']}/100',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _getScoreLabel(score),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  Divider(
                                    height: 1,
                                    color:
                                        isHappyHills
                                            ? Colors.amber.shade200
                                            : Colors.grey.shade200,
                                  ),
                                  const SizedBox(height: 12),

                                  // Report metrics in row with improved visualization
                                  Row(
                                    children: [
                                      _buildMetricItem(
                                        icon: Icons.date_range,
                                        value: dateFormatted,
                                        label: 'Session Date',
                                        highlight: isHappyHills,
                                      ),
                                      _buildMetricItem(
                                        icon: Icons.timer,
                                        value: '${report['duration']} min',
                                        label: 'Duration',
                                        highlight: isHappyHills,
                                      ),
                                      _buildMetricItem(
                                        icon: Icons.emoji_emotions,
                                        value: _getEmotionWithEmoji(
                                          report['dominantEmotion'] as String,
                                        ),
                                        label: 'Emotion',
                                        color: _getEmotionColor(
                                          report['dominantEmotion'] as String,
                                        ),
                                        highlight: isHappyHills,
                                      ),
                                    ],
                                  ),

                                  // Emotional metrics preview for Happy Hills
                                  if (isHappyHills) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.pie_chart_rounded,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Emotion Distribution',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildEmotionPreviewBars(
                                            report['emotionMetrics'],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // Action button with improved styling
                                  Row(
                                    children: [
                                      if (isHappyHills)
                                        TextButton.icon(
                                          onPressed: () {
                                            // Add sharing functionality
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Sharing report with healthcare team...',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.share,
                                            size: 16,
                                          ),
                                          label: const Text('Share'),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.blueGrey.shade600,
                                          ),
                                        ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed:
                                            () => _showReportDetails(report),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isHappyHills
                                                  ? Colors.amber.shade600
                                                  : Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Full Analysis',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // Helper widget for emotion preview bars
  Widget _buildEmotionPreviewBars(Map<String, dynamic> emotionData) {
    final List<MapEntry<String, dynamic>> sortedEmotions =
        emotionData.entries.toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Row(
      children:
          sortedEmotions.take(3).map((entry) {
            final String emotion = entry.key;
            final int percentage = entry.value as int;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _getEmotionColor(emotion),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getEmotionEmoji(emotion),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // Helper widget for quick stats in dashboard header
  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for emoji text by emotion name
  String _getEmotionEmoji(String emotion) {
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

  // Helper to get emotion name with emoji
  String _getEmotionWithEmoji(String emotion) {
    final emoji = _getEmotionEmoji(emotion);
    return "$emoji ${_capitalizeFirst(emotion)}";
  }

  // Helper method to get score labels
  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Average';
    return 'Needs Attention';
  }

  // Helper method for game colors
  Color _getGameColor(String gameName) {
    switch (gameName) {
      case 'Happy Hills':
        return Colors.amber.shade700;
      case 'Angry Volcano':
        return Colors.red.shade700;
      case 'Calm Forest':
        return Colors.teal.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  // New filter chip widget for professional UI
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueGrey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.close, size: 12, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  // New filter options dialog
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Filter Reports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Filter options would go here
                Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                // Date range options
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Today',
                      isSelected: false,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: 'Last 7 Days',
                      isSelected: true,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: 'Last 30 Days',
                      isSelected: false,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: 'Custom Range',
                      isSelected: false,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // More filter options
                Text(
                  'Activity Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'All Activities',
                      isSelected: true,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: 'Happy Hills',
                      isSelected: false,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: 'Angry Volcano',
                      isSelected: false,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: 'Calm Forest',
                      isSelected: false,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Reset Filters'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  // New empty state for professional look
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Reports Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete therapy sessions to generate reports',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Helper method for metric items in report list
  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color ?? Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _buildSummaryCard(
                title: 'Sessions',
                value: '${_sessionReports.length}',
                icon: Icons.calendar_month,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: 'Avg. Score',
                value: '73',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Emotion progress chart
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emotional Progress Over Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last 5 sessions',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Progress Chart\n(Data visualization would appear here)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Clinical insights
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clinical Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInsightItem(
                        'Dominant emotion is happy (62%) indicating positive engagement with therapy exercises.',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildInsightItem(
                        'Consistent improvement in emotional regulation observed over the last 3 sessions.',
                        Icons.insights,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildInsightItem(
                        'Recommended focus on maintaining engagement during transitions between activities.',
                        Icons.lightbulb,
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),

          // Settings cards
          _buildSettingCard(
            title: 'Account Settings',
            icon: Icons.person,
            children: [
              _buildSettingItem(
                'Professional Profile',
                'Update your clinical credentials',
              ),
              _buildSettingItem(
                'Notification Preferences',
                'Manage alerts and reports',
              ),
              _buildSettingItem(
                'Privacy Settings',
                'Control data sharing permissions',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingCard(
            title: 'Clinical Tools',
            icon: Icons.medical_services,
            children: [
              _buildSettingItem(
                'Assessment Templates',
                'Customize evaluation criteria',
              ),
              _buildSettingItem(
                'Report Generation',
                'Configure automatic reporting',
              ),
              _buildSettingItem(
                'Data Visualization',
                'Adjust chart parameters',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingCard(
            title: 'Data Management',
            icon: Icons.storage,
            children: [
              _buildSettingItem('Export Data', 'Download in various formats'),
              _buildSettingItem('Archive Reports', 'Manage historical records'),
              _buildSettingItem(
                'Data Integration',
                'Connect with other clinical systems',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Settings items
          Column(children: children),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title settings will be available soon'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
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

  IconData _getGameIcon(String gameName) {
    switch (gameName) {
      case 'Happy Hills':
        return Icons.emoji_emotions;
      case 'Angry Volcano':
        return Icons.whatshot;
      case 'Calm Forest':
        return Icons.forest;
      default:
        return Icons.games;
    }
  }
}
