import 'package:autismotech_app/screens/ProgressSummaryScreen.dart';
import 'package:autismotech_app/screens/QuestionsScreen.dart';
import 'package:autismotech_app/screens/SummaryScreen.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int _selectedIndex = 0;

  final List<String> _icons = [
    'assets/images/home.png',
    'assets/images/questions.png',
    'assets/images/summary.png',
  ];

  final List<String> _selectedIcons = [
    'assets/images/homeafterclick.png',
    'assets/images/questionsafterclick.png',
    'assets/images/summaryafterclick.png',
  ];

  final List<String> _labels = ['Home', 'Questions', 'Summary'];

  final List<Widget> _screens = [
    ProgressSummaryScreen(), // Home screen
    QuestionsScreen(),       // Questions screen
    SummaryScreen(),         // Summary screen
  ];

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _screens[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: BottomNavigationBar(
        items: List.generate(_icons.length, (index) {
          final isSelected = _selectedIndex == index;
          return BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSelected ? 54 : 42,
                  height: isSelected ? 42 : 34,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF03045E) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    isSelected ? _selectedIcons[index] : _icons[index],
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
            label: '',
          );
        }),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
