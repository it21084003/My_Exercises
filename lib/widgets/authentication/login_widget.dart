import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_exercises/data/auth_service.dart';
import 'package:my_exercises/widgets/authentication/register_widget.dart';
import 'package:my_exercises/widgets/authentication/reset_password_widget.dart';
import 'package:my_exercises/widgets/categories/select_categories_widget.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  LoginWidgetState createState() => LoginWidgetState();
}

class LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      bool? isFirstTime = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (isFirstTime == null) {
        setState(() {
          _emailError = 'Invalid email or password';
          _passwordError = 'Invalid email or password';
        });
      } else {
        // ✅ Navigate to correct page based on first-time login status
        _navigateAfterLogin(isFirstTime);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    User? user = await _authService.signInWithGoogle();
    if (!mounted) return;

    if (user != null) {
      // 🚀 Fetch user Firestore data
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      bool isFirstTime = userDoc.exists ? userDoc['firstTimeLogin'] ?? true : true;

      _navigateAfterLogin(isFirstTime);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _navigateAfterLogin(bool isFirstTime) {
    if (isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SelectCategoriesWidget(
            onCategoriesSelected: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({'firstTimeLogin': false});

              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _goToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterWidget()),
    );
  }

  void _goToResetPasswordPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPasswordWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 📌 **App Logo**
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.create, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "My Exercises",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Let's get started!\nLog in to enjoy the features we've provided.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // 📌 **Form Section**
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline,
                          obscureText: true,
                          errorText: _passwordError,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 📌 **Login Button**
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📌 **Social Media Login**
                  const Text("or continue with", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.facebook, color: Colors.blue),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/ios_neutral_rd_na@4x.png',
                          height: 30,
                          width: 30,
                        ),
                        onPressed: _loginWithGoogle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.apple, color: Colors.black),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 📌 **Sign Up & Forgot Password**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _goToRegisterPage,
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text(" | "),
                      GestureDetector(
                        onTap: _goToResetPasswordPage,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 📌 **Loading Indicator**
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CupertinoActivityIndicator(radius: 15)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        errorText: errorText,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter your $label' : null,
    );
  }
}