import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_exercises/data/auth_service.dart';

class EditExerciseWidget extends StatefulWidget {
  final String exerciseId;
  final String title;
  final bool shared;

  const EditExerciseWidget({
    super.key,
    required this.exerciseId,
    required this.title,
    required this.shared,
  });

  @override
  State<EditExerciseWidget> createState() => _EditExerciseWidgetState();
}

class _EditExerciseWidgetState extends State<EditExerciseWidget> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isShared = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _questions = [];
  final List<Map<String, dynamic>> _newQuestions = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  late AnimationController _snackAnimationController;
  late Animation<double> _snackAnimation;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _isShared = widget.shared;
    _fetchExerciseDetails();
    _fetchQuestions();

    _snackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _snackAnimation = CurvedAnimation(parent: _snackAnimationController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _snackAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchExerciseDetails() async {
    try {
      DocumentSnapshot exerciseDoc = await _firestore.collection('exercises').doc(widget.exerciseId).get();

      if (exerciseDoc.exists) {
        setState(() {
          _descriptionController.text = exerciseDoc['description'] ?? '';
          _selectedCategories.addAll(List<String>.from(exerciseDoc['categories'] ?? []));
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
            'expanded': false,
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
        content: const Text('Are you sure you want to delete this exercise? This action cannot be undone.'),
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
    );

    if (confirmDelete != true) return;

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

      if (mounted) {
        _snackAnimationController.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.transparent,
            content: FadeTransition(
              opacity: _snackAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [Colors.blueGrey[900]!, Colors.blueGrey[700]!]
                        : [Colors.red[100]!, Colors.red[300]!], // Red gradient for delete (to indicate action)
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Exercise deleted successfully!",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        debugPrint("Exercise deleted, showing compact animated SnackBar");
      }

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

      if (mounted) {
        _snackAnimationController.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.transparent,
            content: FadeTransition(
              opacity: _snackAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [Colors.blueGrey[900]!, Colors.blueGrey[700]!]
                        : [Colors.green[100]!, Colors.green[300]!], // Green gradient for success
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Exercise updated successfully!",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        debugPrint("Exercise updated, showing compact animated SnackBar");
      }

      Navigator.pop(context);
    } catch (e) {
      print('Error updating exercise: $e');
      _showToast(context, 'Error updating exercise: $e');
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question, {bool isNew = false}) async {
    bool confirmDelete = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
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

        if (mounted) {
          _snackAnimationController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.transparent,
              content: FadeTransition(
                opacity: _snackAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [Colors.blueGrey[900]!, Colors.blueGrey[700]!]
                          : [Colors.red[100]!, Colors.red[300]!], // Red gradient for delete
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Question deleted successfully!",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          debugPrint("Question deleted, showing compact animated SnackBar");
        }
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
        'expanded': true,
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
          onTap: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Categories:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(_isCategoryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
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
                selectedColor: isDarkMode ? Colors.purpleAccent.withOpacity(0.3) : Colors.blue,
                backgroundColor: isDarkMode ? Colors.grey[850] : Color.fromRGBO(254, 247, 255, 1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[400] : Colors.black),
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? (isDarkMode ? Colors.purpleAccent : Colors.blue) : (isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                    width: isSelected ? 2 : 1,
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
            child: Text('Please select at least one category!', style: TextStyle(color: Colors.red, fontSize: 14)),
          ),
      ],
    );
  }

  Widget _buildShareToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Share Exercise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Switch(
          value: _isShared,
          onChanged: (value) => setState(() => _isShared = value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Exercise'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 22),
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
                validator: (value) => value == null || value.isEmpty ? 'Exercise title cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Exercise Description',
                  hintText: 'Enter a description for the exercise',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Exercise description cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              _buildShareToggle(),
              const Divider(height: 24),
              _buildCategorySelection(),
              const Divider(height: 24),
              ..._questions.map((question) => _buildQuestionTile(question)),
              ..._newQuestions.map((question) => _buildQuestionTile(question, isNew: true)),
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

  Widget _buildQuestionTile(Map<String, dynamic> question, {bool isNew = false}) {
    return ExpansionTile(
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
          GestureDetector(
            onTap: () => _deleteQuestion(question, isNew: isNew),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(CupertinoIcons.trash_fill, color: Colors.redAccent, size: 22),
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
            decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
            onChanged: (value) => question['questionText'] = value,
            validator: (value) => value == null || value.isEmpty ? 'Question text cannot be empty' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['A'],
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Option A', border: OutlineInputBorder()),
            onChanged: (value) => question['A'] = value,
            validator: (value) => value == null || value.isEmpty ? 'Option A cannot be empty' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['B'],
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Option B', border: OutlineInputBorder()),
            onChanged: (value) => question['B'] = value,
            validator: (value) => value == null || value.isEmpty ? 'Option B cannot be empty' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['C'],
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Option C', border: OutlineInputBorder()),
            onChanged: (value) => question['C'] = value,
            validator: (value) => value == null || value.isEmpty ? 'Option C cannot be empty' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['D'],
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Option D', border: OutlineInputBorder()),
            onChanged: (value) => question['D'] = value,
            validator: (value) => value == null || value.isEmpty ? 'Option D cannot be empty' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: question['correctAnswer'],
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Correct Answer (A, B, C, or D)', border: OutlineInputBorder()),
            onChanged: (value) => question['correctAnswer'] = value.toUpperCase(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Correct answer cannot be empty';
              if (!['A', 'B', 'C', 'D'].contains(value.toUpperCase())) return 'Correct answer must be one of: A, B, C, or D';
              return null;
            },
          ),
        ],
      ),
    );
  }
}