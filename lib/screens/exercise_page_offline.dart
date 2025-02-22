import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/offline_database_helper.dart';
import '../models/question_model.dart';
import 'result_page_offline.dart';

class ExercisePageOffline extends StatefulWidget {
  final String exerciseId;

  const ExercisePageOffline({super.key, required this.exerciseId});

  @override
  State<ExercisePageOffline> createState() => _ExercisePageOfflineState();
}

class _ExercisePageOfflineState extends State<ExercisePageOffline> with AutomaticKeepAliveClientMixin {
  late Future<List<Question>> _questionsFuture;
  final Map<int, String> _selectedAnswers = {};
  String _exerciseTitle = "Loading...";
  Timer? _timer;
  int _elapsedTime = 0;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _questionsFuture = _fetchQuestions();
    _fetchExerciseTitle();
    _startTimer();
  }

  Future<List<Question>> _fetchQuestions() async {
    final questionData = await DatabaseHelper.getExerciseQuestions(widget.exerciseId);
    if (questionData.isEmpty) {
      throw Exception("No questions found for this exercise in local storage.");
    }
    return questionData.map((json) => Question.fromJson(json)).toList();
  }

  Future<void> _fetchExerciseTitle() async {
    final exercises = await DatabaseHelper.getDownloadedExercises();
    final exercise = exercises.firstWhere(
      (e) => e['exerciseId'] == widget.exerciseId,
      orElse: () => {'title': 'Untitled Exercise'},
    );
    if (_isMounted && mounted) {
      setState(() {
        _exerciseTitle = exercise['title'] ?? "Untitled Exercise";
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isMounted && mounted) {
        setState(() {
          _elapsedTime++;
        });
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String minutes = (_elapsedTime ~/ 60).toString().padLeft(2, '0');
    String seconds = (_elapsedTime % 60).toString().padLeft(2, '0');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_exerciseTitle),
          leading: IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: _showCancelConfirmationDialog,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "$minutes:$seconds",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 18,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: _showFinishConfirmationDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: const Text(
                    'Finish',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator(radius: 15));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No questions available."));
            }

            final questions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${index + 1}: ${question.questionText}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (var option in ['A', 'B', 'C', 'D'])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: option,
                                  groupValue: _selectedAnswers[index],
                                  onChanged: (value) {
                                    if (_isMounted && mounted) {
                                      setState(() {
                                        _selectedAnswers[index] = value!;
                                      });
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    question.toJson()[option]!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  void _showCancelConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cancel Exercise'),
        content: const Text('Are you sure you want to cancel this exercise? Your progress will be lost.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _timer?.cancel();
              Navigator.of(context).pop();
              Navigator.pop(context);
            },
            isDestructiveAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Finish Exercise'),
        content: const Text('Are you sure you want to finish the exercise and submit your answers?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _timer?.cancel();
              Navigator.of(context).pop();
              _navigateToResultPage();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _navigateToResultPage() {
    _questionsFuture.then((questions) {
      if (_isMounted && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPageOffline(
              questions: questions,
              selectedAnswers: _selectedAnswers,
              timeTaken: _elapsedTime,
              exerciseId: widget.exerciseId,
            ),
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading results: $e")),
        );
      }
    });
  }

  @override
  bool get wantKeepAlive => true;
}