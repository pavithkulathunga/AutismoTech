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
    imageLeftPosition = (MediaQuery.of(context).size.width - 400) / 2 - 20;

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
                Positioned(
                  top: 1,
                  left: imageLeftPosition,
                  child: SizedBox(
                    width: 510,
                    height: 1230,
                    child: Image.asset('assets/images/eappface.png'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30.0, 10.0, 16.0, 260.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green[900],
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 24.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.videogame_asset),
                          label: const Text(
                            'Play Games',
                            style: TextStyle(fontSize: 18),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/games');
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green[900],
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 24.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.music_note),
                          label: const Text(
                            'Music Therapy',
                            style: TextStyle(fontSize: 18),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/music');
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green[900],
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 24.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.assessment),
                          label: const Text(
                            'Professional Reports',
                            style: TextStyle(fontSize: 18),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => _buildAuthenticationDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Professional section
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
        // Search and filter section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search reports',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  // Show filter options
                },
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter reports',
              ),
            ],
          ),
        ),

        // Reports list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _sessionReports.length,
            itemBuilder: (context, index) {
              final report = _sessionReports[index];
              final dateFormatted = DateFormat(
                'MMM d, y',
              ).format(report['date']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onTap: () => _showReportDetails(report),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: Icon(
                      _getGameIcon(report['game']),
                      color: Colors.green.shade700,
                    ),
                  ),
                  title: Text(
                    '${report['game']} - ${report['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(dateFormatted),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildReportChip(
                            '${report['duration']} min',
                            Icons.timer,
                          ),
                          const SizedBox(width: 8),
                          _buildReportChip(
                            'Score: ${report['score']}',
                            Icons.star,
                          ),
                          const SizedBox(width: 8),
                          _buildReportChip(
                            _capitalizeFirst(report['dominantEmotion']),
                            Icons.emoji_emotions,
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
        ),
      ],
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
