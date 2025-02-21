import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:my_exercises/widgets/my_exercises.dart';
import 'home_screen.dart';
//import 'my_exercises_screen.dart';
import 'menu_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MyExercises(),
    MenuScreen(),
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
        backgroundColor: isDarkMode ? Colors.black : Colors.white, // Dynamic BG Color
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