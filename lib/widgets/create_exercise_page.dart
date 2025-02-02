import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/auth_service.dart';

class CreateExercisePage extends StatefulWidget {
  const CreateExercisePage({super.key});

  @override
  State<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _questionTextController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();

  final List<Map<String, dynamic>> _questions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  bool _isShared = false; // Default shared status

  void _addQuestion() {
    if (_questionTextController.text.isEmpty ||
        _optionAController.text.isEmpty ||
        _optionBController.text.isEmpty ||
        _optionCController.text.isEmpty ||
        _optionDController.text.isEmpty ||
        _correctAnswerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields for the question.')),
      );
      return;
    }

    final correctAnswer = _correctAnswerController.text.toUpperCase().trim();
    if (correctAnswer.length != 1 ||
        !['A', 'B', 'C', 'D'].contains(correctAnswer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Correct answer must be one of: A, B, C, or D.')),
      );
      return;
    }

    final answerMapping = {
      'A': 'optionA',
      'B': 'optionB',
      'C': 'optionC',
      'D': 'optionD',
    };

    final formattedAnswer = answerMapping[_correctAnswerController.text];

    _questions.add({
      'questionText': _questionTextController.text,
      'optionA': _optionAController.text,
      'optionB': _optionBController.text,
      'optionC': _optionCController.text,
      'optionD': _optionDController.text,
      'correctAnswer': formattedAnswer,
    });

    _questionTextController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _correctAnswerController.clear();

    setState(() {});
  }

  Future<void> _saveExercise() async {
    if (_titleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a title and at least one question.')),
      );
      return;
    }

    try {
      final user = _authService.currentUser;

      if (user == null) {
        throw Exception('User not logged in.');
      }

      // Add the exercise
      final exerciseDoc = await _firestore.collection('exercises').add({
        'title': _titleController.text,
        'creator': user.email,
        'shared': _isShared, // Use the shared status from the toggle
        'timestamp': Timestamp.now(),
      });

      // Add questions as a sub-collection
      for (var question in _questions) {
        await exerciseDoc.collection('questions').add(question);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving exercise: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveExercise,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Exercise Title'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Exercise',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isShared,
                  onChanged: (value) {
                    setState(() {
                      _isShared = value;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Add Question',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _questionTextController,
              decoration: const InputDecoration(labelText: 'Question Text'),
            ),
            TextField(
              controller: _optionAController,
              decoration: const InputDecoration(labelText: 'Option A'),
            ),
            TextField(
              controller: _optionBController,
              decoration: const InputDecoration(labelText: 'Option B'),
            ),
            TextField(
              controller: _optionCController,
              decoration: const InputDecoration(labelText: 'Option C'),
            ),
            TextField(
              controller: _optionDController,
              decoration: const InputDecoration(labelText: 'Option D'),
            ),
            TextField(
              controller: _correctAnswerController,
              decoration: const InputDecoration(
                  labelText: 'Correct Answer (e.g., optionA)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addQuestion,
              child: const Text('Add Question'),
            ),
            const SizedBox(height: 16),
            const Text('Questions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._questions.map((q) => ListTile(
                  title: Text(q['questionText']),
                  subtitle: Text(
                      'A: ${q['optionA']}, B: ${q['optionB']}, C: ${q['optionC']}, D: ${q['optionD']}'),
                )),
          ],
        ),
      ),
    );
  }
}
