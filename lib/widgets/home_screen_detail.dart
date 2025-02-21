import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firestore_service.dart';
import '../data/offline_database_helper.dart';
import '../screens/exercise_page.dart';
import '../widgets/my_exercises.dart'; // Import for potential navigation (optional)

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
  bool _isDownloaded = false; // ✅ Track if exercise is downloaded (SQLite)
  bool? _isCreatedByCurrentUser; // Track if the current user created this exercise

  @override
  void initState() {
    super.initState();
    _fetchExerciseDetails();
    _checkIfDownloaded(); // ✅ Check if exercise is stored locally
  }

  /// ✅ Fetch exercise details from Firestore and check if created by current user
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
            _isCreatedByCurrentUser = exercise['creatorId'] == currentUser.uid; // Check if current user created this exercise
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

  /// ✅ Check if exercise is downloaded (SQLite)
  Future<void> _checkIfDownloaded() async {
    bool isDownloaded = await DatabaseHelper.isDownloaded(widget.exerciseId);
    setState(() {
      _isDownloaded = isDownloaded;
    });
  }

  /// ✅ Save exercise to local storage (Download) and navigate to MyExercises
  Future<void> _downloadExercise() async {
    // Show confirmation dialog
    bool confirm = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Download Exercise"),
        content: const Text("Are you sure you want to download this exercise?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Download"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.saveDownloadedExercise({
        'exerciseId': widget.exerciseId,
        'title': _title,
        'description': _description,
        'totalQuestions': _questionCount,
      });

      setState(() {
        _isDownloaded = true;
      });

      // Navigate to MyExercises to show downloaded exercises
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyExercises()),
      );
    }
  }

  /// ✅ Fork Exercise (Save to Firestore) - Only if not created by current user
  Future<void> _forkExercise() async {
    if (_isCreatedByCurrentUser == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot fork your own exercise."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        'downloadedCount': FieldValue.increment(1),
      });

      setState(() {
        _isForked = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error forking exercise: $e"), backgroundColor: Colors.red),
      );
    }
  }

  /// ✅ Confirm before starting exam
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
        // Conditionally show actions only after _isCreatedByCurrentUser is determined
        actions: _isCreatedByCurrentUser == null
            ? [] // Show no icons during loading to prevent flicker
            : _isCreatedByCurrentUser == true
                ? [] // Hide all icons if created by current user
                : [
                    // Show icons only if not created by current user
                    IconButton(
                      icon: Icon(
                        _isForked ? Icons.star : Icons.fork_right, // Changed to Icons.star when forked
                        color: _isForked ? const Color.fromARGB(255, 52, 163, 46) : Colors.blue, // Changed color to yellow for star
                      ),
                      onPressed: _isForked ? null : _forkExercise,
                      tooltip: 'Fork Exercise', // Add tooltip for clarity
                    ),
                    // Show download icon only if not downloaded, hide if downloaded
                    if (!_isDownloaded)
                      IconButton(
                        icon: Icon(
                          _isDownloaded ? Icons.check_circle : Icons.cloud_download, // Use cloud_download for downloading
                          color: _isDownloaded ? Colors.green : Colors.blue,
                        ),
                        onPressed: _downloadExercise,
                        tooltip: 'Download Exercise', // Add tooltip for clarity
                      ),
                  ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : Padding(
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