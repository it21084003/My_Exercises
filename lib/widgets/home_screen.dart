import 'package:flutter/material.dart';
import '../screens/exercise_page.dart'; // Correct path based on your project structure// Correct the import path to where ExercisePage is defined
import '../data/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreService.fetchSharedExercises(), // Fetch shared exercises
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No shared exercises available.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                decoration: TextDecoration.underline,
                decorationColor: Colors.yellow,
              ),
            ),
          );
        }

        final exercises = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: ListTile(
                title: Text(
                  exercise['title'] ?? 'Untitled Exercise',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Created by: ${exercise['creator'] ?? 'Unknown'}'),
                onTap: () {
                  if (exercise['exerciseId'] == null) {
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
                        exerciseNumber: exercise['exerciseId'], // Pass exerciseId
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}