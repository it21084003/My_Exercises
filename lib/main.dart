import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/login_form.dart';
import 'widgets/home_page.dart';
import 'firebase_options.dart';

// Entry point of the Flutter application
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is initialized before Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Initializes Firebase
  runApp(const MyApp()); // Runs the main application
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes debug banner
      title: 'My App', // Application title
      theme: ThemeData(primarySwatch: Colors.blue), // Sets app theme
      home: const AuthWrapper(), // Determines initial screen
      routes: {
        '/login': (context) => const LoginForm(), // Login page route
        '/home': (context) => const HomePage(), // Home page route
      },
    );
  }
}

// Widget to check user authentication status and navigate accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listens for authentication state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Shows loading spinner while checking auth status
        } else if (snapshot.hasData) {
          return const HomePage(); // Redirects to HomePage if user is logged in
        } else {
          return const LoginForm(); // Redirects to LoginForm if user is not logged in
        }
      },
    );
  }
}