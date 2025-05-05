import 'package:flutter/material.dart';
import 'package:autismotech_app/constants/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget greetingWidget() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Good\n',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3c6e1d),
                    ),
                  ),
                  TextSpan(
                    text: 'Morning!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF3c6e1d),
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/images/home_girl.png',
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ],
        );
      } else if (hour < 17) {
        return const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Good\n',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              TextSpan(
                text: 'Afternoon!',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w300,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        );
      } else {
        return const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Good\n',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              TextSpan(
                text: 'Evening!',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w300,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text('Autismo-Tech'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: [
          // Positioned footer image (Z-index 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/home_footer.png',
              fit: BoxFit.cover,
              // height: 200,
            ),
          ),

          // Main content scrollable (Z-index 1)
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 200,
            ), // Space for footer image
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: const Color(0xFFe4f6e0),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      greetingWidget(),
                      
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Row 1
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTile(
                        context,
                        icon: Icons.health_and_safety,
                        label: 'ASD Diagnosis',
                        color: Colors.lightBlue,
                        routeName: '/diagnosis',
                      ),
                      const SizedBox(width: 20),
                      _buildTile(
                        context,
                        icon: Icons.lightbulb,
                        label: 'Attention Enhancing',
                        color: Colors.orange,
                        routeName: '/attention',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Row 2
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTile(
                        context,
                        icon: Icons.face,
                        label: 'Emotion Detection',
                        color: Colors.green,
                        routeName: '/emotion',
                      ),
                      const SizedBox(width: 20),
                      _buildTile(
                        context,
                        icon: Icons.trending_up,
                        label: 'Progress Prediction',
                        color: Colors.purple,
                        routeName: '/progress',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String routeName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        height: 180,
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 50),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
