import 'package:firebase_auth/firebase_auth.dart';

// AuthService handles authentication functions for the app
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase authentication instance

  // Function to log in a user with email and password
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true; // Login successful
    } on FirebaseAuthException catch (e) {
      print("Login failed: ${e.message}"); // Print error for debugging
      return false; // Login failed
    }
  }

  // Function to register a new user with email and password
  Future<bool> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true; // Registration successful
    } catch (e) {
      print("Registration failed: $e"); // Print error for debugging
      return false; // Registration failed
    }
  }

  // Function to send a password reset email
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true; // Password reset email sent successfully
    } on FirebaseAuthException catch (e) {
      print("Password reset failed: ${e.message}"); // Print error for debugging
      return false; // Password reset failed
    }
  }

  // Function to log out the current user
  Future<void> logout() async {
    await _auth.signOut(); // Sign out from Firebase
  }
}