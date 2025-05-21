import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'attention_screen.dart';
import 'package:autismotech_app/constants/colors.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> 
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _listItemController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  
  // Animations
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _bounceAnimation;
  
  // Animation variables
  final List<Color> _backgroundColors = [
    AppColors.background,
    AppColors.backgroundAccent,
    Color(0xFF7E57C2), // Light purple
    Color(0xFF9575CD), // Lighter purple
  ];
  
  int _hoveredIndex = -1;
  bool _isLoaded = false;
  late List<bool> _animatedItems;
  
  final List<Map<String, dynamic>> videoAssets = const [
    {'name': 'Fairy Tale', 'path': 'assets/videos/video1.mp4', 'color': 0xFFFF9800, 'icon': Icons.auto_stories},
    {'name': 'Peter Pan', 'path': 'assets/videos/video2.mp4', 'color': 0xFF4CAF50, 'icon': Icons.flight},
    {'name': 'The Lazy Girl', 'path': 'assets/videos/video3.mp4', 'color': 0xFF00BCD4, 'icon': Icons.hotel},
    {'name': 'The Tale of Rapunzel', 'path': 'assets/videos/video4.mp4', 'color': 0xFF9C27B0, 'icon': Icons.woman_2},
    {'name': 'The Lost Child', 'path': 'assets/videos/video5.mp4', 'color': 0xFF3F51B5, 'icon': Icons.explore},
    {'name': 'The Mermaid and the Prince', 'path': 'assets/videos/video6.mp4', 'color': 0xFF009688, 'icon': Icons.water},
    {'name': 'The Old Man', 'path': 'assets/videos/video7.mp4', 'color': 0xFFFF5722, 'icon': Icons.elderly},
    {'name': 'Mermaid and the Red Fish', 'path': 'assets/videos/video8.mp4', 'color': 0xFFE91E63, 'icon': Icons.water_drop},
  ];
  
  // Particles for background effect
  final List<BubbleParticle> _bubbles = [];
  Timer? _bubbleTimer;
  
  @override
  void initState() {
    super.initState();
    _animatedItems = List.generate(videoAssets.length, (_) => false);
    
    // Initialize animation controllers
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    
    _listItemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Initialize animations
    _backgroundColorAnimation = ColorTween(
      begin: _backgroundColors[0],
      end: _backgroundColors[1],
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
    
    _bounceAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -10),
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    
    // Start background bubble effect
    _generateBubbles();
    _bubbleTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _updateBubbles();
        });
      }
    });
    
    // Start staggered animation for list items
    _fadeController.forward();
    _animateListItems();
  }
  
  void _generateBubbles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _bubbles.add(
        BubbleParticle(
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          size: random.nextDouble() * 30 + 5,
          speed: random.nextDouble() * 1.5 + 0.5,
          color: _backgroundColors[random.nextInt(_backgroundColors.length)].withOpacity(0.3),
        ),
      );
    }
  }
  
  void _updateBubbles() {
    for (var bubble in _bubbles) {
      bubble.y -= bubble.speed;
      if (bubble.y < -50) {
        bubble.y = 800 + bubble.size;
        bubble.x = math.Random().nextDouble() * 400;
      }
    }
  }
  
  void _animateListItems() {
    Future.delayed(Duration(milliseconds: 200), () {
      if (!mounted) return;
      
      for (int i = 0; i < videoAssets.length; i++) {
        Future.delayed(Duration(milliseconds: 100 * i), () {
          if (!mounted) return;
          setState(() {
            _animatedItems[i] = true;
          });
        });
      }
    });
  }
  
  void _onTapVideo(Map<String, dynamic> video) {
    // Add haptic feedback for touch response
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          AttentionScreen(videoPath: video['path']),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeOutQuad;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    _listItemController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    _bubbleTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _backgroundColorAnimation.value ?? _backgroundColors[0],
                  _backgroundColors[2],
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background bubbles
                ...List.generate(_bubbles.length, (index) {
                  final bubble = _bubbles[index];
                  return Positioned(
                    left: bubble.x,
                    top: bubble.y,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      width: bubble.size,
                      height: bubble.size,
                      decoration: BoxDecoration(
                        color: bubble.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
                
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Animated app bar
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Row(
                          children: [
                            BackButton(color: Colors.white),
                            AnimatedBuilder(
                              animation: _bounceController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _bounceAnimation.value.dy * 0.3),
                                  child: Text(
                                    'Magic Video Stories',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Video grid
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: videoAssets.length,
                            itemBuilder: (context, index) {
                              final video = videoAssets[index];
                              
                              return AnimatedOpacity(
                                opacity: _animatedItems[index] ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                                child: AnimatedPadding(
                                  padding: _animatedItems[index] 
                                    ? EdgeInsets.zero 
                                    : EdgeInsets.only(top: 20),
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeOutQuad,
                                  child: VideoCard(
                                    title: video['name'],
                                    icon: video['icon'],
                                    color: Color(video['color']),
                                    onTap: () => _onTapVideo(video),
                                    bounceController: _bounceController,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final AnimationController bounceController;
  
  const VideoCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.bounceController,
  }) : super(key: key);
  
  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _scaleController.reverse();
      },
      onTapCancel: () {
        _scaleController.reverse();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, widget.bounceController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, math.sin(widget.bounceController.value * math.pi * 2) * 3),
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  right: -10,
                  bottom: -20,
                  child: Icon(
                    widget.icon,
                    size: 100,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      Spacer(),
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            color: Colors.white.withOpacity(0.8),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Watch Now',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BubbleParticle {
  double x;
  double y;
  double size;
  double speed;
  Color color;
  
  BubbleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}
