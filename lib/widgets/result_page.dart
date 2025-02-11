import 'package:flutter/material.dart';
import '../models/question_model.dart';
import 'package:my_exercises/widgets/my_exercises_screen.dart';

class ResultPage extends StatelessWidget {
  final List<Question> questions;
  final Map<int, String> selectedAnswers;
  final int timeTaken; // ⏳ Time taken parameter

  const ResultPage({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.timeTaken,
  });

  @override
  Widget build(BuildContext context) {
    int score = 0;

    // ✅ Calculate score
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i]?.trim() == questions[i].correctAnswer.trim()) {
        score++;
      }
    }

    // ✅ Convert time to minutes and seconds format
    String minutes = (timeTaken ~/ 60).toString().padLeft(2, '0');
    String seconds = (timeTaken % 60).toString().padLeft(2, '0');

    return WillPopScope(
      onWillPop: () async => false, // ❌ Prevent back swipe navigation
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // ❌ Removes back button
          title: const Text('Results'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // 🔴 Exit button color
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

              // ⏳ Time Taken Display
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

                            // ✅ Display answer choices with icons
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