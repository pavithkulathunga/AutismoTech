import 'package:autismotech_app/screens/ProgressSummaryScreen.dart';
import 'package:autismotech_app/screens/QuestionsScreen.dart';
import 'package:autismotech_app/screens/SummaryScreen.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BottomNavigationBarWidget extends StatefulWidget {
  final int? initialIndex;
  
  const BottomNavigationBarWidget({super.key, this.initialIndex});

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  bool _isInitialized = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _floatingController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatingAnimation;

  final List<String> _icons = [
    'assets/images/home.png',
    'assets/images/questions.png',
    'assets/images/summary.png',
  ];

  final List<String> _selectedIcons = [
    'assets/images/homeafterclick.png',
    'assets/images/questionsafterclick.png',
    'assets/images/summaryafterclick.png',
  ];

  final List<String> _labels = ['Home', 'Questions', 'Summary'];

  final List<IconData> _fallbackIcons = [
    Icons.home_rounded,
    Icons.quiz_rounded,
    Icons.analytics_rounded,
  ];

  final List<Widget> _screens = [
    const ProgressSummaryScreen(),
    const QuestionsScreen(),
    const SummaryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    _initializeAnimations();
    _isInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }

  @override
  void didUpdateWidget(BottomNavigationBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != null && widget.initialIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex!;
      });
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    _floatingAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
    _floatingController.repeat(reverse: true);
  }

  void _startAnimations() async {
    if (!mounted || !_isInitialized) return;
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _slideController.forward();
    if (mounted) _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex && _isInitialized) {
      setState(() {
        _selectedIndex = index;
      });

      // Add haptic feedback
      if (mounted) {
        _scaleController.reset();
        _scaleController.forward();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => _screens[index],
          settings: RouteSettings(
            name: _getRouteName(index),
            arguments: index,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  String _getRouteName(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/questions';
      case 2:
        return '/summary';
      default:
        return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 16,
            vertical: isTablet ? 20 : 12,
          ),
          decoration: _buildGlassContainer(isTablet),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 16 : 12,
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_icons.length, (index) {
                  return _buildNavItem(index, isTablet);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGlassContainer(bool isTablet) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background.withOpacity(0.9),
          AppColors.backgroundAccent.withOpacity(0.8),
          AppColors.primaryColor.withOpacity(0.7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(isTablet ? 32 : 28),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryColor.withOpacity(0.1),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, bool isTablet) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 16 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.8),
                    const Color(0xFF667EEA),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: isSelected ? _floatingAnimation : const AlwaysStoppedAnimation(0.0),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, isSelected ? _floatingAnimation.value : 0),
                  child: _buildIconContainer(index, isSelected, isTablet),
                );
              },
            ),
            SizedBox(height: isTablet ? 8 : 6),
            _buildLabel(index, isSelected, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(int index, bool isSelected, bool isTablet) {
    return Container(
      width: isTablet ? 48 : 40,
      height: isTablet ? 48 : 40,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.15),
                  AppColors.primaryColor.withOpacity(0.05),
                ],
              ),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
        border: Border.all(
          color: isSelected 
              ? Colors.white.withOpacity(0.3)
              : AppColors.primaryColor.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: AnimatedBuilder(
        animation: isSelected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _pulseAnimation.value : 1.0,
            child: _buildIcon(index, isSelected, isTablet),
          );
        },
      ),
    );
  }

  Widget _buildIcon(int index, bool isSelected, bool isTablet) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isTablet ? 8 : 6),
        child: Image.asset(
          isSelected ? _selectedIcons[index] : _icons[index],
          width: isTablet ? 24 : 20,
          height: isTablet ? 24 : 20,
          color: isSelected ? Colors.white : AppColors.primaryColor,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _fallbackIcons[index],
              color: isSelected ? Colors.white : AppColors.primaryColor,
              size: isTablet ? 24 : 20,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(int index, bool isSelected, bool isTablet) {
    if (isSelected) {
      return AnimatedBuilder(
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
              _labels[index],
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _labels[index],
        style: TextStyle(
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor.withOpacity(0.8),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
