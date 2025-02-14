import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_exercises/models/question_model.dart';
import 'package:intl/intl.dart'; // Add this for date formatting
import 'package:timeago/timeago.dart' as timeago; // Add this for relative time

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> unforkExercise(String exerciseId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("No user is logged in.");
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('forkedExercises')
          .doc(exerciseId)
          .delete();

      await _firestore.collection('exercises').doc(exerciseId).update({
        'forkedBy': FieldValue.arrayRemove([currentUser.uid]),
      });
    } catch (e) {
      throw Exception("Error unforking exercise: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> streamUserExercises() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]); // No user logged in
    }

    final userExercisesRef = _firestore
        .collection('exercises')
        .where('creatorId', isEqualTo: currentUser.uid);

    final forkedExercisesRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('forkedExercises');

    return userExercisesRef.snapshots().asyncMap((createdSnapshot) async {
      final createdExercises = createdSnapshot.docs.map((doc) {
        return {
          'exerciseId': doc.id,
          ...doc.data(),
          'isForked': false, // Created by user
        };
      }).toList();

      final forkedSnapshot = await forkedExercisesRef.get();
      final List<Map<String, dynamic>> forkedExercises = [];

      for (var doc in forkedSnapshot.docs) {
        final exerciseId = doc.id;
        final exerciseRef = await _firestore.collection('exercises').doc(exerciseId).get();

        if (!exerciseRef.exists) {
          continue; // Skip if the exercise doesn't exist
        }

        final exerciseData = exerciseRef.data() as Map<String, dynamic>;
        final bool isShared = exerciseData['shared'] ?? false;

        if (isShared) {
          // ✅ Only show if it's still shared
          forkedExercises.add({
            'exerciseId': exerciseId,
            ...exerciseData,
            'isForked': true, // Mark as forked
          });
        }
      }

      return [...createdExercises, ...forkedExercises]; // Combine both lists
    });
  }

  Future<List<Map<String, dynamic>>> fetchSharedExercises() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('exercises')
          .where('shared', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'exerciseId': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error fetching shared exercises: $e');
      return [];
    }
  }

  Future<List<Question>> fetchExerciseQuestions(String exerciseId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .collection('questions')
          .get();

      return querySnapshot.docs.map((doc) {
        return Question.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching exercise questions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserExercises() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user is logged in.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('exercises')
          .where('creatorId', isEqualTo: currentUser.uid)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'exerciseId': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error fetching user exercises: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getExerciseById(String exerciseId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('exercises').doc(exerciseId).get();
      if (doc.exists) {
        return {
          'exerciseId': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching exercise by ID: $e');
      return null;
    }
  }

 Future<List<Map<String, dynamic>>> fetchFilteredExercises({required String category}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    List<String> favoriteCategories = List<String>.from(userDoc['favoriteCategories'] ?? []);

    if (favoriteCategories.isEmpty) return [];

    QuerySnapshot querySnapshot;

    if (category == "All") {
      querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('shared', isEqualTo: true)
          .where('categories', arrayContainsAny: favoriteCategories)
          .orderBy('timestamp', descending: true)
          .get();
    } else {
      querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('shared', isEqualTo: true)
          .where('categories', arrayContains: category)
          .orderBy('timestamp', descending: true)
          .get();
    }

    return querySnapshot.docs.map((doc) {
      Timestamp? timestamp = doc["timestamp"] as Timestamp?;
      String formattedTime = "Unknown"; // Default value

      if (timestamp != null) {
        DateTime dateTime = timestamp.toDate();
        Duration difference = DateTime.now().difference(dateTime);

        if (difference.inMinutes < 1) {
          formattedTime = "Now";
        } else if (difference.inMinutes < 60) {
          formattedTime = "${difference.inMinutes} min ago";
        } else if (difference.inHours < 24) {
          formattedTime = "${difference.inHours} hr ago";
        } else {
          formattedTime = DateFormat('yyyy/MM/dd').format(dateTime);
        }
      }

      return {
        "exerciseId": doc.id,
        "title": doc["title"],
        "description": doc["description"],
        "creatorUsername": doc["creatorUsername"],
        "categories": List<String>.from(doc["categories"] ?? []),
        "downloadedCount": doc["downloadedCount"] ?? 0,
        "shared": doc["shared"] ?? false,
        "timestamp": formattedTime, // ✅ Add formatted time
      };
    }).toList();
  } catch (e) {
    print("❌ Error fetching exercises: $e");
    return [];
  }
}
}