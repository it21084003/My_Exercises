import 'package:flutter/material.dart';
import 'package:my_exercises/screens/exercises/my_exercises_screen.dart';
import '../../data/offline_database_helper.dart';
import 'downloaded_exercises_widget.dart'; // Assuming we’ll create this new page

class MyExercises extends StatefulWidget {
  const MyExercises({super.key});

  @override
  State<MyExercises> createState() => _MyExercisesPageState();
}

class _MyExercisesPageState extends State<MyExercises> {
  int _downloadedExerciseCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDownloadedExerciseCount();
  }

  Future<void> _fetchDownloadedExerciseCount() async {
    final exercises = await DatabaseHelper.getDownloadedExercises();
    setState(() {
      _downloadedExerciseCount = exercises.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Exercises")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              title: "My Exercises",
              subtitle: "Exercises you created",
              icon: Icons.edit_note,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyExercisesPage()),
                ).then((_) => _fetchDownloadedExerciseCount()); // Refresh on return
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: "Downloaded Exercises",
              subtitle: "You have $_downloadedExerciseCount downloaded exercises",
              icon: Icons.download_done,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DownloadedExercisesWidget()),
                ).then((_) => _fetchDownloadedExerciseCount()); // Refresh on return
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}