import 'package:autismotech_app/Widget/bottom_navigation.dart';
import 'package:autismotech_app/screens/ProgressSummaryScreen.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/screens/global.dart' as globals;
import 'package:flutter/material.dart';
import 'dart:math' as math;

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen>
    with TickerProviderStateMixin {
  Map<int, String> initialAnswers = {};
  Map<int, String> followupAnswers = {};
  bool isFollowUp = false;
  bool _isSubmitting = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _cardController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _cardScaleAnimation;

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _cardController.forward();
    
    _updateProgressAnimation();
  }

  void _updateProgressAnimation() {
    final currentAnswers = isFollowUp ? followupAnswers : initialAnswers;
    final progress = currentAnswers.length / questions.length;
    _progressController.animateTo(progress);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!isFollowUp) {
      setState(() {
        isFollowUp = true;
      });
      _updateProgressAnimation();
      _cardController.reset();
      _cardController.forward();
    } else {
      _submitData();
    }
  }

  int _convertAnswer(int index, String? answer) {
    const yesImprovedIndices = [0, 1, 2, 9];
    if (yesImprovedIndices.contains(index)) {
      return answer == 'Yes' ? 1 : 0;
    } else {
      return answer == 'No' ? 1 : 0;
    }
  }

  Future<void> _submitData() async {
    if (initialAnswers.length < questions.length ||
        followupAnswers.length < questions.length) {
      _showErrorSnackBar("Please answer all questions before submitting.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.sendPrediction(
        userId: globals.globalUserId!,
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

      _showSuccessSnackBar("Responses submitted successfully!");
      
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProgressSummaryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      _showErrorSnackBar("Failed to submit responses: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.08 : screenWidth * 0.05;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProgressSummaryScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildGlassAppBar(isTablet),
        body: Container(
          decoration: _buildGradientBackground(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      _buildHeaderCard(isTablet),
                      SizedBox(height: screenHeight * 0.03),
                      _buildProgressIndicator(isTablet),
                      SizedBox(height: screenHeight * 0.03),
                      Expanded(
                        child: _buildQuestionsSection(isTablet),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildSubmitButton(isTablet),
                      SizedBox(height: screenHeight * 0.01),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(initialIndex: 1),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(bool isTablet) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor.withOpacity(0.9),
                  const Color(0xFF667EEA).withOpacity(0.8),
                  AppColors.primaryColor.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
      ),
      title: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white,
                  Colors.white.withOpacity(0.8),
                ],
                stops: [
                  math.max(0.0, _shimmerAnimation.value - 0.3),
                  _shimmerAnimation.value,
                  math.min(1.0, _shimmerAnimation.value + 0.3),
                ],
              ).createShader(bounds);
            },
            child: Text(
              'Questionnaire',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isTablet ? 26 : 22,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      ),
      centerTitle: true,
      leading: Container(
        margin: EdgeInsets.all(isTablet ? 12 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProgressSummaryScreen()),
          ),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF667EEA),
          AppColors.primaryColor,
          const Color(0xFF764BA2),
          AppColors.primaryColor.withOpacity(0.8),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  Widget _buildHeaderCard(bool isTablet) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        decoration: _buildGlassCard(),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFollowUp ? Icons.assignment_turned_in_rounded : Icons.quiz_rounded,
                      color: Colors.white,
                      size: isTablet ? 32 : 28,
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: isTablet ? 24 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFollowUp ? 'Follow-Up Assessment' : 'Initial Assessment',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 8 : 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isFollowUp ? 'Week 6' : 'Week 3',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isTablet) {
    final currentAnswers = isFollowUp ? followupAnswers : initialAnswers;
    final progress = currentAnswers.length / questions.length;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: _buildGlassCard(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${currentAnswers.length}/${questions.length}',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            height: isTablet ? 12 : 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        const Color(0xFF667EEA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  width: MediaQuery.of(context).size.width * progress * _progressAnimation.value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(bool isTablet) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: List.generate(questions.length, (index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, animation, child) {
              return Transform.scale(
                scale: animation,
                child: Container(
                  margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                  child: _buildQuestionCard(index, questions[index], isTablet),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildQuestionCard(int index, String question, bool isTablet) {
    final currentAnswers = isFollowUp ? followupAnswers : initialAnswers;
    final isAnswered = currentAnswers.containsKey(index);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(isAnswered ? 0.3 : 0.25),
            Colors.white.withOpacity(isAnswered ? 0.15 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAnswered 
              ? AppColors.primaryColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
          width: isAnswered ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAnswered 
                ? AppColors.primaryColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              if (isAnswered)
                Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: isTablet ? 20 : 18,
                  ),
                ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            children: [
              Expanded(child: _buildOptionButton(index, 'Yes', isTablet)),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(child: _buildOptionButton(index, 'No', isTablet)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int questionIndex, String label, bool isTablet) {
    final currentAnswers = isFollowUp ? followupAnswers : initialAnswers;
    final isSelected = currentAnswers[questionIndex] == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isFollowUp) {
            followupAnswers[questionIndex] = label;
          } else {
            initialAnswers[questionIndex] = label;
          }
        });
        _updateProgressAnimation();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.8),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  margin: EdgeInsets.only(right: isTablet ? 8 : 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: isTablet ? 20 : 18,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isTablet) {
    final currentAnswers = isFollowUp ? followupAnswers : initialAnswers;
    final isComplete = currentAnswers.length == questions.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isTablet ? 64 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isComplete
              ? [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ]
              : [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isComplete && !_isSubmitting ? _handleNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isTablet ? 24 : 20,
                    height: isTablet ? 24 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Text(
                    'SUBMITTING...',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFollowUp ? 'SUBMIT ASSESSMENT' : 'CONTINUE TO FOLLOW-UP',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: isComplete ? Colors.white : Colors.grey.shade400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 8 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isComplete ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFollowUp ? Icons.send_rounded : Icons.arrow_forward_rounded,
                      color: isComplete ? Colors.white : Colors.grey.shade400,
                      size: isTablet ? 20 : 18,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  BoxDecoration _buildGlassCard() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
