import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_exercises/screens/home_screen_detail_online.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchExercises(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('shared', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final description = data['description'] as String? ?? '';

        if (title.toLowerCase().contains(query.toLowerCase()) ||
            description.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'exerciseId': doc.id,
            ...data,
          });
        } else {
          final questionsSnapshot =
              await doc.reference.collection('questions').get();
          for (var questionDoc in questionsSnapshot.docs) {
            final questionData = questionDoc.data();
            if ((questionData['questionText'] as String)
                .toLowerCase()
                .contains(query.toLowerCase())) {
              results.add({
                'exerciseId': doc.id,
                ...data,
              });
              break;
            }
          }
        }
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error during search: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Search exercises...",
                                hintStyle: TextStyle(
                                  color:
                                      isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              onSubmitted: _searchExercises,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: isDarkMode ? Colors.white : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchResults.clear();
                                  _hasSearched = false;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hasSearched && _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              "No results found.",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final exercise = _searchResults[index];
                              return _buildExerciseCard(exercise, isDarkMode);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, bool isDarkMode) {
    List<String> exerciseCategories = List<String>.from(exercise["categories"] ?? []);
    int downloadCount = exercise["downloadedCount"] ?? 0;
    String creatorUsername = exercise["creatorUsername"] ?? "Unknown";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 6),

                  // ✅ Row for Download Count & Username (Matches HomeScreen)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.download, size: 18, color: Colors.blue),
                              const SizedBox(width: 5),
                              Text(
                                _formatDownloadCount(downloadCount),
                                style: const TextStyle(fontSize: 14, color: Colors.blue),
                              ),

                              
                            ],
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "By: $creatorUsername",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  builder: (context) => HomeScreenDetailOnline(
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

  String _formatDownloadCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}