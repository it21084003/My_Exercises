import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage instance

  // Getter to access Firebase Firestore
  FirebaseFirestore get firestore => _firestore;

  // Getter to get the currently logged-in user
  User? get currentUser => _auth.currentUser;


  // Function to log in a user with email and password
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true; // Login successful
    } on FirebaseAuthException catch (e) {
      print("Login failed: ${e.message}");
      return false; // Login failed
    }
  }

  // Function to register a new user with email, password, and username
  Future<bool> register(String email, String password, String userName) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Update display name in Firebase Authentication
        await user.updateDisplayName(userName);

        // Save user details in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': userName,
          'description':null,
          'profilePicture': null, // Placeholder for profile picture
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error during registration: $e');
      return false;
    }
  }

  // Function to upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(String uid, String filePath) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$uid.jpg');
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL(); // Return download URL
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  // Function to send a password reset email
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true; // Password reset email sent successfully
    } on FirebaseAuthException catch (e) {
      print("Password reset failed: ${e.message}");
      return false; // Password reset failed
    }
  }

  // Function to log out the current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}