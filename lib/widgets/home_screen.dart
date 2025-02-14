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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      List<String> favoriteCategories =
          List<String>.from(userDoc['favoriteCategories'] ?? []);
      setState(() {
        _categories = [
          "All",
          ...favoriteCategories
        ]; // Add "All" at the beginning
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
        padding: const EdgeInsets.all(10.0),
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
                          MaterialPageRoute(
                              builder: (context) => const SearchPage()),
                        );
                      },
                    ),

                    // 🏷 iOS-style Dropdown (Cupertino Action Sheet)
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color:
                              isDarkMode ? Colors.grey[900] : Colors.grey[200],
                        ),
                        child: Row(
                          children: [
                            _isCategoryLoading
                                ? const CupertinoActivityIndicator(
                                    radius: 8) // Show spinner if loading
                                : Text(
                                    _selectedCategory,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
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
                future: _firestoreService.fetchFilteredExercises(
                    category: _selectedCategory), // ✅ Pass category
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CupertinoActivityIndicator(radius: 15));
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

void _showCategoryPicker() {
  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      return CupertinoActionSheet(
        title: const Text("Select Category"),
        actions: [
          ..._categories.map((category) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
              child: Text(category, style: const TextStyle(fontSize: 18)),
            );
          }),
          
          // 🔹 Add "Manage Categories" option
          // 🔹 Modify the function call inside _showCategoryPicker
CupertinoActionSheetAction(
  onPressed: () {
    Navigator.pop(context);
    _showManageCategoriesDialog(Theme.of(context).brightness == Brightness.dark);
  },
  child: const Text(
    "Manage Categories",
    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
  ),
),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text("Cancel"),
        ),
      );
    },
  );
}

Future<void> _updateCategories(List<String> selectedCategories) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Exclude "All" category before saving
      List<String> categoriesToSave = selectedCategories.where((category) => category != "All").toList();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'favoriteCategories': categoriesToSave,
      });

      setState(() {
        _categories = ["All", ...categoriesToSave]; // Ensure "All" stays
      });

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("Categories updated successfully!"),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } catch (e) {
      print("Error updating categories: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update categories."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



void _showManageCategoriesDialog(bool isDarkMode) {
  List<String> predefinedCategories = [
    'Math', 'Science', 'English', 'Programming', 'History',
    'Geography', 'Physics', 'Chemistry', 'Biology', 'Music',
    'Arts', 'Health', 'Sports', 'Technology', 'Finance'
  ];

  List<String> selectedCategories = List.from(_categories); // Store selected categories

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 70, // Add top padding here
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Manage Categories",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 🔹 Selectable Categories Grid
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 items per row
                      childAspectRatio: 3.5, // Adjust button height
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: predefinedCategories.length,
                    itemBuilder: (context, index) {
                      String category = predefinedCategories[index];
                      bool isSelected = selectedCategories.contains(category);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            isSelected
                                ? selectedCategories.remove(category)
                                : selectedCategories.add(category);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Save Button (Fixing isDarkMode Issue)
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(14),
                    color: isDarkMode
                        ? const Color(0xFF9B51E0) // 🔥 Beautiful Dark Mode Purple
                        : const Color.fromARGB(255, 163, 95, 163), // 🎨 Light Lavender in Light Mode
                    disabledColor: Colors.grey, // Disabled state
                    onPressed: () async {
                      await _updateCategories(selectedCategories);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Save Categories",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text for better visibility
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    },
  );
}

 // 📝 Exercise Card UI
Widget _buildExerciseCard(Map<String, dynamic> exercise, bool isDarkMode) {
  List<String> exerciseCategories = List<String>.from(exercise["categories"] ?? []);
  int downloadCount = exercise["downloadedCount"] ?? 0;
  String creatorUsername = exercise["creatorUsername"] ?? "Unknown";
  String timeAgo = exercise["timestamp"] ?? "Unknown"; 


  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
    color: isDarkMode ? Colors.grey[900] : Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
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
                  exercise['description'] ?? 'No description.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                // ✅ Updated Category Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: exerciseCategories.map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15), // Light blue background
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue, width: 1), // Thin blue border
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // Text color matches border
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 6),

                // ✅ Split Row: Download Count on Left, Username starting from Middle
                Row(
                  children: [
                    // Download Count (Left)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.download, size: 18, color: Colors.blue),
                          const SizedBox(width: 5),
                          Text(
                            _formatDownloadCount(downloadCount),
                            style: const TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            "$timeAgo",
                            style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                          ),
                        ],
                      ),
                    ),

                    // Username (Right, starting from middle)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight, // Move to the right side
                        child: Text(
                          "By: $creatorUsername",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis, // ✅ Cuts long names
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
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
        ],
      ),
    ),
  );
}

  /// ✅ Formats large numbers (e.g., 1,500 → 1.5K, 1,200,000 → 1.2M)
  String _formatDownloadCount(int count) {
    if (count >= 1000000) {
      double value = count / 1000000;
      return value == value.toInt()
          ? '${value.toInt()}M'
          : '${value.toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      double value = count / 1000;
      return value == value.toInt()
          ? '${value.toInt()}K'
          : '${value.toStringAsFixed(1)}K';
    } else {
      return count.toString(); // Normal count for small numbers
    }
  }

  // 📌 Fetch Exercises Based on Selected Category
  Future<List<Map<String, dynamic>>> _fetchFilteredExercises() async {
    return await _firestoreService.fetchFilteredExercises(
        category: _selectedCategory);
  }
}
