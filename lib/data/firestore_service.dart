import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_exercises/models/question_model.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream user-specific exercises (real-time updates)
  Stream<List<Map<String, dynamic>>> streamUserExercises() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return Stream.value([]); // Return an empty stream if no user is logged in
    }

    return _firestore
        .collection('exercises')
        .where('creator', isEqualTo: currentUser.email)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'exerciseId': doc.id, // Use document ID as exerciseId
                ...doc.data() as Map<String, dynamic>,
              };
            }).toList());
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
          .where('creator', isEqualTo: currentUser.email)
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
      DocumentSnapshot doc = await _firestore.collection('exercises').doc(exerciseId).get();
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
}