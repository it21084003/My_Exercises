import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/login_form.dart';
import 'widgets/home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData.light(), // Default light theme
      darkTheme: ThemeData.dark(), // Support for dark mode
      themeMode: ThemeMode.system, // Automatically switch theme based on system setting
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginForm(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// Determines whether to show login or home screen based on auth status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show iOS-style loading indicator
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        } else if (snapshot.hasData) {
          // Smooth transition to Home Page
          return const HomePage();
        } else {
          // Smooth transition to Login Page
          return const LoginForm();
        }
      },
    );
  }
}