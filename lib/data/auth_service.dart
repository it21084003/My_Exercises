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

  /// **🔹 Google Sign-In & Link or Save User to Firestore**
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;
      User? user;

      // Check if the email is already registered with Firebase Authentication
      final String email = googleUser.email;
      final List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        // Email already exists, attempt to link the Google credential to the existing account
        User? existingUser = _auth.currentUser;
        if (existingUser == null || existingUser.email != email) {
          // Sign in with the existing email/password first (if possible, or handle manually)
          // For now, we’ll sign in directly with Google and handle linking later if needed
          userCredential = await _auth.signInWithCredential(credential);
          user = userCredential.user;
        } else {
          // Link the Google credential to the existing user
          try {
            userCredential = await existingUser.linkWithCredential(credential);
            user = userCredential.user;
          } catch (e) {
            print("❌ Error linking Google account: $e");
            // If linking fails, sign in directly (but preserve data)
            userCredential = await _auth.signInWithCredential(credential);
            user = userCredential.user;
          }
        }
      } else {
        // Email doesn’t exist, create a new user with Google
        userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;
      }

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
            'points': 0,
            'level': 'Beginner',
            'badges': [],
            'completed_exercises': [],
          });
        } else {
          // Update Firestore with Google-specific data (e.g., profile picture, display name) if needed,
          // but preserve existing data like username, exercises, and password
          await _firestore.collection('users').doc(user.uid).update({
            'profilePicture': FieldValue.arrayUnion([user.photoURL ?? userDoc['profilePicture']]),
            'username': userDoc['username'] ?? user.displayName ?? 'New User', // Preserve existing username
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

  // Register User & Save to Firestore
  Future<String?> register(String email, String password, String userName) async {
    try {
      // ✅ First, validate the email format before sending to Firebase
      if (!_isValidEmail(email)) {
        return 'Invalid email format. Please enter a valid email.';
      }

      // ✅ Proceed with Firebase Authentication (this will throw if email exists)
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
          'firstTimeLogin': true,
          'createdAt': FieldValue.serverTimestamp(),
          'points': 0,
          'level': 'Beginner',
          'badges': [],
          'completed_exercises': [],
        });
        return null; // ✅ No error (successful registration)
      }
      return 'Registration failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email already exists. Please use a different email or log in.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email format. Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak. Please use at least 6 characters.';
      } else {
        return 'Registration failed. Please try again: ${e.message}';
      }
    } catch (e) {
      return 'Registration failed. Please try again: $e';
    }
  }

  // ✅ Helper function to validate email format before Firebase request
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
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

  /// **🔹 Link Google Account to Existing Email/Password Account**
  Future<User?> linkGoogleToExistingAccount(String email, String password) async {
    try {
      // Sign in with email/password to get the existing user
      UserCredential emailCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? existingUser = emailCredential.user;

      if (existingUser == null) return null;

      // Sign in with Google to get the Google credential
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the Google credential to the existing user
      await existingUser.linkWithCredential(googleCredential);
      return existingUser;
    } catch (e) {
      print("❌ Error linking Google account: $e");
      return null;
    }
  }
}