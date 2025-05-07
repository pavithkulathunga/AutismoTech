import 'package:asd_detection_flutter/Widget/bottom_navigation.dart';
import 'package:asd_detection_flutter/screens/ProgressSummaryScreen.dart';
import 'package:asd_detection_flutter/theme/colors.dart';
import 'package:asd_detection_flutter/screens/apiservice.dart';
import 'package:asd_detection_flutter/screens/global.dart' as globals;
import 'package:flutter/material.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  Map<int, String> initialAnswers = {}; // Stores Initial Questions Answers
  Map<int, String> followupAnswers = {}; // Stores Follow-Up Questions Answers
  bool isFollowUp = false; // Tracks if user is answering follow-up questions

  final List<String> questions = [
    "Does the child make eye contact with you during conversations?",
    "Does the child understand and follow verbal instructions?",
    "Has your child shown improvements in verbal communication, such as forming longer sentences or learning new words?",
    "Does the child repeat words or phrases over and over?",
    "Does the child get upset by minor changes in routine or surroundings?",
    "Does the child engage in repetitive actions like hand flapping, spinning, or lining up objects?",
    "Does the child often look at rotating objects?",
    "Does the child play alone and avoid interaction with other children?",
    "When you take the child outside the home, do their activities change?",
    "Have you observed improvements in the child's engagement in therapy or learning activities?",
  ];

  /// Handles "Next" button click
  void _handleNext() {
    if (!isFollowUp) {
      setState(() {
        isFollowUp = true;
      });
    } else {
      _submitData();
    }
  }

  /// Converts Yes/No answers into integer values.
  /// For questions 1, 2, 3, and 10 (indices 0, 1, 2, and 9): "Yes" indicates improvement (1).
  /// For the remaining questions: "No" indicates improvement (1).
  int _convertAnswer(int index, String? answer) {
    const yesImprovedIndices = [0, 1, 2, 9];
    if (yesImprovedIndices.contains(index)) {
      return answer == 'Yes' ? 1 : 0;
    } else {
      return answer == 'No' ? 1 : 0;
    }
  }

  /// Sends collected data to the API and navigates to ProgressSummaryScreen
  Future<void> _submitData() async {
    if (initialAnswers.length < questions.length ||
        followupAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions before submitting.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ApiService.sendPrediction(
        userId: globals.globalUserId!, // Ensure user_id is sent as an INTEGER
        initialData: {
          "Q1_Initial": _convertAnswer(0, initialAnswers[0]),
          "Q2_Initial": _convertAnswer(1, initialAnswers[1]),
          "Q3_Initial": _convertAnswer(2, initialAnswers[2]),
          "Q4_Initial": _convertAnswer(3, initialAnswers[3]),
          "Q5_Initial": _convertAnswer(4, initialAnswers[4]),
          "Q6_Initial": _convertAnswer(5, initialAnswers[5]),
          "Q7_Initial": _convertAnswer(6, initialAnswers[6]),
          "Q8_Initial": _convertAnswer(7, initialAnswers[7]),
          "Q9_Initial": _convertAnswer(8, initialAnswers[8]),
          "Q10_Initial": _convertAnswer(9, initialAnswers[9]),
        },
        followupData: {
          "Q1_Followup": _convertAnswer(0, followupAnswers[0]),
          "Q2_Followup": _convertAnswer(1, followupAnswers[1]),
          "Q3_Followup": _convertAnswer(2, followupAnswers[2]),
          "Q4_Followup": _convertAnswer(3, followupAnswers[3]),
          "Q5_Followup": _convertAnswer(4, followupAnswers[4]),
          "Q6_Followup": _convertAnswer(5, followupAnswers[5]),
          "Q7_Followup": _convertAnswer(6, followupAnswers[6]),
          "Q8_Followup": _convertAnswer(7, followupAnswers[7]),
          "Q9_Followup": _convertAnswer(8, followupAnswers[8]),
          "Q10_Followup": _convertAnswer(9, followupAnswers[9]),
        },
      );

      Navigator.of(context).pop(); // Remove loading indicator

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProgressSummaryScreen()),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Remove loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit responses: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        // Navigate to ProgressSummaryScreen when back button is pressed.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProgressSummaryScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFollowUp
                          ? 'Follow-Up Questionnaire'
                          : 'Progress Questionnaire',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    Text(
                      isFollowUp ? 'Week 4' : 'Week 3',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(questions.length, (index) {
                        return _buildQuestion(index, questions[index]);
                      }),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFollowUp ? 'Submit' : 'Next →',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(),
      ),
    );
  }

  Widget _buildQuestion(int index, String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. $question',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(child: _buildOption(index, 'Yes')),
              const SizedBox(width: 12),
              Flexible(child: _buildOption(index, 'No')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int questionIndex, String label) {
    bool isSelected = isFollowUp
        ? followupAnswers[questionIndex] == label
        : initialAnswers[questionIndex] == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isFollowUp) {
            followupAnswers[questionIndex] = label;
          } else {
            initialAnswers[questionIndex] = label;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(color: AppColors.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.darkBlue,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
