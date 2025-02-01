import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ResetPasswordPage widget for users to reset their passwords
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ResetPasswordPageState createState() => ResetPasswordPageState();
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final TextEditingController _emailController = TextEditingController(); // Controller for email input

  // Function to handle password reset
  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent successfully.')), // Success message
        );
        Navigator.pop(context); // Navigate back after success
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email does not exist in Firebase.')), // Error message for non-existent email
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')), // Display any other errors
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')), // Catch any other errors
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')), // AppBar with title
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
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email'; // Validation for empty email
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Reset Password button
              ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}