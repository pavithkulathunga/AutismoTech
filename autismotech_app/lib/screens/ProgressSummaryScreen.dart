import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/Widget/bottom_navigation.dart';
import 'package:autismotech_app/constants/theme.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:flutter/material.dart';

class ProgressSummaryScreen extends StatelessWidget {
  const ProgressSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen width for responsive scaling.
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenWidth * 0.1),
              // Dynamic welcome text using a FutureBuilder to fetch the username.
              FutureBuilder<String>(
                future:
                    ApiService()
                        .getUsername(), // Access instance method correctly
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Welcome,',
                      style: textStyle.copyWith(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    print('Error fetching username: ${snapshot.error}');
                    return Text(
                      'Welcome,',
                      style: textStyle.copyWith(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else {
                    String username = snapshot.data ?? '';
                    return Text(
                      'Welcome $username,',
                      style: textStyle.copyWith(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                },
              ),

              _buildDetailedProgressSection(screenWidth),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }

  /// Welcome Message Card.
  Widget _buildWelcomeCard(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [AppColors.secondaryColor, AppColors.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Consistency is key!\nNo major changes yet, but every step counts.',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: AppColors.textColor,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Image.asset('assets/images/asd.png', width: screenWidth * 0.15),
        ],
      ),
    );
  }

  /// Summary Section with static progress bars.
  Widget _buildSummarySection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: textStyle.copyWith(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        // _buildProgressBar('Communication', Colors.green, 'Good', 0.9, screenWidth),
        // _buildProgressBar('Social Interaction', Colors.orange, 'Fair', 0.7, screenWidth),
        // _buildProgressBar('Sensory Sensitivities', Colors.green, 'Good', 0.85, screenWidth),
        // _buildProgressBar('Repetitive and Focused Behaviors', Colors.green, 'Good', 0.8, screenWidth),
        // _buildProgressBar('Emotional Regulation', Colors.red, 'Severe', 0.4, screenWidth),
        // _buildProgressBar('Engagement and Learning', Colors.orange, 'Fair', 0.6, screenWidth),
        // _buildProgressBar('Visual Behavior Analysis', Colors.green, 'Good', 0.9, screenWidth),
      ],
    );
  }

  /// Reusable widget for a progress bar.
  Widget _buildProgressBar(
    String title,
    Color color,
    String label,
    double value,
    double screenWidth,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textStyle.copyWith(fontSize: screenWidth * 0.045)),
          SizedBox(height: screenWidth * 0.01),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.secondaryColor.withOpacity(0.4),
                  color: color,
                  minHeight: screenWidth * 0.02,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Comparison Section (static) showing previous vs. current progress values.
  Widget _buildComparisonSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and dropdown button.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comparison',
              style: textStyle.copyWith(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenWidth * 0.015,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF90E0EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Last Week',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                    size: screenWidth * 0.05,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.02),
        _buildComparisonRow('Communication', 10, 0.9, 0.8, screenWidth),
        _buildComparisonRow('Social Interaction', 5, 0.7, 0.65, screenWidth),
        _buildComparisonRow(
          'Sensory Sensitivities',
          -4,
          0.85,
          0.9,
          screenWidth,
        ),
        _buildComparisonRow(
          'Repetitive and Focused Behaviors',
          1,
          0.8,
          0.78,
          screenWidth,
        ),
        _buildComparisonRow('Emotional Regulation', 7, 0.4, 0.3, screenWidth),
      ],
    );
  }

  /// Reusable widget to build a single comparison row.
  Widget _buildComparisonRow(
    String title,
    int change,
    double currentValue,
    double previousValue,
    double screenWidth,
  ) {
    bool isIncrease = change > 0;
    bool isDecrease = change < 0;
    Color changeColor =
        isIncrease ? Colors.green : (isDecrease ? Colors.red : Colors.grey);
    String changeText = '${isIncrease ? '+' : ''}$change%';
    String iconPath =
        isIncrease ? 'assets/images/up.png' : 'assets/images/down.png';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric title with change indicator.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: textStyle.copyWith(fontSize: screenWidth * 0.045),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: screenWidth * 0.01,
                ),
                decoration: BoxDecoration(
                  color: changeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(
                      changeText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Image.asset(
                      iconPath,
                      width: screenWidth * 0.03,
                      height: screenWidth * 0.03,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.error,
                          color: Colors.red,
                          size: screenWidth * 0.03,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.01),
          // Previous progress bar.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previous',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.blueGrey,
                ),
              ),
              SizedBox(height: screenWidth * 0.005),
              LinearProgressIndicator(
                value: previousValue,
                backgroundColor: AppColors.secondaryColor.withOpacity(0.4),
                color: Colors.blueGrey,
                minHeight: screenWidth * 0.02,
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.01),
          // Current progress bar.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: const Color(0xFF0077B6),
                ),
              ),
              SizedBox(height: screenWidth * 0.005),
              LinearProgressIndicator(
                value: currentValue,
                backgroundColor: Colors.transparent,
                color: const Color(0xFF0077B6),
                minHeight: screenWidth * 0.02,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Detailed Progress Section that fetches data from the backend and displays each metric in a Card.
  Widget _buildDetailedProgressSection(double screenWidth) {
    return FutureBuilder<DetailedProgressResponse>(
      future: ApiService.getDetailedProgress(), // Static method call
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            "Error loading detailed progress: ${snapshot.error}",
            style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.04),
          );
        } else {
          final detailedProgress = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Progress',
                style: textStyle.copyWith(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detailedProgress.metrics.length,
                itemBuilder: (context, index) {
                  final metric = detailedProgress.metrics[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.category,
                            style: textStyle.copyWith(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Previous',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "${metric.previous.toStringAsFixed(2)}%",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Followup',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "${metric.followup.toStringAsFixed(2)}%",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Improvement',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.green,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "${metric.improvement.toStringAsFixed(2)}%",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }
}
