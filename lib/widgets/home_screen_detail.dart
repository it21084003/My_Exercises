import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isLoading = true;
  bool _isForked = false; // Track if exercise is forked

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
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          DocumentSnapshot userForkedExercise = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('forkedExercises')
              .doc(widget.exerciseId)
              .get();

          setState(() {
            _title = exercise['title'] ?? "Untitled Exercise";
            _description = exercise['description'] ?? "No description available.";
            _questionCount = questions.length;
            _isForked = userForkedExercise.exists; // Check if already forked
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _title = "Exercise Not Found";
          _description = "No details available.";
          _questionCount = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _title = "Error loading exercise";
        _description = "An error occurred.";
        _questionCount = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _forkExercise() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('forkedExercises')
          .doc(widget.exerciseId)
          .set({
        'exerciseId': widget.exerciseId,
        'title': _title,
        'description': _description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('exercises').doc(widget.exerciseId).update({
        'forkedBy': FieldValue.arrayUnion([currentUser.uid]),
        'downloadedCount': FieldValue.increment(1), // Increment download count
      });

      setState(() {
        _isForked = true;
      });

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Exercise forked successfully!"), backgroundColor: Colors.green),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error forking exercise: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmStartExam() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Start Exam"),
        content: const Text("Are you sure you want to start this exam?"),
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
        builder: (context) => ExercisePage(
          exerciseNumber: widget.exerciseId,
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
        actions: [
          // Fork Button
          IconButton(
            icon: Icon(
              _isForked ? Icons.check_circle : Icons.download_for_offline,
              color: _isForked ? Colors.green : Colors.blue,
            ),
            onPressed: _isForked ? null : _forkExercise,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Exam Info Card
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
                    // Exercise Title
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Exercise Description
                    Text(
                      _description,
                      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Total Questions
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

            // Start Exam Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.deepOrange : Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'Start Exam',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _confirmStartExam,
              ),
            ),
          ],
        ),
      ),
    );
  }
}