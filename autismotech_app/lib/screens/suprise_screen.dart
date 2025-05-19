import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:ui';

class SurpriseScreen extends StatefulWidget {
  const SurpriseScreen({super.key});

  @override
  State<SurpriseScreen> createState() => _SurpriseScreenState();
}

class _SurpriseScreenState extends State<SurpriseScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _characterController;
  late AnimationController _glowController;
  bool _treasureFound = false;
  int _starsCollected = 0;
  final List<Map<String, dynamic>> _stars = [];

  @override
  void initState() {
    super.initState();

    // Background animation - gentle color transitions
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Character bounce animation - subtle and soothing
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Glow animation for treasure - gentle pulsing
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Generate stars for the cave - interactive elements
    _generateStars();
  }

  void _generateStars() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      // Reduced number of stars to avoid overwhelming
      _stars.add({
        'top': 80.0 + random.nextDouble() * 400,
        'left': 40.0 + random.nextDouble() * 300,
        'size':
            15.0 + random.nextDouble() * 15, // Larger size for better targets
        'animationOffset': random.nextDouble(),
        'collected': false,
      });
    }
  }

  void _discoverTreasure() {
    HapticFeedback.mediumImpact(); // Tactile feedback
    setState(() {
      _treasureFound = true;
    });

    // Play celebration animation and transition
    Timer(const Duration(milliseconds: 1500), () {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  const MagicalTreasureScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  void _collectStar(int index) {
    if (!_stars[index]['collected']) {
      HapticFeedback.lightImpact(); // Tactile feedback for collection
      setState(() {
        _stars[index]['collected'] = true;
        _starsCollected++;

        // Auto-discover treasure if all stars collected
        if (_starsCollected == _stars.length) {
          _discoverTreasure();
        }
      });
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _characterController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Magic Cave',
          style: TextStyle(
            fontFamily: 'Comic Sans MS',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Animated background with gentle gradient transitions
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              final double value = _backgroundController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HSVColor.fromAHSV(
                        1.0,
                        270 +
                            (5 *
                                math.sin(
                                  value * 2 * math.pi,
                                )), // Gentle hue shift
                        0.6, // Reduced saturation for softer colors
                        0.7,
                      ).toColor(),
                      HSVColor.fromAHSV(
                        1.0,
                        260 + (5 * math.sin(value * 2 * math.pi)),
                        0.7,
                        0.5,
                      ).toColor(),
                      HSVColor.fromAHSV(
                        1.0,
                        250 + (5 * math.sin(value * 2 * math.pi)),
                        0.8,
                        0.4,
                      ).toColor(),
                    ],
                  ),
                ),
              );
            },
          ),

          // Interactive stars with gentle animations
          ..._stars.asMap().entries.map((entry) {
            final index = entry.key;
            final star = entry.value;
            return Positioned(
              top: star['top'],
              left: star['left'],
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  final starValue =
                      (_backgroundController.value + star['animationOffset']) %
                      1;
                  final size =
                      star['size'] *
                      (0.85 + 0.3 * math.sin(starValue * 2 * math.pi));

                  return star['collected']
                      ? const SizedBox() // Hide collected stars
                      : GestureDetector(
                        onTap: () => _collectStar(index),
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                      );
                },
              ),
            );
          }).toList(),

          // Cave decoration - softer and more rounded
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/cave_rocks.png',
              fit: BoxFit.fitWidth,
              opacity: const AlwaysStoppedAnimation(0.8),
            ),
          ),

          // Child character with gentle bouncing animation
          Positioned(
            bottom: 140,
            left: MediaQuery.of(context).size.width / 3,
            child: AnimatedBuilder(
              animation: _characterController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    4 *
                        math.sin(
                          _characterController.value * math.pi,
                        ), // Gentle bounce
                  ),
                  child: Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      image: DecorationImage(
                        image: AssetImage('assets/images/child_explorer.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Treasure chest with soft glow animation
          Positioned(
            bottom: 100,
            right: 40,
            child: GestureDetector(
              onTap: !_treasureFound ? _discoverTreasure : null,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glow =
                      2 +
                      2 *
                          math.sin(
                            _glowController.value * math.pi,
                          ); // Softer glow

                  return Container(
                    width: 90,
                    height: 80,
                    decoration: BoxDecoration(
                      color:
                          _treasureFound
                              ? Colors.transparent
                              : Colors.brown[700],
                      borderRadius: BorderRadius.circular(
                        15,
                      ), // More rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(
                            _treasureFound ? 0 : 0.4,
                          ),
                          blurRadius: _treasureFound ? 0 : glow * 5,
                          spreadRadius: _treasureFound ? 0 : glow,
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(
                          _treasureFound
                              ? 'assets/images/open_chest.png'
                              : 'assets/images/closed_chest.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child:
                        _treasureFound
                            ? Center(
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.amber,
                                size: 30,
                              ),
                            )
                            : null,
                  );
                },
              ),
            ),
          ),

          // Stars collected counter - clear and accessible
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25), // Very rounded
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '$_starsCollected / ${_stars.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Clear instructions with visual cues
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Tap the stars and find the treasure!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comic Sans MS',
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
  }
}

// Second screen with a more engaging and soothing design
class MagicalTreasureScreen extends StatefulWidget {
  const MagicalTreasureScreen({super.key});

  @override
  State<MagicalTreasureScreen> createState() => _MagicalTreasureScreenState();
}

class _MagicalTreasureScreenState extends State<MagicalTreasureScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    // Gentle floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Slower for more soothing effect
    )..repeat(reverse: true);

    // Soft glowing effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // Slower for more soothing effect
    )..repeat(reverse: true);

    // Background star field animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slower movement
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep but not harsh background
      body: Stack(
        children: [
          // Gentle starfield background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarfieldPainter(_particleController.value),
                size: MediaQuery.of(context).size,
              );
            },
          ),

          // Main content with clear visual hierarchy
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with friendly typography
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      '✨ You Found Magic! ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Comic Sans MS',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Floating treasure with soft animations
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          8 *
                              math.sin(
                                _floatController.value * math.pi,
                              ), // Gentle float
                        ),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber.withOpacity(0.15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius:
                                        20 +
                                        (15 *
                                            math.sin(
                                              _glowController.value * math.pi,
                                            )),
                                    spreadRadius:
                                        5 +
                                        (5 *
                                            math.sin(
                                              _glowController.value * math.pi,
                                            )),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/magic_crystal.png',
                                  width: 130,
                                  height: 130,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Description with clear, readable text
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'This magical crystal helps calm your mind and brings happy feelings!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        height: 1.4,
                        fontFamily: 'Comic Sans MS',
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Large, accessible button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Add haptic feedback for better interaction
                      HapticFeedback.mediumImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Continue Adventure',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Comic Sans MS',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for gentle starfield effect
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Map<String, dynamic>> stars = List.generate(80, (index) {
    final random = math.Random();
    return {
      'x': random.nextDouble(),
      'y': random.nextDouble(),
      'size': random.nextDouble() * 2.5, // Smaller stars
      'speed': 0.1 + random.nextDouble() * 0.3, // Slower movement
    };
  });

  StarfieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (final star in stars) {
      final x = (star['x'] + animationValue * star['speed']) % 1.0 * size.width;
      final y = star['y'] * size.height;

      // Draw softer stars
      final starPaint =
          Paint()
            ..color = Colors.white.withOpacity(
              0.6 +
                  0.4 * math.sin(animationValue * 2 * math.pi + star['x'] * 10),
            )
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

      canvas.drawCircle(Offset(x, y), star['size'], starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
