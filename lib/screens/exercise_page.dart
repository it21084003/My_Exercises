import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/firestore_service.dart';
import '../models/question_model.dart';
import '../widgets/result_page.dart';

class ExercisePage extends StatefulWidget {
  final String exerciseNumber;

  const ExercisePage({super.key, required this.exerciseNumber});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Question>> _questionsFuture;
  final Map<int, String> _selectedAnswers = {};
  String _exerciseTitle = "Loading..."; // Placeholder for exercise title

  @override
  void initState() {
    super.initState();
    _questionsFuture = _firestoreService.fetchExerciseQuestions(widget.exerciseNumber);
    _fetchExerciseTitle(); // Fetch the title of the exercise
  }

  Future<void> _fetchExerciseTitle() async {
    try {
      final exercise = await _firestoreService.getExerciseById(widget.exerciseNumber);
      if (exercise != null) {
        setState(() {
          _exerciseTitle = exercise['title'] ?? "Untitled Exercise";
        });
      }
    } catch (e) {
      print("Error fetching exercise title: $e");
      setState(() {
        _exerciseTitle = "Error loading title";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () {
            _showCancelConfirmationDialog(context);
          },
        ),
        title: Text(_exerciseTitle), // Updated to show the exercise title
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                _showFinishConfirmationDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.blue, // Blue background
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const Text(
                  'Finish',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No questions available.'),
            );
          }

          final questions = snapshot.data!;
          return ListView.builder(
            key: const PageStorageKey('exercise_list'),
            padding: const EdgeInsets.all(16.0),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q${index + 1}: ${question.questionText}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                                  setState(() {
                                    _selectedAnswers[index] = value!;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question.toJson()[option]!,
                                  style: const TextStyle(fontSize: 16),
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
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cancel Exercise'),
        content: const Text('Are you sure you want to cancel this exercise? Your progress will be lost.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: () {
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

  void _showFinishConfirmationDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Finish Exercise'),
        content: const Text('Are you sure you want to finish the exercise and submit your answers?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToResultPage(context);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _navigateToResultPage(BuildContext context) {
    _questionsFuture.then((questions) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            questions: questions,
            selectedAnswers: _selectedAnswers,
          ),
        ),
      );
    });
  }

  @override
  bool get wantKeepAlive => true;
}