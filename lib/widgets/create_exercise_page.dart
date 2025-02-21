import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_exercises/data/auth_service.dart';

class CreateExercisePage extends StatefulWidget {
  const CreateExercisePage({super.key});

  @override
  State<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController(); // Add description controller
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  final List<Map<String, dynamic>> _questions = [];
  bool _isShared = false; // Default shared status
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showQuestionError = false; // To control red border for the button
  bool _showCategoryError = false;

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
      _showQuestionError = false; // Remove error when a question is added
    });
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      setState(() => _showCategoryError = true);
      return;
    } else {
      setState(() => _showCategoryError = false);
    }

    if (_questions.isEmpty) {
      setState(() {
        _showQuestionError = true; // Show red border on the button
      });
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in.');

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc['username'] ?? user.email;

      final exerciseDoc = await _firestore.collection('exercises').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'creatorId': user.uid,
        'creatorUsername': username,
        'downloadedCount': 0,
        'shared': _isShared,
        'categories': _selectedCategories.toList(), // 🔥 Now saving categories
        'timestamp': Timestamp.now(),
      });

      for (var question in _questions) {
        await exerciseDoc.collection('questions').add({
          'questionText': question['questionText'].trim(),
          'A': question['A'].trim(),
          'B': question['B'].trim(),
          'C': question['C'].trim(),
          'D': question['D'].trim(),
          'correctAnswer': question['correctAnswer'].toUpperCase().trim(),
        });
      }

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Exercise created successfully!')),
      // );

      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving exercise: $e')),
      );
    }
  }

 Widget _buildCategorySelection() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
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
          runSpacing: 8,
          children: _allCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              selectedColor: isDarkMode
                  ? Colors.purpleAccent.withOpacity(0.3) // Purple tint in dark mode
                  : Colors.blue, // Blue in light mode
              backgroundColor: isDarkMode
                  ? Colors.grey[850] // Dark gray background in dark mode
                  : Colors.grey[300], // Light gray background in light mode
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white // White text when selected
                    : (isDarkMode ? Colors.grey[400] : Colors.black), // Light gray in dark mode
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? (isDarkMode ? Colors.purpleAccent : Colors.blue)
                      : (isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                  width: isSelected ? 2 : 1, // Slightly thicker border when selected
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

  Widget _buildShareToggle() {
    return Row(
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
    );
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
                question['questionText'].isEmpty
                    ? 'New Question'
                    : question['questionText'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 22),
              onPressed: () {
                setState(() {
                  _questions.removeAt(index);
                });
              },
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
          _buildTextField(
              label: 'Question Text',
              questionKey: 'questionText',
              question: question),
          const SizedBox(height: 8),
          _buildTextField(
              label: 'Option A', questionKey: 'A', question: question),
          const SizedBox(height: 8),
          _buildTextField(
              label: 'Option B', questionKey: 'B', question: question),
          const SizedBox(height: 8),
          _buildTextField(
              label: 'Option C', questionKey: 'C', question: question),
          const SizedBox(height: 8),
          _buildTextField(
              label: 'Option D', questionKey: 'D', question: question),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: question['correctAnswer'],
            maxLines: 1,
            decoration: const InputDecoration(
              labelText: 'Correct Answer (A, B, C, or D)',
              hintText: 'Enter A, B, C, or D',
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
            icon: const Icon(Icons.save_alt_outlined),
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
              TextFormField(
                controller: _descriptionController,
                maxLines: null, // 🔥 Allows auto-expanding
                keyboardType:
                    TextInputType.multiline, // 🔥 Enables multiline input
                decoration: const InputDecoration(
                  labelText: 'Exercise Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Exercise description cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildShareToggle(),
              const Divider(height: 20),
              _buildCategorySelection(),
              const Divider(height: 20),
              ..._questions
                  .asMap()
                  .entries
                  .map((entry) => _buildQuestionTile(entry.value, entry.key)),
              const SizedBox(height: 16),
              Column(
                children: [
                  Container(
                    width: double.infinity, // Make the button full-width
                    decoration: BoxDecoration(
                      border: _showQuestionError
                          ? Border.all(color: Colors.red, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ElevatedButton(
                      onPressed: _addQuestion,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12), // Adjust height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text('Add New Question',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  if (_showQuestionError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Please add at least one question.',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}