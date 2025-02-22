import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';

class ResultPageOnline extends StatelessWidget {
  final List<Question> questions;
  final Map<int, String> selectedAnswers;
  final int timeTaken;
  final String exerciseId;

  const ResultPageOnline({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.timeTaken,
    required this.exerciseId,
  });

  Future<Map<String, dynamic>> _updateUserPoints() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      const int pointsPerExercise = 10;
      try {
        DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        DocumentSnapshot snapshot = await userDoc.get();

        List<String> completedExercises = List<String>.from(snapshot['completed_exercises'] ?? []);
        if (completedExercises.contains(exerciseId)) {
          return {
            'points': 0,
            'message': 'Points are awarded only once for this exercise.',
          };
        }

        int currentPoints = snapshot['points'] ?? 0;
        int newPoints = currentPoints + pointsPerExercise;
        String newLevel = _calculateLevel(newPoints);
        List<String> currentBadges = List<String>.from(snapshot['badges'] ?? []);
        List<String> newBadges = _checkForBadges(newPoints, currentBadges);
        completedExercises.add(exerciseId);

        await userDoc.update({
          'points': newPoints,
          'level': newLevel,
          'badges': newBadges,
          'completed_exercises': completedExercises,
        });
        return {
          'points': pointsPerExercise,
          'message': 'Points earned for first-time completion!',
        };
      } catch (e) {
        return {
          'points': 0,
          'message': 'Error updating points: $e',
        };
      }
    }
    return {
      'points': 0,
      'message': 'User not logged in.',
    };
  }

  String _calculateLevel(int points) {
    if (points >= 700) return 'Master';
    if (points >= 300) return 'Expert';
    return 'Beginner';
  }

  List<String> _checkForBadges(int points, List<String> currentBadges) {
    if (points >= 100 && !currentBadges.contains('First 100 Points')) {
      currentBadges.add('First 100 Points');
    }
    if (points >= 300 && !currentBadges.contains('300 Point Champion')) {
      currentBadges.add('300 Point Champion');
    }
    return currentBadges;
  }

  @override
  Widget build(BuildContext context) {
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i]?.trim() == questions[i].correctAnswer.trim()) {
        score++;
      }
    }

    String minutes = (timeTaken ~/ 60).toString().padLeft(2, '0');
    String seconds = (timeTaken % 60).toString().padLeft(2, '0');

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Results'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Score: $score / ${questions.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<Map<String, dynamic>>(
                future: _updateUserPoints(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Calculating points...',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    );
                  }
                  int pointsEarned = snapshot.data?['points'] ?? 0;
                  String message = snapshot.data?['message'] ?? 'Error loading points';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points Earned: $pointsEarned',
                        style: const TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Time Taken: $minutes:$seconds',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final selectedAnswer = selectedAnswers[index];
                    final correctAnswer = question.correctAnswer;

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
                            Column(
                              children: ['A', 'B', 'C', 'D'].map((option) {
                                bool isCorrect = option == correctAnswer;
                                bool isSelected = option == selectedAnswer;
                                bool isWrong = isSelected && !isCorrect;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCorrect
                                            ? Icons.check_circle
                                            : isWrong
                                                ? Icons.cancel
                                                : Icons.circle_outlined,
                                        color: isCorrect
                                            ? Colors.green
                                            : isWrong
                                                ? Colors.red
                                                : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          question.toJson()[option]!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isCorrect
                                                ? Colors.green
                                                : isWrong
                                                    ? Colors.red
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}