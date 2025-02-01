import 'package:flutter/material.dart';
import '../data/firestore_service.dart';
import '../models/question.dart';

class ExercisePage extends StatefulWidget {
  final int exerciseNumber; // Passed from the previous screen

  const ExercisePage({super.key, required this.exerciseNumber});

  @override
  ExercisePageState createState() => ExercisePageState();
}

class ExercisePageState extends State<ExercisePage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exercise ${widget.exerciseNumber}')),
      body: FutureBuilder<List<Question>>(
        future: _firestoreService.fetchQuestions(widget.exerciseNumber), // Pass exerciseNumber
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loader
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Show error
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No questions found.')); // Show if no data exists
          }

          List<Question> questions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.questionText,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          for (var option in ['optionA', 'optionB', 'optionC', 'optionD'])
                            ListTile(
                              title: Text(question.toJson()[option]!),
                              leading: Radio(
                                value: option,
                                groupValue: null,
                                onChanged: (value) {},
                              ),
                            ),
                        ],
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
}