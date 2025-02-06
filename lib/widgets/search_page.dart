import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/exercise_page.dart';

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
          padding: const EdgeInsets.all(16.0),
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
                        color: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200], // Adjust color for dark mode
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
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600], // Adjust hint text color
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black, // Adjust input text color
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
              const SizedBox(height: 16),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              if (!_isLoading && !_hasSearched)
                const Center(
                  child: Text(
                    "Search for an exercise...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              if (!_isLoading && _hasSearched && _searchResults.isEmpty)
                const Center(
                  child: Text(
                    "No results found.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              if (!_isLoading && _searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          title: Text(
                            result['title'] ?? 'Untitled Exercise',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result['description'] ?? 'No description'),
                              Text(
                                'Created by: ${result['creatorUsername'] ?? 'Unknown User'}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExercisePage(
                                  exerciseNumber: result['exerciseId'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}