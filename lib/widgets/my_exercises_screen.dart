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
  List<Map<String, dynamic>> _exercises = [];

  Future<void> _navigateToCreateExercise() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExercisePage(),
      ),
    );
    setState(() {}); // Refresh the list after navigating back
  }

  Future<void> _unforkExercise(String exerciseId) async {
    try {
      await _firestoreService.unforkExercise(exerciseId);

      // Update the UI directly by removing the unforked exercise from the list
      setState(() {
        _exercises.removeWhere((exercise) => exercise['exerciseId'] == exerciseId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unforking exercise: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

            // StreamBuilder to fetch exercises
            Expanded(
  child: StreamBuilder<List<Map<String, dynamic>>>(
    stream: _firestoreService.streamUserExercises(),
    builder: (context, snapshot) {
      // Directly check for data without showing a spinner
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(
          child: Text(
            'No exercises found. Create or fork an exercise!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      // Update the internal exercises list for better control
      _exercises = snapshot.data!;

      return ListView.builder(
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          final exerciseId = exercise['exerciseId'];
          final title = exercise['title'] ?? 'Untitled Exercise';
          final description =
              exercise['description'] ?? 'No description.';
          final bool isForked = exercise['isForked'] ?? false;
          final originalCreator = exercise['creatorUsername'] ?? '';
          final int downloadedCount = exercise['downloadedCount'] ?? 0;

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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isForked
                        ? 'Forked from: $originalCreator'
                        : 'Created by you',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (!isForked)
                    Text(
                      'Downloaded by: $downloadedCount users',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isForked)
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
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
                        ).then((_) => setState(() {}));
                      },
                    ),
                  if (isForked)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () {
                        _unforkExercise(exerciseId!);
                      },
                    ),
                ],
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