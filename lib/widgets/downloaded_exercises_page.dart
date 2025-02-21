import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_exercises/widgets/home_screen_detail.dart';
import '../data/offline_database_helper.dart';

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
    final exercises = await DatabaseHelper.getDownloadedExercises();
    setState(() {
      _downloadedExercises = exercises;
      _isLoading = false;
    });
  }

  Future<void> _removeDownloadedExercise(String exerciseId) async {
    // Add confirmation dialog before deletion
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
      await DatabaseHelper.removeDownloadedExercise(exerciseId);
      // Refetch the downloaded exercises to ensure the list is up-to-date
      await _fetchDownloadedExercises();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exercise removed successfully.")),
      );
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
                        onTap: () {
                          // Navigate to HomeScreenDetail for the downloaded exercise
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
                  },
                ),
    );
  }
}