import 'package:flutter/material.dart';
import 'package:my_exercises/data/auth_service.dart';
import 'package:my_exercises/widgets/home_page.dart';
import 'package:my_exercises/widgets/register_page.dart';
import 'package:my_exercises/widgets/reset_password.dart';

// LoginForm widget for user authentication
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>(); // Form key to validate input fields
  final TextEditingController _emailController = TextEditingController(); // Controller for email input
  final TextEditingController _passwordController = TextEditingController(); // Controller for password input
  final AuthService _authService = AuthService(); // Authentication service instance

  String? _emailError;
  String? _passwordError;

  // Function to handle login
  void _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      bool success = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()), // Redirects to HomePage upon successful login
        );
      } else {
        setState(() {
          _emailError = 'Invalid email or password';
          _passwordError = 'Invalid email or password';
        });
      }
    }
  }

  // Function to navigate to RegisterPage
  void _goToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()), // Opens registration page
    );
  }

  // Function to navigate to ResetPasswordPage
  void _goToResetPasswordPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPasswordPage()), // Opens password reset page
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')), // AppBar with login title
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email input field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  errorText: _emailError,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email'; // Validates empty email field
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password input field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  errorText: _passwordError,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password'; // Validates empty password field
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Login button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 10),
              // Register navigation button
              TextButton(
                onPressed: _goToRegisterPage,
                child: const Text('Create an account'),
              ),
              // Password reset navigation button
              TextButton(
                onPressed: _goToResetPasswordPage,
                child: const Text('Forgot password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}