import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'dart:ui';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _sparkleController;
  late AnimationController _bounceController;
  late AnimationController _glowController;

  // Animations
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;

  List<Map<String, dynamic>> playlist = [
    {
      'song': 'Rainbow Journey',
      'artist': 'AutismoTech',
      'image': 'assets/music/track1.jpeg',
      'file': 'assets/music/m1.mp3',
      'color': const Color(0xFFFF6B9D),
      'mood': 'Happy',
      'emoji': '🌈',
      'duration': '3:45',
    },
    {
      'song': 'Gentle Breeze',
      'artist': 'AutismoTech',
      'image': 'assets/music/track2.jpg',
      'file': 'assets/music/m2.mp3',
      'color': const Color(0xFF4ECDC4),
      'mood': 'Calm',
      'emoji': '🍃',
      'duration': '4:12',
    },
    {
      'song': 'Ocean Whispers',
      'artist': 'AutismoTech',
      'image': 'assets/music/track3.jpg',
      'file': 'assets/music/m3.mp3',
      'color': const Color(0xFF45B7D1),
      'mood': 'Peaceful',
      'emoji': '🌊',
      'duration': '5:20',
    },
    {
      'song': 'Starlight Dreams',
      'artist': 'AutismoTech',
      'image': 'assets/music/track4.jpg',
      'file': 'assets/music/m4.mp3',
      'color': const Color(0xFF9B59B6),
      'mood': 'Dreamy',
      'emoji': '⭐',
      'duration': '4:35',
    },
    {
      'song': 'Peaceful Meadow',
      'artist': 'AutismoTech',
      'image': 'assets/music/track5.jpg',
      'file': 'assets/music/m5.mp3',
      'color': const Color(0xFF2ECC71),
      'mood': 'Serene',
      'emoji': '🌸',
      'duration': '3:58',
    },
    {
      'song': 'Magic Clouds',
      'artist': 'AutismoTech',
      'image': 'assets/music/track6.jpg',
      'file': 'assets/music/m6.mp3',
      'color': const Color(0xFFF39C12),
      'mood': 'Magical',
      'emoji': '☁️',
      'duration': '4:22',
    },
    {
      'song': 'Sunny Smiles',
      'artist': 'AutismoTech',
      'image': 'assets/music/track7.jpg',
      'file': 'assets/music/m7.mp3',
      'color': const Color(0xFFFFE066),
      'mood': 'Joyful',
      'emoji': '☀️',
      'duration': '3:30',
    },
    {
      'song': 'Moonlight Hugs',
      'artist': 'AutismoTech',
      'image': 'assets/music/track8.jpg',
      'file': 'assets/music/m8.mp3',
      'color': const Color(0xFF6C5CE7),
      'mood': 'Cozy',
      'emoji': '🌙',
      'duration': '4:48',
    },
    {
      'song': 'Happy Heartbeats',
      'artist': 'AutismoTech',
      'image': 'assets/music/track9.jpg',
      'file': 'assets/music/m9.mp3',
      'color': const Color(0xFFE84393),
      'mood': 'Energetic',
      'emoji': '💖',
      'duration': '3:15',
    },
    {
      'song': 'Calm Forest',
      'artist': 'AutismoTech',
      'image': 'assets/music/track10.jpg',
      'file': 'assets/music/m10.mp3',
      'color': const Color(0xFF00B894),
      'mood': 'Natural',
      'emoji': '🌳',
      'duration': '5:10',
    },
    {
      'song': 'Bubble Parade',
      'artist': 'AutismoTech',
      'image': 'assets/music/track11.jpeg',
      'file': 'assets/music/m11.mp3',
      'color': const Color(0xFF74B9FF),
      'mood': 'Playful',
      'emoji': '🫧',
      'duration': '3:42',
    },
    {
      'song': 'Cozy Cuddles',
      'artist': 'AutismoTech',
      'image': 'assets/music/track12.jpg',
      'file': 'assets/music/m12.mp3',
      'color': const Color(0xFFFFB8B8),
      'mood': 'Warm',
      'emoji': '🤗',
      'duration': '4:05',
    },
  ];

  int? currentlyPlayingIndex; // Track index of currently playing song
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize animations
    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFF9C27B0),
      end: const Color(0xFF673AB7),
    ).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start animations
    _backgroundController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _rotationController.repeat();
    _fadeController.forward();
    _slideController.forward();
    _sparkleController.repeat(reverse: true);
    _glowController.repeat(reverse: true);

    // Audio player listeners
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentlyPlayingIndex = null;
      });
    });
  }

  Future<void> _playLocalTrack(String filePath, int index) async {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    final fileName = filePath.split('/').last;
    if (currentlyPlayingIndex == index && isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('music/$fileName'));
      setState(() {
        currentlyPlayingIndex = index;
        isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _sparkleController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            "🎵 Music Therapy 🎵",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.pink),
              onPressed: () {
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                  _backgroundColorAnimation.value ?? const Color(0xFF9C27B0),
                  const Color(0xFFf093fb),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Floating title section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder: (context, child) {
                              return AnimatedBuilder(
                                animation: _sparkleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale:
                                        1.0 + (_sparkleAnimation.value * 0.2),
                                    child: Transform.rotate(
                                      angle: _rotationAnimation.value,
                                      child: Text(
                                        "🎪",
                                        style: TextStyle(
                                          fontSize: 40,
                                          shadows: [
                                            Shadow(
                                              color: Colors.white.withOpacity(
                                                _sparkleAnimation.value,
                                              ),
                                              blurRadius:
                                                  10 * _sparkleAnimation.value,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Magical Music Journey",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Touch a song to start your adventure! 🌟",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Playlist
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: playlist.length,
                        itemBuilder: (context, index) {
                          final track = playlist[index];
                          final isCurrentlyPlaying =
                              currentlyPlayingIndex == index;

                          return AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    isCurrentlyPlaying && isPlaying
                                        ? _pulseAnimation.value
                                        : 1.0,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        track['color'].withOpacity(0.3),
                                        track['color'].withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color:
                                          isCurrentlyPlaying
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.white.withOpacity(0.3),
                                      width: isCurrentlyPlaying ? 3 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: track['color'].withOpacity(0.4),
                                        blurRadius:
                                            isCurrentlyPlaying ? 25 : 15,
                                        offset: const Offset(0, 10),
                                        spreadRadius:
                                            isCurrentlyPlaying ? 2 : 0,
                                      ),
                                      if (isCurrentlyPlaying)
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 30,
                                          offset: const Offset(0, 0),
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            children: [
                                              // Enhanced album art with multiple effects
                                              Stack(
                                                children: [
                                                  // Glow background
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: track['color']
                                                              .withOpacity(0.6),
                                                          blurRadius: 20,
                                                          offset: const Offset(
                                                            0,
                                                            0,
                                                          ),
                                                          spreadRadius: 5,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Actual image
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white
                                                            .withOpacity(0.3),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                      child: Image.asset(
                                                        track['image'],
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  // Rotating overlay for playing track
                                                  if (isCurrentlyPlaying &&
                                                      isPlaying)
                                                    AnimatedBuilder(
                                                      animation:
                                                          _rotationAnimation,
                                                      builder: (
                                                        context,
                                                        child,
                                                      ) {
                                                        return Transform.rotate(
                                                          angle:
                                                              _rotationAnimation
                                                                  .value,
                                                          child: Container(
                                                            width: 80,
                                                            height: 80,
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              border: Border.all(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.5,
                                                                    ),
                                                                width: 3,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                ],
                                              ),

                                              const SizedBox(width: 20),

                                              // Enhanced song details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Song title with emoji
                                                    Row(
                                                      children: [
                                                        AnimatedBuilder(
                                                          animation:
                                                              _bounceAnimation,
                                                          builder: (
                                                            context,
                                                            child,
                                                          ) {
                                                            return Transform.scale(
                                                              scale:
                                                                  isCurrentlyPlaying
                                                                      ? _bounceAnimation
                                                                          .value
                                                                      : 1.0,
                                                              child: Text(
                                                                track['emoji'],
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          24,
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            track['song'],
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                              shadows: [
                                                                Shadow(
                                                                  color: track['color']
                                                                      .withOpacity(
                                                                        0.5,
                                                                      ),
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        2,
                                                                      ),
                                                                  blurRadius: 4,
                                                                ),
                                                              ],
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),

                                                    // Enhanced mood chip
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            track['color']
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                            track['color']
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: track['color']
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  3,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        track['mood'],
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),

                                                    // Enhanced progress or duration
                                                    if (isCurrentlyPlaying) ...[
                                                      // Animated progress bar
                                                      Container(
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                3,
                                                              ),
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                3,
                                                              ),
                                                          child: LinearProgressIndicator(
                                                            value:
                                                                totalDuration
                                                                            .inMilliseconds >
                                                                        0
                                                                    ? currentPosition
                                                                            .inMilliseconds /
                                                                        totalDuration
                                                                            .inMilliseconds
                                                                    : 0.0,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  track['color'],
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            _formatDuration(
                                                              currentPosition,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          Text(
                                                            _formatDuration(
                                                              totalDuration,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ] else ...[
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.access_time,
                                                            size: 16,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            track['duration'],
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),

                                              // Enhanced control buttons
                                              Column(
                                                children: [
                                                  // Main play/pause button with enhanced effects
                                                  GestureDetector(
                                                    onTap:
                                                        () => _playLocalTrack(
                                                          track['file'],
                                                          index,
                                                        ),
                                                    child: AnimatedBuilder(
                                                      animation: _glowAnimation,
                                                      builder: (
                                                        context,
                                                        child,
                                                      ) {
                                                        return AnimatedBuilder(
                                                          animation:
                                                              _bounceAnimation,
                                                          builder: (
                                                            context,
                                                            child,
                                                          ) {
                                                            return Transform.scale(
                                                              scale:
                                                                  isCurrentlyPlaying &&
                                                                          isPlaying
                                                                      ? _bounceAnimation
                                                                          .value
                                                                      : 1.0,
                                                              child: Container(
                                                                width: 70,
                                                                height: 70,
                                                                decoration: BoxDecoration(
                                                                  gradient: RadialGradient(
                                                                    colors: [
                                                                      track['color'],
                                                                      track['color']
                                                                          .withOpacity(
                                                                            0.8,
                                                                          ),
                                                                    ],
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        35,
                                                                      ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: track['color'].withOpacity(
                                                                        _glowAnimation.value *
                                                                            0.8,
                                                                      ),
                                                                      blurRadius:
                                                                          20,
                                                                      offset:
                                                                          const Offset(
                                                                            0,
                                                                            0,
                                                                          ),
                                                                      spreadRadius:
                                                                          _glowAnimation
                                                                              .value *
                                                                          3,
                                                                    ),
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.3,
                                                                          ),
                                                                      blurRadius:
                                                                          15,
                                                                      offset:
                                                                          const Offset(
                                                                            0,
                                                                            5,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Icon(
                                                                  isCurrentlyPlaying &&
                                                                          isPlaying
                                                                      ? Icons
                                                                          .pause_rounded
                                                                      : Icons
                                                                          .play_arrow_rounded,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  size: 35,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),

                                                  const SizedBox(height: 16),

                                                  // Enhanced skip controls
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      GestureDetector(
                                                        onTap:
                                                            index > 0
                                                                ? () => _playLocalTrack(
                                                                  playlist[index -
                                                                      1]['file'],
                                                                  index - 1,
                                                                )
                                                                : null,
                                                        child: Container(
                                                          width: 42,
                                                          height: 42,
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                index > 0
                                                                    ? LinearGradient(
                                                                      colors: [
                                                                        Colors
                                                                            .white
                                                                            .withOpacity(
                                                                              0.3,
                                                                            ),
                                                                        Colors
                                                                            .white
                                                                            .withOpacity(
                                                                              0.1,
                                                                            ),
                                                                      ],
                                                                    )
                                                                    : null,
                                                            color:
                                                                index > 0
                                                                    ? null
                                                                    : Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  21,
                                                                ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .skip_previous_rounded,
                                                            color:
                                                                index > 0
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                            size: 24,
                                                          ),
                                                        ),
                                                      ),

                                                      const SizedBox(width: 12),

                                                      GestureDetector(
                                                        onTap:
                                                            index <
                                                                    playlist.length -
                                                                        1
                                                                ? () => _playLocalTrack(
                                                                  playlist[index +
                                                                      1]['file'],
                                                                  index + 1,
                                                                )
                                                                : null,
                                                        child: Container(
                                                          width: 42,
                                                          height: 42,
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                index <
                                                                        playlist.length -
                                                                            1
                                                                    ? LinearGradient(
                                                                      colors: [
                                                                        Colors
                                                                            .white
                                                                            .withOpacity(
                                                                              0.3,
                                                                            ),
                                                                        Colors
                                                                            .white
                                                                            .withOpacity(
                                                                              0.1,
                                                                            ),
                                                                      ],
                                                                    )
                                                                    : null,
                                                            color:
                                                                index <
                                                                        playlist.length -
                                                                            1
                                                                    ? null
                                                                    : Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  21,
                                                                ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .skip_next_rounded,
                                                            color:
                                                                index <
                                                                        playlist.length -
                                                                            1
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                            size: 24,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom floating music visualizer
                  if (currentlyPlayingIndex != null && isPlaying)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return AnimatedBuilder(
                              animation: _waveAnimation,
                              builder: (context, child) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  height:
                                      20 +
                                      (math.sin(
                                            _waveAnimation.value * 2 * math.pi +
                                                index,
                                          ) *
                                          15),
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color:
                                        playlist[currentlyPlayingIndex!]['color'],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
