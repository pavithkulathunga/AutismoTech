import 'dart:async';
import 'package:flutter/material.dart';

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
                      ElevatedButton.icon(
                        onPressed: _restartGame,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Restart"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
