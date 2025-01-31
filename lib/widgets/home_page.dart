import 'package:flutter/material.dart';
import '../data/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    void _logout() async {
      await _authService.logout();
      Navigator.pushReplacementNamed(context, '/'); // Navigate to login screen
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to the Home Page!'),
      ),
    );
  }
}