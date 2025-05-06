import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class HappyScreen extends StatefulWidget {
  const HappyScreen({super.key});

  @override
  State<HappyScreen> createState() => _HappyScreenState();
}

class _HappyScreenState extends State<HappyScreen>
    with TickerProviderStateMixin {
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
  ];
  late Color targetColor;
  int score = 0;

  Timer? _timer;
  int _secondsLeft = 60;
  bool _gameStarted = true;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _generateNewTarget();
    _startTimer();

    // Animation controller for color button scaling
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Time\'s up!')));
        _showGameOver();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateNewTarget() {
    setState(() {
      targetColor = colors[Random().nextInt(colors.length)];
    });
  }

  void _checkMatch(Color selectedColor) {
    // Trigger scale animation on color tap
    _scaleController.forward().then((_) => _scaleController.reverse());

    if (selectedColor == targetColor) {
      setState(() {
        score++;
      });
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Great job! You matched the color! 🎉')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Oops! Try again 😊')));
    }
    _generateNewTarget();
  }

  void _showGameOver() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your score is: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Go back to the previous screen
              },
              child: const Text('Go to Previous Page'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Happy Hills - Color Match"),
        centerTitle: true,
        backgroundColor: Colors.yellowAccent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.red,
                      Colors.green,
                      Colors.blue,
                      Colors.yellow,
                    ],
                  ),
                ),
                if (_gameStarted)
                  Column(
                    children: [
                      Text(
                        'Time left: $_secondsLeft s',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Can you tap the color that matches?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Match this color:",
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: targetColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children:
                            colors.map((color) {
                              return GestureDetector(
                                onTap: () => _checkMatch(color),
                                child: MouseRegion(
                                  onEnter: (_) {
                                    // When mouse hovers over the color
                                    setState(() {});
                                  },
                                  onExit: (_) {
                                    // When mouse stops hovering over the color
                                    setState(() {});
                                  },
                                  child: AnimatedBuilder(
                                    animation: _scaleController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _scaleAnimation.value,
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey.shade700,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
