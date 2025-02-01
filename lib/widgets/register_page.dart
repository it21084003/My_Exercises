import 'package:flutter/material.dart';
import '../data/auth_service.dart';

// RegisterPage widget for new user sign-up
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final TextEditingController _emailController = TextEditingController(); // Controller for email input
  final TextEditingController _passwordController = TextEditingController(); // Controller for password input
  final AuthService _authService = AuthService(); // Authentication service instance

  String? _emailError;
  String? _passwordError;

  // Function to handle user registration
  void _register() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      bool success = await _authService.register(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please log in.')), // Success message
        );
        Navigator.pop(context); // Navigate back to login page
      } else {
        setState(() {
          _emailError = 'Email is already in use or invalid';
          _passwordError = 'Please try a different password';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')), // AppBar with title
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
                    return 'Please enter your email'; // Validation for empty email
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
                    return 'Please enter your password'; // Validation for empty password
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Register button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
