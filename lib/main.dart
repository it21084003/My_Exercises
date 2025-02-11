import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/login_form.dart';
import 'widgets/home_page.dart';
import 'widgets/select_categories_page.dart';
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginForm(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  late Widget _nextPage;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _nextPage = const LoginForm(); // 🚀 No user → Show login
    } else {
      // 🚀 Check Firestore for firstTimeLogin
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        bool isFirstTime = userDoc['firstTimeLogin'] ?? true;
        
        if (isFirstTime) {
          _nextPage = SelectCategoriesPage(
            onCategoriesSelected: () async {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'firstTimeLogin': false, // ✅ Mark as NOT first login
              });

              if (mounted) {
                setState(() {
                  _nextPage = const HomePage();
                });
              }
            },
          );
        } else {
          _nextPage = const HomePage();
        }
      } else {
        _nextPage = const LoginForm(); // If no Firestore data, force login
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return _nextPage;
  }
}