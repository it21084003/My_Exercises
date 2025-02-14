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

      // ✅ Filter out forked exercises where `shared` is now `false`
      List<Map<String, dynamic>> filteredExercises = [];
      for (var exercise in exercises) {
        if (exercise['isForked'] == true) {
          final originalExercise = await _firestoreService.getExerciseById(exercise['exerciseId']);
          if (originalExercise == null || originalExercise['shared'] == false) {
            // 🔥 Skip this exercise (it was unshared)
            continue;
          }
        }
        filteredExercises.add(exercise);
      }

      if (mounted) {
        setState(() {
          _exercises = filteredExercises;
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
      onWillPop: () async => false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
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
                        child: CupertinoActivityIndicator(radius: 15),
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
                        final List<String> exerciseCategories =
                            List<String>.from(exercise["categories"] ?? []);

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
                                        isForked
                                            ? 'Forked from: $originalCreator'
                                            : 'Created by you',
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
                                      const SizedBox(height: 6),

                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: exerciseCategories.map((category) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(16),
                                              border:
                                                  Border.all(color: Colors.blue, width: 1),
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

                                      Row(
                                        children: [
                                          const Icon(Icons.download,
                                              size: 18, color: Colors.blue),
                                          const SizedBox(width: 5),
                                          Text(
                                            _formatDownloadCount(downloadedCount),
                                            style: const TextStyle(
                                                fontSize: 14, color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: isForked
                                      ? IconButton(
                                          icon: const Icon(Icons.remove_circle_outline,
                                              color: Colors.red),
                                          onPressed: () => _unforkExercise(exerciseId!),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.edit_note,
                                              color: Colors.blue),
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
                                  onTap: () => _navigateToHomeScreenDetail(context, exerciseId),
                                ),
                              ],
                            ),
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

  String _formatDownloadCount(int count) {
    if (count >= 1000000) {
      return count % 1000000 == 0 ? '${count ~/ 1000000}M' : '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return count % 1000 == 0 ? '${count ~/ 1000}K' : '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}