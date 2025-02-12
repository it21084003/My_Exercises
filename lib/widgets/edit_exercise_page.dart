import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _descriptionController = TextEditingController();
  bool _isShared = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _questions = [];
  final List<Map<String, dynamic>> _newQuestions = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 🔥 Categories
  final List<String> _allCategories = [
    'Math',
    'Science',
    'English',
    'Programming',
    'History',
    'Geography',
    'Physics',
    'Chemistry',
    'Biology',
    'Economics',
    'Arts',
    'Music'
  ];
  final Set<String> _selectedCategories = {};
  bool _isCategoryExpanded = false;
  bool _showCategoryError = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _isShared = widget.shared;
    _fetchExerciseDetails();
    _fetchQuestions();
  }

  Future<void> _fetchExerciseDetails() async {
    try {
      DocumentSnapshot exerciseDoc =
          await _firestore.collection('exercises').doc(widget.exerciseId).get();

      if (exerciseDoc.exists) {
        setState(() {
          _descriptionController.text =
              exerciseDoc['description'] ?? ''; // Load description
          _selectedCategories.addAll(
            List<String>.from(exerciseDoc['categories'] ?? []),
          );
        });
      }
    } catch (e) {
      print("Error fetching exercise details: $e");
    }
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
            'expanded': false, // To control the initial expansion state
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  Future<void> _deleteExercise() async {
    bool confirmDelete = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Exercise'),
        content: const Text(
          'Are you sure you want to delete this exercise? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true, // Makes text red for delete
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    try {
      // Delete all questions associated with this exercise
      QuerySnapshot questionSnapshot = await _firestore
          .collection('exercises')
          .doc(widget.exerciseId)
          .collection('questions')
          .get();

      for (var doc in questionSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the exercise itself
      await _firestore.collection('exercises').doc(widget.exerciseId).delete();

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Exercise deleted successfully!')),
      // );

      Navigator.pop(context);
    } catch (e) {
      print('Error deleting exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting exercise: $e')),
      );
    }
  }

  Future<void> _updateExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategories.isEmpty) {
      setState(() => _showCategoryError = true);
      return;
    }

    try {
      if (_titleController.text.isEmpty) {
        _showToast(context, 'Exercise title cannot be empty!');
        return;
      }
      if (_descriptionController.text.isEmpty) {
        _showToast(context, 'Exercise description cannot be empty!');
        return;
      }

      for (var question in [..._questions, ..._newQuestions]) {
        if (question['questionText'].isEmpty ||
            question['A'].isEmpty ||
            question['B'].isEmpty ||
            question['C'].isEmpty ||
            question['D'].isEmpty) {
          _showToast(context, 'Please fill all fields for every question.');
          return;
        }
      }

      await _firestore.collection('exercises').doc(widget.exerciseId).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'shared': _isShared,
        'categories': _selectedCategories.toList(),
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
          'correctAnswer': question['correctAnswer'].toUpperCase(),
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
          'correctAnswer': question['correctAnswer'].toUpperCase(),
        });
      }

      //_showToast(context, 'Exercise updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      print('Error updating exercise: $e');
      _showToast(context, 'Error updating exercise: $e');
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question,
      {bool isNew = false}) async {
    bool confirmDelete = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Question'),
        content: const Text(
          'Are you sure you want to delete this question?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true, // Makes text red for delete
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    if (isNew) {
      setState(() {
        _newQuestions.remove(question);
      });
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

        //_showToast(context, 'Question deleted successfully!');
      } catch (e) {
        print('Error deleting question: $e');
        _showToast(context, 'Error deleting question: $e');
      }
    }
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
        'expanded': true, // Automatically expand new questions
      });
    });
  }

  void _showToast(BuildContext context, String message) {
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

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _buildCategorySelection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _isCategoryExpanded = !_isCategoryExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Categories:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(_isCategoryExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
            ],
          ),
        ),
        if (_isCategoryExpanded)
          Wrap(
            spacing: 8,
            children: _allCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                selectedColor: isDarkMode
                    ? Colors.purpleAccent
                        .withOpacity(0.3) // Purple tint in dark mode
                    : Colors.blue, // Blue in light mode
                backgroundColor: isDarkMode
                    ? Colors.grey[850] // Dark gray background in dark mode
                    : Colors.grey[300], // Light gray background in light mode
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white // White text when selected
                      : (isDarkMode
                          ? Colors.grey[400]
                          : Colors.black), // Light gray in dark mode
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? (isDarkMode ? Colors.purpleAccent : Colors.blue)
                        : (isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                    width: isSelected
                        ? 2
                        : 1, // Slightly thicker border when selected
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                    _showCategoryError = _selectedCategories.isEmpty;
                  });
                },
              );
            }).toList(),
          ),
        if (_showCategoryError)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select at least one category!',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Exercise'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash,
                color: Colors.redAccent, size: 22),
            onPressed: _deleteExercise,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _updateExercise,
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
                decoration: const InputDecoration(labelText: 'Exercise Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Exercise title cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Exercise Description',
                  hintText: 'Enter a description for the exercise',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Exercise description cannot be empty';
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
              _buildCategorySelection(),
              const Divider(height: 24),
              ..._questions.map((question) => _buildQuestionTile(question)),
              ..._newQuestions
                  .map((question) => _buildQuestionTile(question, isNew: true)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addNewQuestion,
                child: const Text('Add New Question'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTile(Map<String, dynamic> question,
      {bool isNew = false}) {
    return ExpansionTile(
      initiallyExpanded: question['expanded'] ?? false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              question['questionText'].isEmpty
                  ? 'New Question'
                  : question['questionText'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _deleteQuestion(question, isNew: isNew),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                CupertinoIcons.trash_fill, // Trash bin icon (more modern)
                color: Colors.redAccent, // Vibrant red color
                size: 22, // Slightly larger for better visibility
              ),
            ),
          ),
        ],
      ),
      children: [_buildQuestionFields(question)],
    );
  }

  Widget _buildQuestionFields(Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            initialValue: question['questionText'],
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Question Text',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => question['questionText'] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Question text cannot be empty';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['A'],
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Option A',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => question['A'] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Option A cannot be empty';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['B'],
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Option B',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => question['B'] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Option B cannot be empty';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['C'],
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Option C',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => question['C'] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Option C cannot be empty';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['D'],
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Option D',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => question['D'] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Option D cannot be empty';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['correctAnswer'],
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Correct Answer (A, B, C, or D)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                question['correctAnswer'] = value.toUpperCase(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Correct answer cannot be empty';
              }
              if (!['A', 'B', 'C', 'D'].contains(value.toUpperCase())) {
                return 'Correct answer must be one of: A, B, C, or D';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
