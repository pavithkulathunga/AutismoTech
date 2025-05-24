import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';

class CalmForestScreen extends StatefulWidget {
  const CalmForestScreen({super.key});

  @override
  State<CalmForestScreen> createState() => _CalmForestScreenState();
}

class _CalmForestScreenState extends State<CalmForestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnimation;
  bool _isBreathingIn = true;
  int _breathCycle = 0;
  int _score = 0;
  Timer? _timer;
  bool _showCongrats = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isBreathingIn = false;
          _breathCycle++;
          if (_breathCycle % 2 == 0) _score++;
          if (_score >= 5) {
            _showCongrats = true;
            _controller.stop();
            _timer?.cancel();
          }
        });
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isBreathingIn = true;
        });
        _controller.forward();
      }
    });

    _breathAnimation = Tween<double>(
      begin: 80,
      end: 180,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_showCongrats) timer.cancel();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _breathCycle = 0;
      _showCongrats = false;
      _isBreathingIn = true;
    });
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe0f7fa),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388e3c),
        title: const Text("Calm Forest"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Forest background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFa8e063), Color(0xFF56ab2f)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Trees illustration (simple)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/forest_trees.png',
                fit: BoxFit.cover,
                height: 220,
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Breathe with the glowing orb",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2e7d32),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _breathAnimation,
                  builder: (context, child) {
                    return Container(
                      width: _breathAnimation.value,
                      height: _breathAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isBreathingIn
                                ? Colors.greenAccent.withOpacity(0.7)
                                : Colors.blueAccent.withOpacity(0.7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isBreathingIn ? "Inhale" : "Exhale",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  "Score: $_score",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF388e3c),
                  ),
                ),
                const SizedBox(height: 10),
                if (_showCongrats)
                  Column(
                    children: [
                      const Text(
                        "🎉 Great job! You completed 5 calm breaths!",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF2e7d32),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _restartGame,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Restart"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _startSoundMatchingGame,
                            icon: const Icon(Icons.music_note),
                            label: const Text("Sound Game"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.brown[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Sound matching game overlay
          if (_showSoundGame) _buildSoundMatchingGame(),
        ],
      ),
    );
  }

  // New variables for sound matching game
  bool _showSoundGame = false;
  List<ForestAnimal> _animals = [];
  ForestAnimal? _currentSound;
  int _soundGameScore = 0;
  int _soundGameRound = 1;
  bool _showSoundFeedback = false;
  bool _isCorrectMatch = false;

  void _startSoundMatchingGame() {
    // Initialize forest animals
    _animals = [
      ForestAnimal(
        id: 'owl',
        name: 'Owl',
        emoji: '🦉',
        imagePath: 'assets/images/owl.png',
        soundPath: 'assets/sounds/owl.mp3',
      ),
      ForestAnimal(
        id: 'fox',
        name: 'Fox',
        emoji: '🦊',
        imagePath: 'assets/images/fox.png',
        soundPath: 'assets/sounds/fox.mp3',
      ),
      ForestAnimal(
        id: 'deer',
        name: 'Deer',
        emoji: '🦌',
        imagePath: 'assets/images/deer.png',
        soundPath: 'assets/sounds/deer.mp3',
      ),
      ForestAnimal(
        id: 'frog',
        name: 'Frog',
        emoji: '🐸',
        imagePath: 'assets/images/frog.png',
        soundPath: 'assets/sounds/frog.mp3',
      ),
      ForestAnimal(
        id: 'bird',
        name: 'Bird',
        emoji: '🐦',
        imagePath: 'assets/images/bird.png',
        soundPath: 'assets/sounds/bird.mp3',
      ),
    ];

    setState(() {
      _showSoundGame = true;
      _soundGameScore = 0;
      _soundGameRound = 1;
      _showSoundFeedback = false;
    });

    _playRandomSound();
  }

  void _playRandomSound() {
    final random = Random();
    final selectedAnimal = _animals[random.nextInt(_animals.length)];

    setState(() {
      _currentSound = selectedAnimal;
      _showSoundFeedback = false;
    });

    // In a real implementation, you would play the actual sound:
    // AudioPlayer().play(AssetSource(_currentSound!.soundPath));

    print('Playing sound: ${_currentSound!.name}');
  }

  void _checkSoundMatch(ForestAnimal selectedAnimal) {
    if (_showSoundFeedback)
      return; // Prevent multiple selections while showing feedback

    final isCorrect = selectedAnimal.id == _currentSound?.id;

    setState(() {
      _showSoundFeedback = true;
      _isCorrectMatch = isCorrect;

      if (isCorrect) {
        _soundGameScore += 10;
        _soundGameRound++;
      }
    });

    // Schedule next round or end game
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_soundGameRound > 10 || !isCorrect) {
        setState(() {
          _showSoundGame = false;
        });
      } else {
        _playRandomSound();
      }
    });
  }

  Widget _buildSoundMatchingGame() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Forest Sounds",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showSoundGame = false;
                      });
                    },
                  ),
                ],
              ),
              const Divider(),

              // Game info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        "Round: $_soundGameRound/10",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        "Score: $_soundGameScore",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sound player
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Listen to the sound:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2e7d32),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () {
                        // Play the sound again
                        // AudioPlayer().play(AssetSource(_currentSound!.soundPath));
                        print('Replaying sound: ${_currentSound!.name}');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tap to play again",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Feedback area (shows when user makes a selection)
              if (_showSoundFeedback)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        _isCorrectMatch ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrectMatch ? Icons.check_circle : Icons.cancel,
                        color: _isCorrectMatch ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isCorrectMatch
                            ? "Great job! That's right!"
                            : "Not quite. That was a ${_currentSound?.name}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              _isCorrectMatch
                                  ? Colors.green[800]
                                  : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Animals to choose from
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _animals.length,
                  itemBuilder: (context, index) {
                    final animal = _animals[index];
                    return GestureDetector(
                      onTap: () => _checkSoundMatch(animal),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              animal.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              animal.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model class for forest animals
class ForestAnimal {
  final String id;
  final String name;
  final String emoji;
  final String imagePath;
  final String soundPath;

  ForestAnimal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.imagePath,
    required this.soundPath,
  });
}
