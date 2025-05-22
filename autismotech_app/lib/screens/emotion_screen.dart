import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen>
    with SingleTickerProviderStateMixin {
  double imageLeftPosition = 0.0;
  bool _showProfessionalSection = false;
  late TabController _tabController;
  bool _isLoading = false;

  // Mock data for reports
  final List<Map<String, dynamic>> _sessionReports = [
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
    final timeFormatted = DateFormat('h:mm a').format(report['date']);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Report header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade900],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Detailed Session Report',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${report['game']} - ${report['id']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
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
              padding: const EdgeInsets.all(20),
              children: [
                // Session metadata
                _buildInfoRow('Date', dateFormatted),
                _buildInfoRow('Time', timeFormatted),
                _buildInfoRow('Duration', '${report['duration']} minutes'),
                _buildInfoRow('Score', '${report['score']}/100'),

                const Divider(height: 32),

                // Emotion distribution chart
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emotion Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _buildEmotionChart(report['emotionMetrics']),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Clinical observations
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clinical Observations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildObservationItem(
                            title: 'Primary Emotional State',
                            value:
                                '${_capitalizeFirst(report['dominantEmotion'])} (${report['emotionMetrics'][report['dominantEmotion']]}%)',
                            iconData: Icons.psychology,
                          ),
                          const SizedBox(height: 16),
                          _buildObservationItem(
                            title: 'Engagement Level',
                            value: _getEngagementLevel(report['score']),
                            iconData: Icons.show_chart,
                          ),
                          const SizedBox(height: 16),
                          _buildObservationItem(
                            title: 'Clinical Notes',
                            value: report['notes'],
                            iconData: Icons.note_alt,
                            isMultiLine: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Recommendations
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecommendationItem(
                            'Continue with regular emotional recognition exercises',
                          ),
                          _buildRecommendationItem(
                            'Focus on transition scenarios that triggered ${report['dominantEmotion'] == 'happy' ? 'positive' : 'challenging'} emotions',
                          ),
                          _buildRecommendationItem(
                            'Practice ${_getRecommendedActivity(report['dominantEmotion'])} to build on current progress',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Download PDF functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading PDF report...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Share functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sharing report...')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

  @override
  Widget build(BuildContext context) {
    // Calculate the image position to center it horizontally
    imageLeftPosition = (MediaQuery.of(context).size.width - 400) / 2 - 20;
    // Calculate appropriate image sizes based on screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
        // Professional Search and Filter UI
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
              // Summary stats
              Row(
                children: [
                  Text(
                    'Clinical Reports',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_sessionReports.length} Reports',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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

              // Filter chips (optional - shown when filters are active)
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
                        isSelected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reports list with enhanced professional styling
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

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showReportDetails(report),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Report header with game and ID
                                  Row(
                                    children: [
                                      // Game icon with styled container
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _getGameColor(
                                            report['game'],
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                            Text(
                                              report['game'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
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
                                          Row(
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
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
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  // Report metrics in row
                                  Row(
                                    children: [
                                      _buildMetricItem(
                                        icon: Icons.date_range,
                                        value: dateFormatted,
                                        label: 'Session Date',
                                      ),
                                      _buildMetricItem(
                                        icon: Icons.timer,
                                        value: '${report['duration']} min',
                                        label: 'Duration',
                                      ),
                                      _buildMetricItem(
                                        icon: Icons.emoji_emotions,
                                        value: _capitalizeFirst(
                                          report['dominantEmotion'] as String,
                                        ),
                                        label: 'Primary Emotion',
                                        color: _getEmotionColor(
                                          report['dominantEmotion'] as String,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Action button
                                  Row(
                                    children: [
                                      const Spacer(),
                                      TextButton(
                                        onPressed:
                                            () => _showReportDetails(report),
                                        child: Row(
                                          children: [
                                            Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: Colors.blueGrey.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward,
                                              size: 16,
                                              color: Colors.blueGrey.shade700,
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
