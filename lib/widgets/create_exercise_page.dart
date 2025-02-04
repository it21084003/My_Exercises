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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  final List<Map<String, dynamic>> _questions = [];
  bool _isShared = false; // Default shared status
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _addQuestion() {
    setState(() {
      _questions.add({
        'questionText': '',
        'A': '',
        'B': '',
        'C': '',
        'D': '',
        'correctAnswer': '',
        'expanded': true, // Auto-expand new questions
      });
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_titleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title and at least one question.')),
      );
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in.');

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc['username'] ?? user.email;

      final exerciseDoc = await _firestore.collection('exercises').add({
        'title': _titleController.text,
        'creator': user.email,
        'username': username,
        'shared': _isShared,
        'timestamp': Timestamp.now(),
      });

      for (var question in _questions) {
        await exerciseDoc.collection('questions').add({
          'questionText': question['questionText'],
          'A': question['A'],
          'B': question['B'],
          'C': question['C'],
          'D': question['D'],
          'correctAnswer': question['correctAnswer'].toUpperCase(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise created successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving exercise: $e')),
      );
    }
  }

  Widget _buildQuestionTile(Map<String, dynamic> question, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        initiallyExpanded: question['expanded'] ?? false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                question['questionText'].isEmpty ? 'New Question' : question['questionText'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteQuestion(index),
            ),
          ],
        ),
        children: [_buildQuestionFields(question)],
      ),
    );
  }

  Widget _buildQuestionFields(Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTextField(label: 'Question Text', questionKey: 'questionText', question: question),
          const SizedBox(height: 8),
          _buildTextField(label: 'Option A', questionKey: 'A', question: question),
          const SizedBox(height: 8),
          _buildTextField(label: 'Option B', questionKey: 'B', question: question),
          const SizedBox(height: 8),
          _buildTextField(label: 'Option C', questionKey: 'C', question: question),
          const SizedBox(height: 8),
          _buildTextField(label: 'Option D', questionKey: 'D', question: question),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: question['correctAnswer'],
            maxLines: 1,
            decoration: const InputDecoration(
              labelText: 'Correct Answer (A, B, C, or D)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                question['correctAnswer'] = value.toUpperCase();
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Correct answer cannot be empty';
              }
              if (!['A', 'B', 'C', 'D'].contains(value.toUpperCase())) {
                return 'Correct answer must be A, B, C, or D';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String questionKey,
    required Map<String, dynamic> question,
  }) {
    return TextFormField(
      initialValue: question[questionKey],
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() {
        question[questionKey] = value;
      }),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label cannot be empty';
        }
        return null;
      },
    );
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
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Exercise title cannot be empty';
                  }
                  return null;
                },
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
              ..._questions.asMap().entries.map((entry) => _buildQuestionTile(entry.value, entry.key)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addQuestion,
                child: const Text('Add New Question'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}