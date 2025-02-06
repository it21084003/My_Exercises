import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/firestore_service.dart';
import '../screens/exercise_page.dart';

class HomeScreenDetail extends StatefulWidget {
  final String exerciseId;

  const HomeScreenDetail({super.key, required this.exerciseId});

  @override
  State<HomeScreenDetail> createState() => _HomeScreenDetailState();
}

class _HomeScreenDetailState extends State<HomeScreenDetail> {
  final FirestoreService _firestoreService = FirestoreService();
  String _title = "Loading...";
  String _description = "Fetching details...";
  int _questionCount = 0;
  List<String> _questionTexts = [];

  @override
  void initState() {
    super.initState();
    _fetchExerciseDetails();
  }

  Future<void> _fetchExerciseDetails() async {
    try {
      final exercise = await _firestoreService.getExerciseById(widget.exerciseId);
      if (exercise != null) {
        final questions = await _firestoreService.fetchExerciseQuestions(widget.exerciseId);
        setState(() {
          _title = exercise['title'] ?? "Untitled Exercise";
          _description = exercise['description'] ?? "No description available.";
          _questionCount = questions.length;
          _questionTexts = questions.map((q) => q.questionText).toList();
        });
      } else {
        setState(() {
          _title = "Exercise Not Found";
          _description = "No details available.";
          _questionCount = 0;
          _questionTexts = [];
        });
      }
    } catch (e) {
      setState(() {
        _title = "Error loading exercise";
        _description = "An error occurred.";
        _questionCount = 0;
        _questionTexts = [];
      });
    }
  }

  void _showStartExamConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Start Exam"),
        content: const Text("Are you sure you want to start this exam?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(), // Close popup
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Start"),
            onPressed: () {
              Navigator.of(context).pop(); // Close popup
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
        builder: (context) => ExercisePage(
          exerciseNumber: widget.exerciseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Title
            Text(
              _title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Exercise Description
            Text(
              _description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Number of Questions
            Text(
              "Total Questions: $_questionCount",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Displaying Numbered Question Texts
            _questionTexts.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _questionTexts
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(
                              "${entry.key + 1}. ${entry.value}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                        .toList(),
                  )
                : const Text(
                    "",
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),

            const SizedBox(height: 30),

            // Start Exam Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _questionCount > 0 ? _showStartExamConfirmation : null,
                child: const Text(
                  'Start Exam',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}