import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/Widget/bottom_navigation.dart';
import 'package:autismotech_app/constants/theme.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProgressSummaryScreen extends StatefulWidget {
  const ProgressSummaryScreen({Key? key}) : super(key: key);

  @override
  State<ProgressSummaryScreen> createState() => _ProgressSummaryScreenState();
}

class _ProgressSummaryScreenState extends State<ProgressSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _shimmerController;
  late AnimationController _cardController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _cardScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _floatingAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    _cardController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.08 : screenWidth * 0.05;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(isTablet),
      body: Container(
        decoration: _buildGradientBackground(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.12),
                    _buildWelcomeSection(screenWidth, isTablet),
                    SizedBox(height: screenHeight * 0.03),
                    _buildDetailedProgressSection(screenWidth, isTablet),
                    SizedBox(height: screenHeight * 0.12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
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
              'Progress Dashboard',
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
      actions: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                margin: EdgeInsets.only(right: isTablet ? 24 : 16),
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),
            );
          },
        ),
      ],
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

  Widget _buildWelcomeSection(double screenWidth, bool isTablet) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: _buildGlassCard(),
        child: FutureBuilder<String>(
          future: ApiService().getUsername(),
          builder: (context, snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatingAnimation.value),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.waving_hand_rounded,
                              color: Colors.amber.shade300,
                              size: isTablet ? 36 : 32,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (snapshot.connectionState == ConnectionState.waiting)
                            _buildShimmerText('Welcome,', isTablet)
                          else if (snapshot.hasError)
                            _buildGradientText('Welcome,', isTablet)
                          else
                            _buildGradientText(
                              'Welcome ${snapshot.data ?? ''},',
                              isTablet,
                            ),
                          SizedBox(height: isTablet ? 8 : 6),
                          Text(
                            "Let's explore your amazing journey together! ✨",
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 24 : 20),
                _buildInspirationQuote(isTablet),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInspirationQuote(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amber.shade200,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              'Consistency is key! Every step counts towards amazing progress.',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedProgressSection(double screenWidth, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Progress Analytics', isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        FutureBuilder<DetailedProgressResponse>(
          future: ApiService.getDetailedProgress(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading(isTablet);
            } else if (snapshot.hasError) {
              return _buildErrorCard(snapshot.error.toString(), isTablet);
            } else {
              final detailedProgress = snapshot.data!;
              return _buildProgressCards(detailedProgress, isTablet);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isTablet) {
    return _buildGradientText(title, isTablet, fontSize: isTablet ? 24 : 20);
  }

  Widget _buildProgressCards(DetailedProgressResponse detailedProgress, bool isTablet) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: detailedProgress.metrics.length,
      itemBuilder: (context, index) {
        final metric = detailedProgress.metrics[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, animation, child) {
            return Transform.scale(
              scale: animation,
              child: Container(
                margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                child: _buildMetricCard(metric, isTablet, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(MetricProgress metric, bool isTablet, int index) {
    final colors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF06FFA5), const Color(0xFF3D8BFF)],
      [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
      [const Color(0xFFDE6262), const Color(0xFFFFB88C)],
      [const Color(0xFF92FE9D), const Color(0xFF00C9FF)],
      [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)],
    ];
    
    final colorPair = colors[index % colors.length];
    final improvementPercentage = metric.improvement;
    final isImprovement = improvementPercentage > 0;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
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
            color: colorPair[0].withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colorPair),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorPair[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getMetricIcon(metric.category),
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
                      metric.category,
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 10,
                        vertical: isTablet ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: isImprovement 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isImprovement 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isImprovement 
                                ? Icons.trending_up_rounded
                                : Icons.trending_flat_rounded,
                            color: isImprovement ? Colors.green : Colors.orange,
                            size: isTablet ? 18 : 16,
                          ),
                          SizedBox(width: isTablet ? 6 : 4),
                          Text(
                            isImprovement ? 'Improving' : 'Stable',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: isImprovement ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 20),
          _buildProgressBars(metric, isTablet, colorPair),
          SizedBox(height: isTablet ? 20 : 16),
          _buildImprovementIndicator(metric, isTablet),
        ],
      ),
    );
  }

  Widget _buildProgressBars(MetricProgress metric, bool isTablet, List<Color> colors) {
    return Column(
      children: [
        _buildProgressBarRow(
          'Previous',
          metric.previous,
          Colors.grey.withOpacity(0.6),
          isTablet,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        _buildProgressBarRow(
          'Follow-up',
          metric.followup,
          colors[0],
          isTablet,
        ),
      ],
    );
  }

  Widget _buildProgressBarRow(String label, double value, Color color, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Container(
          height: isTablet ? 12 : 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 1500),
              tween: Tween(begin: 0.0, end: value / 100),
              curve: Curves.easeOutCubic,
              builder: (context, animation, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  width: MediaQuery.of(context).size.width * animation,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementIndicator(MetricProgress metric, bool isTablet) {
    final improvement = metric.improvement;
    final isPositive = improvement > 0;
    final isNeutral = improvement == 0;
    
    Color indicatorColor = isPositive 
        ? Colors.green 
        : isNeutral 
            ? Colors.orange 
            : Colors.red;
    
    IconData icon = isPositive 
        ? Icons.trending_up_rounded 
        : isNeutral 
            ? Icons.trending_flat_rounded 
            : Icons.trending_down_rounded;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: indicatorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 8 : 6),
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: indicatorColor,
              size: isTablet ? 20 : 18,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Improvement',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w800,
                    color: indicatorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isTablet) {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
          padding: EdgeInsets.all(isTablet ? 28 : 20),
          decoration: _buildGlassCard(),
          child: Column(
            children: [
              _buildShimmerContainer(double.infinity, isTablet ? 60 : 50),
              SizedBox(height: isTablet ? 20 : 16),
              _buildShimmerContainer(double.infinity, isTablet ? 12 : 10),
              SizedBox(height: isTablet ? 12 : 10),
              _buildShimmerContainer(double.infinity, isTablet ? 12 : 10),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShimmerContainer(double width, double height) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                math.max(0.0, _shimmerAnimation.value - 0.3),
                _shimmerAnimation.value,
                math.min(1.0, _shimmerAnimation.value + 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(String error, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: _buildGlassCard(),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade300,
              size: isTablet ? 48 : 40,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Unable to load progress data. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientText(String text, bool isTablet, {double? fontSize}) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [Colors.white, Colors.white.withOpacity(0.8)],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? (isTablet ? 28 : 24),
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildShimmerText(String text, bool isTablet) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.6),
                Colors.white,
                Colors.white.withOpacity(0.6),
              ],
              stops: [
                math.max(0.0, _shimmerAnimation.value - 0.3),
                _shimmerAnimation.value,
                math.min(1.0, _shimmerAnimation.value + 0.3),
              ],
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
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

  IconData _getMetricIcon(String category) {
    switch (category.toLowerCase()) {
      case 'communication':
        return Icons.chat_bubble_outline_rounded;
      case 'social interaction':
        return Icons.people_outline_rounded;
      case 'sensory sensitivities':
        return Icons.sensors_rounded;
      case 'repetitive and focused behaviors':
        return Icons.repeat_rounded;
      case 'emotional regulation':
        return Icons.favorite_outline_rounded;
      case 'engagement and learning':
        return Icons.school_outlined;
      case 'visual behavior analysis':
        return Icons.visibility_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }
}
