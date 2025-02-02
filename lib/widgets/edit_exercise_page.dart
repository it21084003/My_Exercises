import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditExercisePage extends StatefulWidget {
  final String exerciseId;
  final String title;
  final bool shared;

  const EditExercisePage({
    super.key,
    required this.exerciseId,
    required this.title,
    required this.shared,
  });

  @override
  State<EditExercisePage> createState() => _EditExercisePageState();
}

class _EditExercisePageState extends State<EditExercisePage> {
  final TextEditingController _titleController = TextEditingController();
  bool _isShared = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _newQuestions = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _isShared = widget.shared;
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('exercises')
          .doc(widget.exerciseId)
          .collection('questions')
          .get();

      setState(() {
        _questions = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'questionText': doc['questionText'],
            'A': doc['A'],
            'B': doc['B'],
            'C': doc['C'],
            'D': doc['D'],
            'correctAnswer': doc['correctAnswer'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  Future<void> _updateExercise() async {
    try {
      if (_titleController.text.isEmpty) {
        showIOSToast(context, 'Exercise title cannot be empty!');
        return;
      }

      // Validate questions
      for (var question in [..._questions, ..._newQuestions]) {
        if (question['questionText'].isEmpty ||
            question['A'].isEmpty ||
            question['B'].isEmpty ||
            question['C'].isEmpty ||
            question['D'].isEmpty ||
            question['correctAnswer'].isEmpty) {
          showIOSToast(context, 'Please fill all fields for every question.');
          return;
        }
      }

      await _firestore.collection('exercises').doc(widget.exerciseId).update({
        'title': _titleController.text,
        'shared': _isShared,
      });

      for (var question in _questions) {
        await _firestore
            .collection('exercises')
            .doc(widget.exerciseId)
            .collection('questions')
            .doc(question['id'])
            .update({
          'questionText': question['questionText'],
          'A': question['A'],
          'B': question['B'],
          'C': question['C'],
          'D': question['D'],
          'correctAnswer': question['correctAnswer'],
        });
      }

      for (var question in _newQuestions) {
        await _firestore
            .collection('exercises')
            .doc(widget.exerciseId)
            .collection('questions')
            .add({
          'questionText': question['questionText'],
          'A': question['A'],
          'B': question['B'],
          'C': question['C'],
          'D': question['D'],
          'correctAnswer': question['correctAnswer'],
        });
      }

      showIOSToast(context, 'Exercise updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      print('Error updating exercise: $e');
      showIOSToast(context, 'Error updating exercise: $e');
    }
  }

  Future<void> _deleteExercise() async {
    bool confirmDelete = await _showIOSDeleteDialog(
      context,
      'Delete Exercise',
      'Are you sure you want to delete this exercise?',
    );

    if (!confirmDelete) return;

    try {
      QuerySnapshot questionSnapshot = await _firestore
          .collection('exercises')
          .doc(widget.exerciseId)
          .collection('questions')
          .get();

      for (var doc in questionSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('exercises').doc(widget.exerciseId).delete();

      showIOSToast(context, 'Exercise deleted successfully!');
      Navigator.pop(context);
    } catch (e) {
      print('Error deleting exercise: $e');
      showIOSToast(context, 'Error deleting exercise: $e');
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question, {bool isNew = false}) async {
    bool confirmDelete = await _showIOSDeleteDialog(
      context,
      'Delete Question',
      'Are you sure you want to delete this question?',
    );

    if (!confirmDelete) return;

    if (isNew) {
      setState(() {
        _newQuestions.remove(question);
      });
      showIOSToast(context, 'Question deleted successfully!');
    } else {
      try {
        await _firestore
            .collection('exercises')
            .doc(widget.exerciseId)
            .collection('questions')
            .doc(question['id'])
            .delete();

        setState(() {
          _questions.remove(question);
        });

        showIOSToast(context, 'Question deleted successfully!');
      } catch (e) {
        print('Error deleting question: $e');
        showIOSToast(context, 'Error deleting question: $e');
      }
    }
  }

  Future<bool> _showIOSDeleteDialog(
      BuildContext context, String title, String message) async {
    return await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _addNewQuestion() {
    setState(() {
      _newQuestions.add({
        'questionText': '',
        'A': '',
        'B': '',
        'C': '',
        'D': '',
        'correctAnswer': '',
      });
    });
  }

  void showIOSToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateExercise,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteExercise,
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
            const Text(
              'Edit Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ..._questions.map((question) {
              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      question['questionText'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteQuestion(question),
                    ),
                  ],
                ),
                children: [_buildQuestionFields(question)],
              );
            }).toList(),
            ..._newQuestions.map((question) {
              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Question',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteQuestion(question, isNew: true),
                    ),
                  ],
                ),
                children: [_buildQuestionFields(question)],
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addNewQuestion,
              child: const Text('Add New Question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionFields(Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Question Text',
              border: const OutlineInputBorder(),
              errorText:
                  question['questionText'].isEmpty ? 'This field is required' : null,
            ),
            maxLines: null,
            onChanged: (value) => question['questionText'] = value,
            controller: TextEditingController(text: question['questionText']),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: 'Option A',
              border: const OutlineInputBorder(),
              errorText: question['A'].isEmpty ? 'This field is required' : null,
            ),
            maxLines: null,
            onChanged: (value) => question['A'] = value,
            controller: TextEditingController(text: question['A']),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: 'Option B',
              border: const OutlineInputBorder(),
              errorText: question['B'].isEmpty ? 'This field is required' : null,
            ),
            maxLines: null,
            onChanged: (value) => question['B'] = value,
            controller: TextEditingController(text: question['B']),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: 'Option C',
              border: const OutlineInputBorder(),
              errorText: question['C'].isEmpty ? 'This field is required' : null,
            ),
            maxLines: null,
            onChanged: (value) => question['C'] = value,
            controller: TextEditingController(text: question['C']),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: 'Option D',
              border: const OutlineInputBorder(),
              errorText: question['D'].isEmpty ? 'This field is required' : null,
            ),
            maxLines: null,
            onChanged: (value) => question['D'] = value,
            controller: TextEditingController(text: question['D']),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: 'Correct Answer (A, B, C, or D)',
              border: const OutlineInputBorder(),
              errorText: question['correctAnswer'].isEmpty
                  ? 'This field is required'
                  : null,
            ),
            maxLines: 1,
            onChanged: (value) => question['correctAnswer'] = value.toUpperCase(),
            controller: TextEditingController(text: question['correctAnswer']),
          ),
        ],
      ),
    );
  }
}