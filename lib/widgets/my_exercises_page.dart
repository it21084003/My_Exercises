import 'package:flutter/material.dart';
import 'package:my_exercises/widgets/edit_exercise_page.dart';
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

  Future<void> _navigateToCreateExercise() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExercisePage(),
      ),
    );
    // No need to manually fetch, since StreamBuilder will update automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Exercises",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 28, color: Colors.blue),
                  onPressed: _navigateToCreateExercise,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService
                    .streamUserExercises(), // 🔥 Stream-based listener
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                          'No exercises found. Create your first exercise!'),
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
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: ListTile(
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              Text('Created on: ${exercise['timestamp']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditExercisePage(
                                    exerciseId: exerciseId,
                                    title: title,
                                    shared: exercise['shared'],
                                  ),
                                ),
                              );
                            },
                          ),
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
        ),
      ),
    );
  }
}
