import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/offline_database_helper.dart';
import '../exercises/exercise_offline_page.dart';

class HomeScreenDetailOffline extends StatefulWidget {
  final String exerciseId;

  const HomeScreenDetailOffline({super.key, required this.exerciseId});

  @override
  State<HomeScreenDetailOffline> createState() => _HomeScreenDetailOfflineState();
}

class _HomeScreenDetailOfflineState extends State<HomeScreenDetailOffline> {
  String _title = "Loading...";
  String _description = "Fetching details...";
  int _questionCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExerciseDetails();
  }

  Future<void> _fetchExerciseDetails() async {
    try {
      final exercises = await DatabaseHelper.getDownloadedExercises();
      final exercise = exercises.firstWhere(
        (e) => e['exerciseId'] == widget.exerciseId,
        orElse: () => throw Exception("Exercise not found in local storage."),
      );
      final questions = await DatabaseHelper.getExerciseQuestions(widget.exerciseId);

      if (mounted) {
        setState(() {
          _title = exercise['title'] ?? "Untitled Exercise";
          _description = exercise['description'] ?? "No description available.";
          _questionCount = questions.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _title = "Error loading exercise";
          _description = "An error occurred: $e";
          _questionCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  void _confirmStartExam() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Start Exam"),
        content: const Text("Are you sure you want to start this exercise?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Start"),
            onPressed: () {
              Navigator.of(context).pop();
              _startExam();
            },
          ),
        ],
      ),
    );
  }

  void _startExam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseOfflinePage(
          exerciseId: widget.exerciseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(_title, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _description,
                            style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.question_answer, color: isDarkMode ? Colors.white60 : Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                "Total Questions: $_questionCount",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text("Start Exam", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _confirmStartExam,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}