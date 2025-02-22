import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../data/firestore_service.dart';
import '../../models/question_model.dart';
import '../results/result_online_page.dart';

class ExerciseOnlinePage extends StatefulWidget {
  final String exerciseNumber;

  const ExerciseOnlinePage({super.key, required this.exerciseNumber});

  @override
  State<ExerciseOnlinePage> createState() => _ExerciseOnlinePageState();
}

class _ExerciseOnlinePageState extends State<ExerciseOnlinePage> with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
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
    _questionsFuture = _firestoreService.fetchExerciseQuestions(widget.exerciseNumber);
    _fetchExerciseTitle();
    _startTimer();
  }

  Future<void> _fetchExerciseTitle() async {
    try {
      final exercise = await _firestoreService.getExerciseById(widget.exerciseNumber);
      if (_isMounted && mounted) {
        setState(() {
          _exerciseTitle = exercise?['title'] ?? "Untitled Exercise";
        });
      }
    } catch (e) {
      if (_isMounted && mounted) {
        setState(() {
          _exerciseTitle = "Error loading title";
        });
      }
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
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
            builder: (context) => ResultOnlinePage(
              questions: questions,
              selectedAnswers: _selectedAnswers,
              timeTaken: _elapsedTime,
              exerciseId: widget.exerciseNumber,
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