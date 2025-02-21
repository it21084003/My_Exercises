// widgets/select_categories_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SelectCategoriesPage extends StatefulWidget {
  final VoidCallback onCategoriesSelected;

  const SelectCategoriesPage({super.key, required this.onCategoriesSelected});

  @override
  _SelectCategoriesPageState createState() => _SelectCategoriesPageState();
}

class _SelectCategoriesPageState extends State<SelectCategoriesPage> {
  final List<String> _categories = [
    'Math', 'Science', 'English', 'Programming', 'History',
    'Geography', 'Physics', 'Chemistry', 'Biology', 'Music',
    'Arts', 'Health', 'Sports', 'Technology', 'Finance'
  ]; // **15 categories**

  final Set<String> _selectedCategories = {}; // Store selected categories
  bool _isSaving = false; // Track saving process

  Future<void> _saveFavoriteCategories() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one category.")),
      );
      return;
    }

    setState(() {
      _isSaving = true; // Show loading state
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print("🚀 Saving categories and FCM token to Firestore...");

        // Get FCM Token
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'favoriteCategories': _selectedCategories.toList(),
            'firstTimeLogin': false, // ✅ Mark first login as completed
            'fcmToken': fcmToken, // Store FCM token for notifications
          },
          SetOptions(merge: true), // Merge with existing data
        );

        print("✅ Categories and FCM token saved successfully!");

        if (mounted) {
          widget.onCategoriesSelected(); // Call the callback to navigate
        }
      } catch (e) {
        print("❌ Error saving categories: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save categories. Error: $e")),
        );
      }
    } else {
      print("❌ User is null! Firestore update failed.");
    }

    if (mounted) {
      setState(() {
        _isSaving = false; // Hide loading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pick your favorite categories:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategories.remove(category);
                        } else {
                          _selectedCategories.add(category);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : (isDarkMode ? Colors.grey[900] : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(14),
            onPressed: _isSaving || _selectedCategories.isEmpty
                ? null
                : _saveFavoriteCategories, // Disable while saving or no selection
            child: _isSaving
                ? const CupertinoActivityIndicator() // Show loading spinner
                : const Text(
                    "Save",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}