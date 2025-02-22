import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:my_exercises/widgets/exercises/my_exercises_widget.dart';
import '../../screens/home/home_screen.dart';
//import 'my_exercises_screen.dart';
import '../../screens/settings/settings_page.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MyExercises(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: isDarkMode ? Colors.black : const Color.fromRGBO(253, 247, 254, 1), // Dynamic BG Color
        color:  Colors.blueAccent, // Navbar Color
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          Icon(Icons.home, color: isDarkMode ? Colors.black : Colors.white, size: 30),
          Icon(Icons.book, color: isDarkMode ? Colors.black : Colors.white, size: 30),
          Icon(Icons.person, color: isDarkMode ? Colors.black : Colors.white, size: 30),
        ],
      ),
    );
  }
}