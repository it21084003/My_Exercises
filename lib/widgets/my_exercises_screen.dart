import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_exercises/widgets/edit_exercise_page.dart';
import 'package:my_exercises/widgets/home_screen_detail.dart';
import '../data/firestore_service.dart';
import 'create_exercise_page.dart';

class MyExercisesPage extends StatefulWidget {
  const MyExercisesPage({super.key});

  @override
  State<MyExercisesPage> createState() => _MyExercisesPageState();
}

class _MyExercisesPageState extends State<MyExercisesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _firestoreService.fetchUserExercises();
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching exercises: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToCreateExercise() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExercisePage()),
    );
    _fetchExercises();
  }

  Future<void> _unforkExercise(String exerciseId) async {
    try {
      await _firestoreService.unforkExercise(exerciseId);
      setState(() {
        _exercises.removeWhere((exercise) => exercise['exerciseId'] == exerciseId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unforking exercise: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // Prevent accidental logout swipe
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔹 Title and Add Button in the Same Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Exercises",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 28, color: Colors.blue),
                    onPressed: _navigateToCreateExercise,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.streamUserExercises(),
                  builder: (context, snapshot) {
                    if (_isLoading) {
                      return const Center(
                        child: CupertinoActivityIndicator(radius: 15), // ✅ iOS-style loading spinner
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final exercises = snapshot.data ?? [];
                    if (exercises.isEmpty) {
                      return const Center(
                        child: Text(
                          'No exercises found. Create or fork an exercise!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        final exerciseId = exercise['exerciseId'];
                        final title = exercise['title'] ?? 'Untitled Exercise';
                        final description = exercise['description'] ?? 'No description.';
                        final bool isForked = exercise['isForked'] ?? false;
                        final originalCreator = exercise['creatorUsername'] ?? '';
                        final int downloadedCount = exercise['downloadedCount'] ?? 0;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          child: ListTile(
                            title: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isForked ? 'Forked from: $originalCreator' : 'Created by you',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                if (!isForked)
                                  Text(
                                    'Downloaded by: $downloadedCount users',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isForked)
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditExercisePage(
                                            exerciseId: exerciseId,
                                            title: title,
                                            shared: exercise['shared'],
                                          ),
                                        ),
                                      ).then((_) => _fetchExercises());
                                    },
                                  ),
                                if (isForked)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _unforkExercise(exerciseId!),
                                  ),
                              ],
                            ),
                            onTap: () {
                              if (exerciseId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Exercise ID is missing!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _navigateToHomeScreenDetail(context, exerciseId);
                            },
                          ),
                        );
                      },
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

  void _navigateToHomeScreenDetail(BuildContext context, String exerciseId) async {
    setState(() => _isLoading = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreenDetail(exerciseId: exerciseId),
      ),
    );

    _fetchExercises();
  }
}