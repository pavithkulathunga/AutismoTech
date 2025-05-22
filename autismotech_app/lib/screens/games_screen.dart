import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autismotech_app/screens/suprise_screen.dart';
import 'dart:math' as math;
import 'dart:ui';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  bool _isLoaded = false;
  final List<GlobalKey> _cardKeys = List.generate(4, (_) => GlobalKey());
  
  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    // Add haptic feedback when screen loads
    HapticFeedback.mediumImpact();
    
    // Delayed animation for card appearance
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isLoaded = true;
      });
    });
  }
  
  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: _buildAnimatedTitle(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            _buildSettingsButton(),
          ],
        ),
        body: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),
            
            // Foreground particles
            _buildParticlesEffect(),
            
            // Frosted Glass Effect for Content Area
            _buildFrostedGlassContent(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: const Text(
              "Emotion World",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSettingsButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showSettingsModal(context);
          },
          tooltip: 'Settings',
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF6A3DE8), 
                Color(0xFF7C4DFF),
                Color(0xFF9D6FFF),
              ],
              stops: [
                0.0,
                0.5 + 0.1 * math.sin(_backgroundAnimationController.value * math.pi * 2),
                1.0,
              ],
              transform: GradientRotation(_backgroundAnimationController.value * 0.2 * math.pi),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildParticlesEffect() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(
            animation: _backgroundAnimationController,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildFrostedGlassContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Journey title with SVG animation
            const SizedBox(height: 20),
            _buildAnimatedSectionHeader(
              'Emotion Adventure Map',
              'Explore different emotional landscapes',
            ),
            const SizedBox(height: 24),
            
            // Game cards grid
            Expanded(
              child: _buildGameGrid(),
            ),
            
            // Bottom info card
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedSectionHeader(String title, String subtitle) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildPulsingIcon(Icons.map, Colors.amber),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulsingIcon(IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        );
      },
      onEnd: () {
        // Restart the animation in reverse
        setState(() {});
      },
    );
  }
  
  Widget _buildGameGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        // Staggered animation for each card
        return TweenAnimationBuilder<double>(
          key: _cardKeys[index],
          tween: Tween(begin: 0.0, end: _isLoaded ? 1.0 : 0.0),
          duration: Duration(milliseconds: 600 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                ),
              ),
            );
          },
          child: _buildGameCard(index, context),
        );
      },
    );
  }

  Widget _buildGameCard(int index, BuildContext context) {
    final gameData = [
      {
        'icon': Icons.emoji_emotions,
        'title': 'Happy Hills',
        'description': 'Match colors with joy',
        'color': Colors.yellow.shade700,
        'gradientColors': [Colors.yellow.shade700, Colors.amber.shade500],
        'path': '/happy',
        'stars': 4,
      },
      {
        'icon': Icons.whatshot,
        'title': 'Angry Volcano',
        'description': 'Calm the eruption inside',
        'color': Colors.redAccent,
        'gradientColors': [Colors.redAccent, Colors.red.shade800],
        'screenBuilder': (context) => const AngryVolcanoGameScreen(),
        'stars': 5,
      },
      {
        'icon': Icons.wb_incandescent,
        'title': 'Surprise Cave',
        'description': 'Discover the unexpected',
        'color': Colors.orangeAccent,
        'gradientColors': [Colors.orangeAccent, Colors.deepOrange.shade400],
        'screenBuilder': (context) => const SurpriseScreen(),
        'stars': 3,
      },
      {
        'icon': Icons.self_improvement,
        'title': 'Calm Forest',
        'description': 'Find your inner peace',
        'color': Colors.green,
        'gradientColors': [Colors.green, Colors.green.shade800],
        'path': '/calmforest',
        'stars': 4,
      },
    ];

    final game = gameData[index];
    
    return Hero(
      tag: 'game-card-${game['title']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _navigateToGame(context, game);
          },
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: game['gradientColors'] as List<Color>,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (game['color'] as Color).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with icon and stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildShimmeringIcon(game['icon'] as IconData),
                            _buildStarRating(game['stars'] as int),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Game title
                        Text(
                          game['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Game description
                        Text(
                          game['description'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Play button
                        _buildPlayButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildShimmeringIcon(IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.5),
              Colors.white,
            ],
            stops: [
              value - 0.3,
              value,
              value + 0.3,
            ],
            tileMode: TileMode.mirror,
          ).createShader(bounds),
          child: Icon(
            icon,
            size: 42,
            color: Colors.white,
          ),
        );
      },
      onEnd: () {
        // Restart the shimmer effect
        setState(() {});
      },
    );
  }
  
  Widget _buildStarRating(int stars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(stars, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 150)),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.star,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      }),
    );
  }
  
  Widget _buildPlayButton() {
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.deepPurple,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Play Now',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  void _navigateToGame(BuildContext context, Map<String, dynamic> game) {
    if (game.containsKey('path')) {
      Navigator.pushNamed(context, game['path'] as String);
    } else if (game.containsKey('screenBuilder')) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            (game['screenBuilder'] as Widget Function(BuildContext))(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
  
  Widget _buildInfoCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _isLoaded ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tips_and_updates,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Did you know?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Playing emotion games helps develop emotional intelligence!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
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

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Game Settings",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Settings options would go here
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Particle Effect
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Particle> particles = [];
  
  ParticlesPainter({required this.animation}) {
    if (particles.isEmpty) {
      // Generate random particles
      for (int i = 0; i < 30; i++) {
        particles.add(Particle.random());
      }
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position based on animation value
      final progress = (animation.value + particle.offset) % 1.0;
      final position = Offset(
        particle.originX * size.width,
        particle.originY * size.height + progress * size.height * 1.5,
      );
      
      // Calculate opacity - fade in and out
      double opacity;
      if (progress < 0.3) {
        opacity = progress / 0.3;
      } else if (progress > 0.7) {
        opacity = (1.0 - progress) / 0.3;
      } else {
        opacity = 1.0;
      }
      
      // Adjust size based on animation
      final currentSize = particle.size * (0.7 + 0.3 * math.sin(progress * math.pi));
      
      // Draw particle
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(position, currentSize, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Particle class for background effect
class Particle {
  final double originX;
  final double originY;
  final double size;
  final Color color;
  final double offset;
  
  Particle({
    required this.originX,
    required this.originY,
    required this.size,
    required this.color,
    required this.offset,
  });
  
  factory Particle.random() {
    final random = math.Random();
    
    // Create color variations for particles
    List<Color> colors = [
      Colors.white,
      Colors.blue.shade200,
      Colors.purple.shade200,
      Colors.pink.shade200,
    ];
    
    return Particle(
      originX: random.nextDouble(),
      originY: random.nextDouble() * 0.2 - 0.2, // Start above the screen
      size: 2 + random.nextDouble() * 4,
      color: colors[random.nextInt(colors.length)],
      offset: random.nextDouble(), // Random starting point in the animation
    );
  }
}

class GameSectionScreen extends StatelessWidget {
  const GameSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Happy Hills Game"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Game is starting...',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}

class AngryVolcanoGameScreen extends StatefulWidget {
  const AngryVolcanoGameScreen({super.key});

  @override
  State<AngryVolcanoGameScreen> createState() => _AngryVolcanoGameScreenState();
}

class _AngryVolcanoGameScreenState extends State<AngryVolcanoGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calm the Volcano"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent, Colors.orangeAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.3).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                ),
                child: const Icon(
                  Icons.whatshot,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Take a deep breath",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  "Follow the breathing animation. Tap the icon slowly while breathing in and out.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
