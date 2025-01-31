import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Sign In with Email & Password
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _logger.e("Login failed: $e");
      return false;
    }
  }

  // Register New User
  Future<bool> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _logger.e("Registration failed: $e");
      return false;
    }
  }

  // Password Reset
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _logger.e("Password reset failed: $e");
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut(); // Sign out from Firebase
    await GoogleSignIn().signOut(); // Sign out from Google (if applicable)
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      _logger.e("Google Sign-In failed: $e");
      return false;
    }
  }
}
