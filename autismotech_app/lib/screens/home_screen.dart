import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/rendering.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late AnimationController _backgroundController;
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  late AnimationController _floatingController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<Offset> _floatingAnimation;
  
  // Additional animation properties
  final List<Color> _gradientColors = [
    AppColors.background,
    Color(0xFF5527AA),
    Color(0xFF4A23A0),
    Color(0xFF3F51B5),
  ];
  int _currentGradientIndex = 0;
  
  // UI state
  bool _isLoaded = false;
  int _selectedTileIndex = -1;
  bool _showSplashEffect = false;
  List<Color> _splashColors = [
    AppColors.accent1,
    AppColors.accent2,
    AppColors.accent3,
  ];
  
  // For particle effects
  final List<ParticleModel> _particles = [];
  final List<BubbleParticle> _bubbles = [];
  Timer? _particleTimer;
  Timer? _gradientTransitionTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    // Initialize particles after the first frame is rendered when we have a context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateParticles();
      _generateBubbles();
      
      // Start particle animation
      _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (mounted) {
          setState(() {
            // This will trigger particles to be redrawn with updated positions
          });
        }
      });
      
      // Start gradient transitions
      _startGradientTransition();
    });
    
    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
      .animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05)
      .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.95)
      .animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi)
      .animate(CurvedAnimation(parent: _rotationController, curve: Curves.linear));
    
    _backgroundColorAnimation = ColorTween(
      begin: _gradientColors[0],
      end: _gradientColors[1],
    ).animate(_backgroundController);
    
    _waveAnimation = Tween<double>(begin: -5.0, end: 5.0)
      .animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0)
      .animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    
    _floatingAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -10),
    ).animate(CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut));
    
    // Start the entrance animations with slight delays for a staggered effect
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
      setState(() {
        _isLoaded = true;
      });
    });
    
    // Trigger splash effect after initial load
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _showSplashEffect = true;
      });
      
      // Hide splash after a moment
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSplashEffect = false;
          });
        }
      });
    });
  }
  
  void _startGradientTransition() {
    _gradientTransitionTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted) {
        setState(() {
          _currentGradientIndex = (_currentGradientIndex + 1) % _gradientColors.length;
          _backgroundController.reset();
          _backgroundController.forward();
        });
      }
    });
  }
  
  void _generateParticles() {
    final random = math.Random();
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 40; i++) {
      _particles.add(
        ParticleModel(
          x: random.nextDouble() * size.width,
          y: random.nextDouble() * size.height,
          size: 1 + random.nextDouble() * 3,
          speed: 0.5 + random.nextDouble() * 1.5,
          opacity: 0.1 + random.nextDouble() * 0.4,
          color: _splashColors[random.nextInt(_splashColors.length)].withOpacity(0.7),
        ),
      );
    }
  }
  
  void _generateBubbles() {
    final random = math.Random();
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 15; i++) {
      _bubbles.add(
        BubbleParticle(
          x: random.nextDouble() * size.width,
          y: random.nextDouble() * size.height + size.height * 0.5,
          size: 20 + random.nextDouble() * 60,
          speed: 0.5 + random.nextDouble() * 1.0,
          opacity: 0.05 + random.nextDouble() * 0.15,
          color: Colors.white,
        ),
      );
    }
  }
  
  void _playTileAnimation(int index) {
    setState(() {
      _selectedTileIndex = index;
    });
    
    // Play haptic feedback for interactivity
    HapticFeedback.selectionClick();
    
    // Play bounce animation
    _bounceController.forward().then((_) => _bounceController.reverse());
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _rotationController.dispose();
    _backgroundController.dispose();
    _waveController.dispose();
    _shimmerController.dispose();
    _floatingController.dispose();
    _particleTimer?.cancel();
    _gradientTransitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsiveness
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 600;
    final double tileSize = isLargeScreen ? 200.0 : 160.0;
    final double iconSize = isLargeScreen ? 60.0 : 50.0;
    final double tileFontSize = isLargeScreen ? 20.0 : 16.0;
    final double spacing = isLargeScreen ? 25.0 : 15.0;
    
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColorAnimation.value,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.05),
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 28,
                    ),
                    splashRadius: 24,
                    onPressed: () {
                      // Show a cool animated menu
                      _showAnimatedMenu(context);
                    },
                  ),
                );
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.05),
                      child: const Text(
                        'Autismo-Tech',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black38,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: const Icon(
                        Icons.psychology,
                        color: AppColors.accent2,
                        size: 24,
                      ),
                    );
                  },
                ),
              ],
            ),            actions: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                splashRadius: 24,
                onPressed: () {
                  // Add notification functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("No new notifications"),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.accent1,
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: Container(
                height: 2.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Background particle effect
              CustomPaint(
                size: Size.infinite,
                painter: ParticlePainter(particles: _particles, bubbles: _bubbles),
              ),
              
              // Positioned footer image with rotation animation
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (Rect bounds) {                        return LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.5 + _pulseController.value * 0.1),
                            Colors.white.withOpacity(0.3 + _pulseController.value * 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Image.asset(
                        'assets/images/home_footer.png',
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              
              // Animated help button
              Positioned(
                bottom: 20,
                right: 20,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: FloatingActionButton(
                        onPressed: () => _showHelpDialog(context),
                        backgroundColor: AppColors.accent1,
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                        elevation: 8 + (_pulseController.value * 4),
                      ),
                    );
                  },
                ),
              ),
              
              // Main scrollable content with fade and scale animations
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.25,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Greeting section with time-based content
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _getGreetingGradient(),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _buildGreetingWidget(),
                        ),
                        
                        SizedBox(height: spacing * 1.5),
                        
                        // Feature tiles grid with responsiveness
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: spacing),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Use grid layout for better responsiveness
                              return GridView.count(
                                crossAxisCount: isLargeScreen ? 3 : 2,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildAnimatedTile(
                                    context,
                                    index: 0,
                                    icon: Icons.health_and_safety,
                                    label: 'ASD Diagnosis',
                                    color: AppColors.diagnosis,
                                    routeName: '/diagnosis',
                                    size: tileSize,
                                    iconSize: iconSize,
                                    fontSize: tileFontSize,
                                  ),
                                  _buildAnimatedTile(
                                    context,
                                    index: 1,
                                    icon: Icons.lightbulb,
                                    label: 'Attention Enhancing',
                                    color: AppColors.Attention,
                                    routeName: '/emotion',
                                    size: tileSize,
                                    iconSize: iconSize,
                                    fontSize: tileFontSize,
                                  ),
                                  _buildAnimatedTile(
                                    context,
                                    index: 2,
                                    icon: Icons.face,
                                    label: 'Emotion Detection',
                                    color: AppColors.Emotion,
                                    routeName: '/emotion',
                                    size: tileSize,
                                    iconSize: iconSize,
                                    fontSize: tileFontSize,
                                  ),
                                  _buildAnimatedTile(
                                    context,
                                    index: 3,
                                    icon: Icons.trending_up,
                                    label: 'Progress Prediction',
                                    color: const Color(0xFF5C6BC0), // Indigo color
                                    routeName: '/login',
                                    size: tileSize,
                                    iconSize: iconSize,
                                    fontSize: tileFontSize,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Splash effect overlay
              if (_showSplashEffect)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  color: Colors.black54,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showSplashEffect ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [              AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.1),
                                child: Image.asset(
                                  'assets/icons/app_icon.png',
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Welcome to Autismo-Tech',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Supporting neurodiversity with technology',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get different greeting gradients based on time of day
  List<Color> _getGreetingGradient() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      // Morning gradient - fresh and lively
      return [
        const Color(0xFFC8E6C9),
        const Color(0xFF81C784),
      ];
    } else if (hour < 17) {
      // Afternoon gradient - warm and bright
      return [
        const Color(0xFFFFE0B2),
        const Color(0xFFFFB74D),
      ];
    } else {
      // Evening gradient - calm and soothing
      return [
        const Color(0xFFBBDEFB),
        const Color(0xFF64B5F6),
      ];
    }
  }

  // Dynamic greeting widget based on time of day
  Widget _buildGreetingWidget() {
    final hour = DateTime.now().hour;
    String greeting;
    String subGreeting;
    Color textColor;
    String imagePath;
    IconData weatherIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning!';
      subGreeting = 'Let\'s start the day with positivity';
      textColor = const Color(0xFF3c6e1d);
      imagePath = 'assets/images/good_morning.png';
      weatherIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon!';
      subGreeting = 'Time for some engaging activities';
      textColor = Colors.deepOrange.shade700;
      imagePath = 'assets/images/good_afternoon.png';
      weatherIcon = Icons.wb_twilight;
    } else {
      greeting = 'Good Evening!';
      subGreeting = 'Relax and enjoy some calm activities';
      textColor = Colors.indigo.shade700;
      imagePath = 'assets/images/good_evening.png';
      weatherIcon = Icons.nights_stay;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 0.5,
                        child: Icon(
                          weatherIcon,
                          color: textColor,
                          size: 28,
                        ),
                      );
                    },
                  ),                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subGreeting,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),        ),
        SizedBox(
          width: 110, // Fixed width for the image
          child: Image.asset(
            imagePath,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
  // Build animated tile with hover effects and animations
  Widget _buildAnimatedTile(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required String routeName,
    required double size,
    required double iconSize,
    required double fontSize,
  }) {
    final bool isSelected = _selectedTileIndex == index;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _bounceController, _shimmerController]),
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected 
              ? _bounceAnimation.value 
              : 1.0 + (_pulseController.value * 0.03),
          child: GestureDetector(
            onTap: () {
              _playTileAnimation(index);
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pushNamed(context, routeName);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(isSelected ? 1.0 : 0.9),
                    color,
                    color.withOpacity(isSelected ? 0.8 : 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isSelected ? 0.6 : 0.4),
                    blurRadius: isSelected ? 15 : 10,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.transparent,
                  child: Stack(
                    children: [
                      // Shimmer effect overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isSelected ? 1.0 : 0.0,
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment(
                                    -1.0 + _shimmerController.value * 3,
                                    -1.0 + _shimmerController.value * 3,
                                  ),
                                  end: Alignment(
                                    0.0 + _shimmerController.value * 3, 
                                    0.0 + _shimmerController.value * 3,
                                  ),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ).createShader(rect);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon with glow effect
                            Container(
                              alignment: Alignment.center,
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return RadialGradient(
                                    center: const Alignment(0.1, 0.1),
                                    radius: 0.8,
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.8),
                                    ],
                                  ).createShader(bounds);
                                },
                                child: Icon(
                                  icon,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Label with subtle animation and proper centering
                            Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Show an animated slide-in menu with navigation options
  void _showAnimatedMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundAccent,
                  AppColors.background,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Handle indicator
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                // Menu header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Menu items with animations
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),                    children: [
                      _buildMenuTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpDialog(context);
                        },
                      ),
                      _buildMenuTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: () {
                          Navigator.pop(context);
                          _showAboutDialog(context);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper to build menu item tiles with animation
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),        ),
      ),
    );
  }

  // Show about dialog with animation
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0.8, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'About',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/app_icon.png',
                height: 80,
                width: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Autismo-Tech is an innovative app designed to assist and support children with autism and their caregivers. Our mission is to provide helpful tools for diagnosis, education, and emotional development.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Version 1.0.0',
                style: TextStyle(color: AppColors.accent2),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('CLOSE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show help dialog with useful information
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0.8, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Help & Support',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  icon: Icons.health_and_safety,
                  title: 'ASD Diagnosis',
                  description: 'Answer questions and upload a photo for preliminary autism screening.',
                ),
                _buildHelpItem(
                  icon: Icons.face,
                  title: 'Emotion Detection',
                  description: 'Help your child recognize and understand different emotions.',
                ),
                _buildHelpItem(
                  icon: Icons.trending_up,
                  title: 'Progress Prediction',
                  description: 'Predict and track autism development progress for infants over time.',
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper for building individual help items
  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent2.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent2, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Particle models and painters
class ParticleModel {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  Color color;
  
  ParticleModel({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
  
  // Update particle position for animation
  void update(Size screenSize) {
    y -= speed;
    if (y < 0) {
      y = screenSize.height;
      x = math.Random().nextDouble() * screenSize.width;
    }
  }
}

// Bubble particle model for the animated background
class BubbleParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  Color color;
  double wobble; // For gentle wobbling motion
  double wobbleSpeed;
  double wobbleDirection;
  double originalX; // To keep track of original position for wobbling around
  
  BubbleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  }) : 
    wobble = 0,
    originalX = x,
    wobbleSpeed = 0.01 + (math.Random().nextDouble() * 0.01), 
    wobbleDirection = math.Random().nextBool() ? 1 : -1;
  
  // Update bubble position for animation
  void update(Size screenSize) {
    y -= speed * 0.5;
    
    // Create a gentle wobbling effect
    wobble += wobbleSpeed;
    x = originalX + (math.sin(wobble) * size / 4 * wobbleDirection);
    
    // Reset when off screen
    if (y < -size) {
      y = screenSize.height + size;
      x = math.Random().nextDouble() * screenSize.width;
      originalX = x;
      opacity = 0.05 + math.Random().nextDouble() * 0.15;
      size = 20 + math.Random().nextDouble() * 60;
      speed = 0.5 + math.Random().nextDouble() * 1.0;
      wobbleDirection = math.Random().nextBool() ? 1 : -1;
    }
  }
}

// Custom painter for rendering the particle effect background
class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final List<BubbleParticle> bubbles;
  
  ParticlePainter({
    required this.particles,
    required this.bubbles,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw bubbles first (behind the particles)
    for (var bubble in bubbles) {
      bubble.update(size);
      
      // Create gradient for bubble
      final gradient = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.0,
        colors: [
          bubble.color.withOpacity(bubble.opacity * 1.5),
          bubble.color.withOpacity(bubble.opacity * 0.5),
        ],
      );
      
      final rect = Rect.fromCircle(
        center: Offset(bubble.x, bubble.y),
        radius: bubble.size,
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
      canvas.drawCircle(
        Offset(bubble.x, bubble.y),
        bubble.size,
        paint,
      );
      
      // Add highlight to bubble for 3D effect
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(bubble.opacity * 0.8)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        
      canvas.drawCircle(
        Offset(bubble.x - bubble.size * 0.3, bubble.y - bubble.size * 0.3),
        bubble.size * 0.2,
        highlightPaint,
      );
    }
    
    // Update and draw particles (on top of bubbles)
    for (var particle in particles) {
      particle.update(size);
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
