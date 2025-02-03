import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = "";
  bool _isEditing = false;
  bool _isLoading = true;
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Fetch User Data from Firestore
  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _username = userDoc['username'] ?? "Unknown User";
            _usernameController.text = _username;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _username = "Error loading name";
          _isLoading = false;
        });
        print("Error fetching username: $e");
      }
    }
  }

  /// Update Username in Firestore
  Future<void> _updateUsername() async {
    User? user = _auth.currentUser;
    if (user != null && _usernameController.text.trim().isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
      });

      setState(() {
        _username = _usernameController.text.trim();
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isLoading
          ? const CircularProgressIndicator() // Show spinner while loading
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 100, color: Colors.blue),
                const SizedBox(height: 16),

                // Username Display
                _isEditing
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Edit Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Text(
                        _username,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                const SizedBox(height: 16),

                // Save / Edit Button
                _isEditing
                    ? ElevatedButton(
                        onPressed: _usernameController.text.trim().isEmpty
                            ? null
                            : _updateUsername, // Disable if empty
                        child: const Text('Save'),
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),

                const SizedBox(height: 16),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }
}