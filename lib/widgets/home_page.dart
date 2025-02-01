import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'exercise_page.dart';

// HomePage widget with bottom navigation bar
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Index for navigation bar

  // Function to navigate to an exercise page
  void _navigateToExercise(int exerciseNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExercisePage(exerciseNumber: exerciseNumber)),
    );
  }

  // Function to handle navigation bar tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService(); // Initialize AuthService for handling logout

    // List of pages for navigation
    final List<Widget> pages = <Widget>[
      ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Exercise 1'),
            onTap: () => _navigateToExercise(1),
          ),
          const Divider(),
          ListTile(
            title: const Text('Exercise 2'),
            onTap: () => _navigateToExercise(2),
          ),
          const Divider(),
          ListTile(
            title: const Text('Exercise 3'),
            onTap: () => _navigateToExercise(3),
          ),
        ],
      ),
      const Center(child: Text('My Page')), // My Page
      const Center(child: Text('Profile Page')), // Profile Page
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'), // Title displayed in the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Logout icon button
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/'); // Redirect to login screen after logout
            },
          ),
        ],
      ),
      body: pages[_selectedIndex], // Display selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'My',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
