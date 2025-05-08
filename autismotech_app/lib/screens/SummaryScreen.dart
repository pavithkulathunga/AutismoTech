import 'package:autismotech_app/Widget/bottom_navigation.dart';
import 'package:autismotech_app/screens/ProgressSummaryScreen.dart'; // Import added
import 'package:autismotech_app/constants/colors.dart';
import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/screens/global.dart' as globals;
import 'package:flutter/material.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String selectedTimeframe = 'Past Week';
  OverallPredictionResponse? overallResponse;

  @override
  void initState() {
    super.initState();
    _fetchOverallPrediction();
  }

  Future<void> _fetchOverallPrediction() async {
    try {
      if (globals.globalUserId != null) {
        final res = await ApiService.getOverallPrediction(
          userId: globals.globalUserId!,
        );
        setState(() {
          overallResponse = res;
        });
      } else {
        print("Error: User ID is null");
      }
    } catch (error) {
      print("Error fetching overall prediction: $error");
    }
  }

  /// Converts the prediction integer to a readable string.
  String _formatPrediction(int prediction) {
    switch (prediction) {
      case 1:
        return 'Improved';
      case 0:
        return 'No Change';
      case -1:
        return 'Declined';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        // Navigate to ProgressSummaryScreen when back button is pressed.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProgressSummaryScreen(),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: const Text('Summary'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section: Title & Dropdown for timeframe
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    _buildDropdown(),
                  ],
                ),
                const SizedBox(height: 16),
                // Summary Card displaying details
                _buildSummaryCard(),
                const SizedBox(height: 20),
                // Timeframe Selector Bar
                _buildTimeframeSelector(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(),
      ),
    );
  }

  /// Dropdown for selecting a timeframe.
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedTimeframe,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        underline: const SizedBox(),
        dropdownColor: AppColors.secondaryColor,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (String? newValue) {
          setState(() {
            selectedTimeframe = newValue!;
          });
        },
        items:
            <String>[
              'Past Week',
              '1 Month',
              '3 Months',
              '1 Year',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Builds the summary card with overall prediction details.
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: overallResponse == null ? _buildLoadingContent() : _buildContent(),
    );
  }

  /// Displays a loading indicator while data is being fetched.
  Widget _buildLoadingContent() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Displays the overall prediction details.
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row for Overall Improvement Percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overall Improvement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
            Text(
              '+${overallResponse!.overallImprovementPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.goodBorder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Row for Overall Prediction
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overall Prediction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
            Text(
              _formatPrediction(overallResponse!.overallPrediction),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Display CNN Progress with a progress bar.
        const Text(
          'CNN Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: overallResponse!.cnnProgressPercentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${overallResponse!.cnnProgressPercentage}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the timeframe selection bar.
  Widget _buildTimeframeSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Uncomment and implement buttons if needed.
          // _buildTimeframeButton('Past Week'),
          // _buildTimeframeButton('1 Month'),
          // _buildTimeframeButton('3 Months'),
          // _buildTimeframeButton('1 Year'),
        ],
      ),
    );
  }
}
