import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_exercises/widgets/exercises/downloaded_exercises_widget.dart';
import '../../data/firestore_service.dart';
import '../../data/offline_database_helper.dart';
import '../exercises/exercise_online_page.dart';
import 'package:flutter/animation.dart';

class HomeScreenDetailOnline extends StatefulWidget {
  final String exerciseId;

  const HomeScreenDetailOnline({super.key, required this.exerciseId});

  @override
  State<HomeScreenDetailOnline> createState() => _HomeScreenDetailOnlineState();
}

class _HomeScreenDetailOnlineState extends State<HomeScreenDetailOnline> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  String _title = "Loading...";
  String _description = "Fetching details...";
  int _questionCount = 0;
  bool _isLoading = true;
  bool _isForked = false;
  bool _isDownloaded = false;
  bool? _isCreatedByCurrentUser;

  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;

  late AnimationController _snackAnimationController;
  late Animation<double> _snackAnimation;

  @override
  void initState() {
    super.initState();
    _fetchExerciseDetails();
    _checkIfDownloaded();

    // Animation setup for card (fade-in)
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeInOut);
    _cardAnimationController.forward();

    // Animation setup for SnackBar (fade-in)
    _snackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _snackAnimation = CurvedAnimation(parent: _snackAnimationController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _snackAnimationController.dispose();
    super.dispose();
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

          if (mounted) {
            setState(() {
              _title = exercise['title'] ?? "Untitled Exercise";
              _description = exercise['description'] ?? "No description available.";
              _questionCount = questions.length;
              _isForked = userForkedExercise.exists;
              _isCreatedByCurrentUser = exercise['creatorId'] == currentUser.uid;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _title = "Exercise Not Found";
            _description = "No details available.";
            _questionCount = 0;
            _isLoading = false;
          });
        }
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

  Future<void> _checkIfDownloaded() async {
    bool isDownloaded = await DatabaseHelper.isDownloaded(widget.exerciseId);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  Future<void> _downloadExercise() async {
    debugPrint("Starting download for exercise ID: ${widget.exerciseId}");
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
      try {
        final questions = await _firestoreService.fetchExerciseQuestions(widget.exerciseId);
        final questionData = questions.map((q) => q.toJson()).toList();

        debugPrint("Saving exercise and questions to SQLite: Title = $_title, Questions = ${questionData.length}");
        await DatabaseHelper.saveDownloadedExercise({
          'exerciseId': widget.exerciseId,
          'title': _title,
          'description': _description,
          'totalQuestions': _questionCount,
        }, questionData);

        if (mounted) {
          setState(() {
            _isDownloaded = true;
          });
          // Show compact animated gradient SnackBar
          _snackAnimationController.forward(from: 0); // Trigger animation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4), // Reduced duration for compactness
              backgroundColor: Colors.transparent, // Transparent to show gradient
              content: FadeTransition(
                opacity: _snackAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Reduced padding
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // Smaller radius
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [Colors.blueGrey[900]!, Colors.blueGrey[700]!] // Dark mode
                          : [Colors.blue[100]!, Colors.blue[300]!], // Light mode
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Ensures content fits tightly
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Download successful!",
                        style: TextStyle(
                          fontSize: 14, // Smaller font size
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DownloadedExercisesWidget()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Smaller padding
                          minimumSize: Size.zero, // Removes default minimum size
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrinks to content
                        ),
                        child: Text(
                          "View Downloads",
                          style: TextStyle(
                            fontSize: 12, // Smaller font size
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          debugPrint("Download completed, showing compact animated SnackBar with action");
        }
      } catch (e) {
        debugPrint("Error downloading exercise: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error downloading exercise: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    } else {
      debugPrint("Download cancelled by user");
    }
  }

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

      await FirebaseFirestore.instance
          .collection('exercises')
          .doc(widget.exerciseId)
          .update({
        'forkedBy': FieldValue.arrayUnion([currentUser.uid]),
        'downloadedCount': FieldValue.increment(1),
      });

      if (mounted) {
        setState(() {
          _isForked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error forking exercise: $e"),
              backgroundColor: Colors.red),
        );
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
        builder: (context) => ExerciseOnlinePage(
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
        title: Text(_title,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 2,
        actions: _isCreatedByCurrentUser == null
            ? []
            : _isCreatedByCurrentUser == true
                ? []
                : [
                    IconButton(
                      icon: Icon(
                        _isForked ? Icons.star : Icons.fork_right,
                        color: _isForked
                            ? const Color.fromARGB(255, 52, 163, 46)
                            : Colors.blue,
                      ),
                      onPressed: _isForked ? null : _forkExercise,
                      tooltip: 'Fork Exercise',
                    ),
                    if (!_isDownloaded)
                      IconButton(
                        icon: Icon(
                          _isDownloaded
                              ? Icons.check_circle
                              : Icons.cloud_download,
                          color: _isDownloaded ? Colors.green : Colors.blue,
                        ),
                        onPressed: _downloadExercise,
                        tooltip: 'Download Exercise',
                      ),
                  ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Animated Card with Gradient
                  FadeTransition(
                    opacity: _cardAnimation,
                    child: Card(
                      elevation: 8, // Increased elevation for shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20), // Larger radius for modern look
                      ),
                      color: Colors.transparent, // Transparent to show gradient
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [
                                    Colors.blueGrey[900]!,
                                    Colors.blueGrey[700]!
                                  ] // Dark mode gradient
                                : [
                                    Colors.blue[100]!,
                                    Colors.blue[300]!
                                  ], // Light mode gradient
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                              20.0), // Increased padding for breathing room
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: TextStyle(
                                  fontSize: 24, // Larger title for emphasis
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _description,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  height: 1.5, // Better line spacing
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Icon(Icons.question_answer,
                                      color: isDarkMode
                                          ? Colors.white60
                                          : Colors.black54,
                                      size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Total Questions: $_questionCount",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24), // Larger padding
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // More rounded corners
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 24),
                      label: const Text(
                        "Start Exam",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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