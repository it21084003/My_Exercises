import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Getter to access Firebase Firestore
  FirebaseFirestore get firestore => _firestore;

  // Getter to get the currently logged-in user
  User? get currentUser => _auth.currentUser;

  /// **🔹 Google Sign-In & Save User to Firestore**
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Save user details in Firestore for first-time users
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'username': user.displayName ?? 'New User',
            'profilePicture': user.photoURL ?? '',
            'description': 'No description provided',
            'favoriteCategories': [],
            'firstTimeLogin': true, // Mark first login
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        return user;
      }
      return null;
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      return null;
    }
  }

  // Register New User
  Future<bool> register(String email, String password, String userName) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': userName,
          'description': 'No description available',
          'profilePicture': '',
          'favoriteCategories': [],
          'firstTimeLogin': true, // ✅ First-time login flag
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Registration Error: $e');
      return false;
    }
  }

  // Login User & Check First-Time Login
  Future<bool?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          bool isFirstTime = userDoc['firstTimeLogin'] ?? true;
          return isFirstTime; // ✅ Return firstTimeLogin status
        }
      }
      return false; // Default to false if something goes wrong
    } catch (e) {
      print("❌ Login Error: $e");
      return null; // Return null on error
    }
  }

  /// **🔹 Check if First-Time Login**
  Future<bool> isFirstTimeLogin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return (userDoc.data() as Map<String, dynamic>)['firstTimeLogin'] ?? false;
      }
    } catch (e) {
      print('❌ Error checking first-time login: $e');
    }
    return false;
  }

  /// **🔹 Upload Profile Picture**
  Future<String?> uploadProfilePicture(String uid, String filePath) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$uid.jpg');
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      return null;
    }
  }

  /// **🔹 Reset Password**
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      print("❌ Password reset failed: ${e.message}");
      return false;
    }
  }

  /// **🔹 Logout User**
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print("✅ User Logged Out Successfully");
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }
}