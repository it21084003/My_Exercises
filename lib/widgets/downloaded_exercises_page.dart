import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_exercises/data/offline_database_helper.dart';
import 'package:my_exercises/screens/home_screen_detail_offline.dart'; 

class DownloadedExercisesPage extends StatefulWidget {
  const DownloadedExercisesPage({super.key});

  @override
  State<DownloadedExercisesPage> createState() => _DownloadedExercisesPageState();
}

class _DownloadedExercisesPageState extends State<DownloadedExercisesPage> {
  List<Map<String, dynamic>> _downloadedExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDownloadedExercises();
  }

  Future<void> _fetchDownloadedExercises() async {
    try {
      final exercises = await DatabaseHelper.getDownloadedExercises();
      debugPrint("Fetched exercises: $exercises");
      if (mounted) {
        setState(() {
          _downloadedExercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching exercises: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading exercises: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeDownloadedExercise(String exerciseId) async {
    debugPrint("Attempting to remove exercise with ID: $exerciseId");
    bool confirm = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Remove Exercise"),
        content: const Text("Are you sure you want to remove this downloaded exercise?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Remove"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final exists = await DatabaseHelper.isDownloaded(exerciseId);
        debugPrint("Exercise exists before deletion: $exists");
        if (!exists) {
          throw Exception("Exercise with ID $exerciseId not found in local storage.");
        }

        await DatabaseHelper.removeDownloadedExercise(exerciseId);
        await _fetchDownloadedExercises();

        final stillExists = await DatabaseHelper.isDownloaded(exerciseId);
        debugPrint("Exercise exists after deletion: $stillExists");
        if (stillExists) {
          throw Exception("Failed to delete exercise with ID $exerciseId.");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Exercise removed successfully.")),
          );
        }
      } catch (e) {
        debugPrint("Error removing exercise: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error removing exercise: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _navigateToExercise(String exerciseId) {
    debugPrint("Navigating to ExercisePageOffline with ID: $exerciseId");
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreenDetailOffline(exerciseId: exerciseId),
        ),
      ).then((_) => _fetchDownloadedExercises());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloaded Exercises"),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : _downloadedExercises.isEmpty
              ? const Center(
                  child: Text(
                    "No downloaded exercises found.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _downloadedExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _downloadedExercises[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      child: ListTile(
                        title: Text(
                          exercise['title'] ?? 'Untitled Exercise',
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
                              exercise['description'] ?? 'No description.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Total Questions: ${exercise['totalQuestions'] ?? 0}",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeDownloadedExercise(exercise['exerciseId']),
                              tooltip: 'Remove Download',
                            ),
                          ],
                        ),
                        onTap: () => _navigateToExercise(exercise['exerciseId']),
                      ),
                    );
                  },
                ),
    );
  }
}