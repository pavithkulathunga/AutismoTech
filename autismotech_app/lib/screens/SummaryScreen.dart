import 'package:autismotech_app/Widget/bottom_navigation.dart';
import 'package:autismotech_app/screens/ProgressSummaryScreen.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/screens/global.dart' as globals;
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with TickerProviderStateMixin {
  String selectedTimeframe = 'Past Week';
  OverallPredictionResponse? overallResponse;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _cardController;
  late AnimationController _pulseController;
  
  // Add new controllers for background animations
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _pulseAnimation;
  
  // Background animation variables
  late Animation<Color?> _gradientAnimation1;
  late Animation<Color?> _gradientAnimation2;
  late Animation<Color?> _gradientAnimation3;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchOverallPrediction();
  }

  void _initializeAnimations() {
    // Existing animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Add new background animation controllers
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Existing animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.elasticOut),
    );
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // New background animations
    _gradientAnimation1 = ColorTween(
      begin: const Color(0xFF6448FE),
      end: const Color(0xFF5FC3E4),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation2 = ColorTween(
      begin: const Color(0xFFE0C3FC),
      end: const Color(0xFF8EC5FC),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation3 = ColorTween(
      begin: const Color(0xFF6BAAFF),
      end: const Color(0xFFB06AB3),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
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
        _startAnimations();
      } else {
        print("Error: User ID is null");
      }
    } catch (error) {
      print("Error fetching overall prediction: $error");
    }
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _progressController.forward();
  }

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

  Color _getPredictionColor(int prediction) {
    switch (prediction) {
      case 1:
        return const Color(0xFF10B981);
      case 0:
        return const Color(0xFFF59E0B);
      case -1:
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getPredictionIcon(int prediction) {
    switch (prediction) {
      case 1:
        return Icons.trending_up_rounded;
      case 0:
        return Icons.trending_flat_rounded;
      case -1:
        return Icons.trending_down_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.08 : 20.0;
    
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
        backgroundColor: Colors.white, // Make scaffold background transparent
        extendBodyBehindAppBar: true, // Let content flow behind the AppBar
        appBar: _buildAppBar(),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _backgroundController,
            _particleAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Stack(
              children: [
                // Beautiful animated background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(_gradientAnimation1.value, _gradientAnimation3.value, 
                          0.6 + 0.3 * math.sin(_backgroundController.value * 2 * math.pi))!,
                        Color.lerp(_gradientAnimation2.value, _gradientAnimation1.value,
                          0.7 + 0.2 * math.cos(_backgroundController.value * 3 * math.pi))!,
                        Color.lerp(_gradientAnimation3.value, _gradientAnimation2.value,
                          0.5 + 0.4 * math.sin(_backgroundController.value * 1.5 * math.pi))!,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                
                // Floating particles
                _buildFloatingParticles(),
                
                // Content with overlay to ensure readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.6),
                        Colors.white.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: child,
                ),
              ],
            );
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top),
                      _buildHeader(isTablet),
                      const SizedBox(height: 24),
                      _buildSummaryCard(isTablet),
                      const SizedBox(height: 24),
                      _buildInsightsSection(isTablet),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(initialIndex: 2),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return Stack(
      children: List.generate(15, (index) {
        final delay = index * 0.1;
        final animationValue = (_particleAnimation.value + delay) % 1.0;
        final size = MediaQuery.of(context).size;
        
        return Positioned(
          left: (index * 0.13 * size.width + animationValue * 100) % size.width,
          top: (index * 0.17 * size.height + animationValue * 200) % size.height,
          child: Container(
            width: 4 + (index % 3) * 2,
            height: 4 + (index % 3) * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(_glowAnimation.value * 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              '✨ Progress Summary',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: const Color.fromARGB(0, 255, 0, 0),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () => _fetchOverallPrediction(),
            icon: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
            AppColors.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.08),
            blurRadius: 25,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  const Color(0xFF667EEA),
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
              Icons.analytics_outlined,
              color: Colors.white,
              size: isTablet ? 32 : 28,
            ),
          ),
          SizedBox(width: isTablet ? 24 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Comprehensive Analysis",
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Your child's behavioral progress insights",
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: selectedTimeframe,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primaryColor,
          size: 20,
        ),
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        onChanged: (String? newValue) {
          setState(() {
            selectedTimeframe = newValue!;
          });
        },
        items: <String>[].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(bool isTablet) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: overallResponse == null ? _buildLoadingContent(isTablet) : _buildContent(isTablet),
      ),
    );
  }

  Widget _buildLoadingContent(bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withOpacity(0.1),
                AppColors.primaryColor.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 24 : 20),
        Text(
          "Analyzing Progress...",
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBlue,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          "Please wait while we compile your results",
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isTablet) {
    return Column(
      children: [
        _buildImprovementSection(isTablet),
        SizedBox(height: isTablet ? 32 : 24),
        _buildPredictionSection(isTablet),
        SizedBox(height: isTablet ? 32 : 24),
        _buildProgressSection(isTablet),
      ],
    );
  }

  Widget _buildImprovementSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Improvement',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Positive behavioral changes detected',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Text(
                  '+${overallResponse!.overallImprovementPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: isTablet ? 32 : 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                    letterSpacing: -1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSection(bool isTablet) {
    final predictionColor = _getPredictionColor(overallResponse!.overallPrediction);
    final predictionIcon = _getPredictionIcon(overallResponse!.overallPrediction);
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            predictionColor.withOpacity(0.1),
            predictionColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: predictionColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: predictionColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: predictionColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              predictionIcon,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress of Behaviour',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current behavioral trajectory',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: predictionColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatPrediction(overallResponse!.overallPrediction),
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress of an Activity',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Activity completion rate',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${overallResponse!.cnnProgressPercentage.toInt()}%',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Container(
            height: isTablet ? 16 : 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
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
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  width: MediaQuery.of(context).size.width * 
                        (overallResponse!.cnnProgressPercentage / 100) * 
                        _progressAnimation.value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Key Insights",
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBlue,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Row(
          children: [
            Expanded(child: _buildInsightCard(
              "Improvement Rate",
              "+${overallResponse?.overallImprovementPercentage.toStringAsFixed(1) ?? '0'}%",
              Icons.trending_up_rounded,
              const Color(0xFF10B981),
              isTablet,
            )),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(child: _buildInsightCard(
              "Activity Score",
              "${overallResponse?.cnnProgressPercentage.toInt() ?? 0}%",
              Icons.assessment_rounded,
              AppColors.primaryColor,
              isTablet,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
