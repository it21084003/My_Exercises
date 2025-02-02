import 'package:flutter/material.dart';
import '../data/firestore_service.dart';
import '../screens/exercise_page.dart';
import 'create_exercise_page.dart';

class MyExercisesPage extends StatefulWidget {
  const MyExercisesPage({super.key});

  @override
  State<MyExercisesPage> createState() => _MyExercisesPageState();
}

class _MyExercisesPageState extends State<MyExercisesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Future<List<Map<String, dynamic>>>? _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  // Fetch user exercises and update UI
  void _fetchExercises() {
    setState(() {
      _exercisesFuture = _firestoreService.fetchUserExercises();
    });
  }

  // Navigate to CreateExercisePage and refresh after returning
  Future<void> _navigateToCreateExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExercisePage(),
      ),
    );

    // ✅ Force refresh only if an exercise was added
    if (result == true) {
      _fetchExercises();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Row with "My Exercises" and Add Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _exercisesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No exercises found. Create your first exercise!'),
                );
              }

              final exercises = snapshot.data!;
              return ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final exerciseId = exercise['exerciseId'];
                  final title = exercise['title'] ?? 'Untitled Exercise';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8.0,
                    ),
                    child: ListTile(
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Created on: ${exercise['timestamp']}'),
                      onTap: () {
                        if (exerciseId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exercise ID is missing!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExercisePage(
                              exerciseNumber: exerciseId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}