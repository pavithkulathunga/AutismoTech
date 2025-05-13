import 'package:flutter/material.dart';

class SurpriseScreen extends StatelessWidget {
  const SurpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surprise Box'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8BBD0), Color(0xFFB2EBF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉 Surprise Time!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You discovered a magical gift box 🎁',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 40),
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎁', style: TextStyle(fontSize: 50)),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SurpriseHealingGame(),
                    ),
                  );
                },
                child: const Text(
                  'Open Surprise',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurpriseHealingGame extends StatefulWidget {
  const SurpriseHealingGame({super.key});

  @override
  State<SurpriseHealingGame> createState() => _SurpriseHealingGameState();
}

class _SurpriseHealingGameState extends State<SurpriseHealingGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.5, -0.5),
      end: const Offset(1.5, 0.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        backgroundColor: Colors.lightBlueAccent,
        title: const Text("Butterfly Breeze"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 1, 255, 234),
              Color.fromARGB(255, 0, 204, 7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Center(
              child: Text(
                "Catch the butterfly 🦋\nBreathe in... Breathe out...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SlideTransition(
              position: _offsetAnimation,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You caught the butterfly! Feel the calm 🦋',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Image.asset(
                    'assets/images/butterfly.png',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
