import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_exercises/models/question_model.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> unforkExercise(String exerciseId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("No user is logged in.");
    }

    try {
      // Remove the exercise from the user's forkedExercises collection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('forkedExercises')
          .doc(exerciseId)
          .delete();

      // Remove the user ID from the 'forkedBy' field in the exercise document
      await _firestore.collection('exercises').doc(exerciseId).update({
        'forkedBy': FieldValue.arrayRemove([currentUser.uid]),
      });
    } catch (e) {
      throw Exception("Error unforking exercise: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> streamUserExercises() {
    final currentUser = AuthService().currentUser;
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
          'isForked': false, // Mark as created by user
        };
      }).toList();

      final forkedSnapshot = await forkedExercisesRef.get();
      final forkedExercises = forkedSnapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'isForked': true, // Mark as forked
        };
      }).toList();

      return [...createdExercises, ...forkedExercises]; // Combine both lists
    });
  }

  // Fetch shared exercises
  Future<List<Map<String, dynamic>>> fetchSharedExercises() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('exercises')
          .where('shared', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'exerciseId': doc.id, // Use document ID as exerciseId
          ...doc.data() as Map<String, dynamic>, // Merge document data
        };
      }).toList();
    } catch (e) {
      print('Error fetching shared exercises: $e');
      return [];
    }
  }

  // Fetch questions for a specific exercise
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

  // Fetch user-specific exercises
  Future<List<Map<String, dynamic>>> fetchUserExercises() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        throw Exception("No user is logged in.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('exercises')
          .where('creatorId', isEqualTo: currentUser.email)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'exerciseId': doc.id, // Use document ID as exerciseId
          ...doc.data() as Map<String, dynamic>, // Merge document data
        };
      }).toList();
    } catch (e) {
      print('Error fetching user exercises: $e');
      return [];
    }
  }

  // Fetch a specific exercise by ID
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
      return null; // Return null if no document is found
    } catch (e) {
      print('Error fetching exercise by ID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFilteredExercises({required String category}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // 🔹 Fetch user's favorite categories
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    List<String> favoriteCategories = List<String>.from(userDoc['favoriteCategories'] ?? []);

    if (favoriteCategories.isEmpty) return []; // No favorite categories, return empty list

    QuerySnapshot querySnapshot;

    if (category == "All") {
      // 🔹 Show only exercises that match at least one of the user's favorite categories
      querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('shared', isEqualTo: true) // ✅ Check if the exercise is shared
          .where('categories', arrayContainsAny: favoriteCategories) // ✅ User's categories only
          .get();
    } else {
      // 🔹 Show exercises for the selected category
      querySnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('shared', isEqualTo: true) // ✅ Check if the exercise is shared
          .where('categories', arrayContains: category)
          .get();
    }

    return querySnapshot.docs.map((doc) {
      return {
        "exerciseId": doc.id,
        "title": doc["title"],
        "description": doc["description"],
        "creatorUsername": doc["creatorUsername"],
        "categories": List<String>.from(doc["categories"] ?? []),
        "downloadedCount": doc["downloadedCount"] ?? 0,
        "shared": doc["shared"] ?? false,
      };
    }).toList();
  } catch (e) {
    print("❌ Error fetching exercises: $e");
    return [];
  }
}
}
