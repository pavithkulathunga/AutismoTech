import 'package:flutter/material.dart';
import 'package:autismotech_app/constants/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget greetingWidget() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return const Text.rich(
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
                text: 'Morning!',
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
                text: 'Morning!',
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
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Color(0xFFe4f6e0),
            // padding: const EdgeInsets.all(8),
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                greetingWidget(),
                Image.asset(
                  'assets/images/home_girl.png',
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          // navigations for screens
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/diagnosis');
                  },
                  child: Container(
                    //ASD Diagnosis
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.health_and_safety,
                            color: Colors.lightBlue,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'ASD Diagnosis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  //Attention Enhancing
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: Colors.orange,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Attention Enhancing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  //Emotion detection
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.face, color: Colors.green, size: 50),
                        const SizedBox(height: 10),
                        const Text(
                          'Emotion Detection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  //Progress Prediction
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.purple,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Progress Prediction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
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
    );
  }
}
