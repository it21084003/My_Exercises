import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_exercises/widgets/home_screen_detail.dart';
import '../data/firestore_service.dart';
import 'search_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = "All"; // Default category
  List<String> _categories = []; // Dynamic categories list
  bool _isCategoryLoading = true; // Track category loading state

  @override
  void initState() {
    super.initState();
    _fetchFavoriteCategories(); // Fetch categories on startup
  }

  Future<void> _fetchFavoriteCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        List<String> favoriteCategories = List<String>.from(userDoc['favoriteCategories'] ?? []);
        setState(() {
          _categories = ["All", ...favoriteCategories]; // Add "All" at the beginning
          _isCategoryLoading = false; // Hide spinner
        });
      } catch (e) {
        print("❌ Error fetching favorite categories: $e");
        setState(() {
          _isCategoryLoading = false; // Ensure UI is not stuck on loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // ❌ Prevent swipe back logout issue
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔎 Top row with Title, Search Icon, and Category Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 📌 Home Title
                const Text(
                  "Home",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                // 🔎 Search & iOS-Style Category Picker (Right Side)
                Row(
                  children: [
                    // 🔎 Search Icon
                    IconButton(
                      icon: const Icon(Icons.search, size: 26),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchPage()),
                        );
                      },
                    ),

                    // 🏷 iOS-style Dropdown (Cupertino Action Sheet)
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                        ),
                        child: Row(
                          children: [
                            _isCategoryLoading
                                ? const CupertinoActivityIndicator(radius: 8) // Show spinner if loading
                                : Text(
                                    _selectedCategory,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                            const SizedBox(width: 5),
                            const Icon(CupertinoIcons.chevron_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFilteredExercises(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator(radius: 15));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No exercises found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final exercises = snapshot.data!;
                  return ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(exercises[index], isDarkMode);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📌 Show iOS-style Picker
  void _showCategoryPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text("Select Category"),
          actions: _categories.map((category) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
              child: Text(category, style: const TextStyle(fontSize: 18)),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text("Cancel"),
          ),
        );
      },
    );
  }

  // 📝 Exercise Card UI
  Widget _buildExerciseCard(Map<String, dynamic> exercise, bool isDarkMode) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ListTile(
        title: Text(
          exercise['title'] ?? 'Untitled Exercise',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By: ${exercise['creatorUsername'] ?? 'Unknown'}',
              style: TextStyle(
                  fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              exercise['description'] ?? 'No description.',
              style: TextStyle(
                  fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
        onTap: () {
          if (exercise['exerciseId'] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Exercise ID is missing!'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreenDetail(
                exerciseId: exercise['exerciseId'],
              ),
            ),
          );
        },
      ),
    );
  }

  // 📌 Fetch Exercises Based on Selected Category
  Future<List<Map<String, dynamic>>> _fetchFilteredExercises() async {
    return await _firestoreService.fetchFilteredExercises(category: _selectedCategory);
  }
}