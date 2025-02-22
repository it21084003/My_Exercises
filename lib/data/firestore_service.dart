import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_exercises/models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'package:timeago/timeago.dart' as timeago;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Unfork an exercise
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
      debugPrint("❌ Error unforking exercise: $e");
      throw Exception("Error unforking exercise: $e");
    }
  }

  /// Stream exercises created and forked by the user
  Stream<List<Map<String, dynamic>>> streamUserExercises() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
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
        debugPrint("Streaming created exercise ${doc.id}: downloadedCount = ${doc['downloadedCount'] ?? 0}");
        return {
          'exerciseId': doc.id,
          ...doc.data() as Map<String, dynamic>,
          'isForked': false,
          'downloadedCount': doc['downloadedCount'] ?? 0,
        };
      }).toList();

      final forkedSnapshot = await forkedExercisesRef.get();
      final List<Map<String, dynamic>> forkedExercises = [];

      for (var doc in forkedSnapshot.docs) {
        final exerciseId = doc.id;
        final exerciseRef = await _firestore.collection('exercises').doc(exerciseId).get();

        if (!exerciseRef.exists) continue;

        final exerciseData = exerciseRef.data() as Map<String, dynamic>;
        if (exerciseData['shared'] == true) {
          debugPrint("Streaming forked exercise $exerciseId: downloadedCount = ${exerciseData['downloadedCount'] ?? 0}");
          forkedExercises.add({
            'exerciseId': exerciseId,
            ...exerciseData,
            'isForked': true,
            'downloadedCount': exerciseData['downloadedCount'] ?? 0,
          });
        }
      }

      return [...createdExercises, ...forkedExercises];
    });
  }

  /// Fetch shared exercises
  Future<List<Map<String, dynamic>>> fetchSharedExercises() async {
    try {
      final querySnapshot = await _firestore
          .collection('exercises')
          .where('shared', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        debugPrint("Fetching shared exercise ${doc.id}: downloadedCount = ${doc['downloadedCount'] ?? 0}");
        return {
          'exerciseId': doc.id,
          ...doc.data() as Map<String, dynamic>,
          'downloadedCount': doc['downloadedCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching shared exercises: $e");
      return [];
    }
  }

  /// Fetch questions of a specific exercise
  Future<List<Question>> fetchExerciseQuestions(String exerciseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .collection('questions')
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching exercise questions: $e");
      return [];
    }
  }

  /// Fetch exercises created by the current user
  Future<List<Map<String, dynamic>>> fetchUserExercises() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("No user is logged in.");

      final querySnapshot = await _firestore
          .collection('exercises')
          .where('creatorId', isEqualTo: currentUser.uid)
          .get();

      return querySnapshot.docs.map((doc) {
        debugPrint("Fetching user exercise ${doc.id}: downloadedCount = ${doc['downloadedCount'] ?? 0}");
        return {
          'exerciseId': doc.id,
          ...doc.data() as Map<String, dynamic>,
          'downloadedCount': doc['downloadedCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching user exercises: $e");
      return [];
    }
  }

  /// Get a single exercise by ID
  Future<Map<String, dynamic>?> getExerciseById(String exerciseId) async {
    try {
      final doc = await _firestore.collection('exercises').doc(exerciseId).get();
      if (doc.exists) {
        debugPrint("Fetching exercise $exerciseId: downloadedCount = ${doc['downloadedCount'] ?? 0}");
        return {
          'exerciseId': doc.id,
          ...doc.data() as Map<String, dynamic>,
          'downloadedCount': doc['downloadedCount'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error fetching exercise by ID: $e");
      return null;
    }
  }

  /// Fetch exercises filtered by category and user's favorite categories
  Future<List<Map<String, dynamic>>> fetchFilteredExercises({required String category}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final List<String> favoriteCategories = List<String>.from(userDoc['favoriteCategories'] ?? []);

      if (favoriteCategories.isEmpty) return [];

      QuerySnapshot querySnapshot;

      if (category == "All") {
        querySnapshot = await _firestore
            .collection('exercises')
            .where('shared', isEqualTo: true)
            .where('categories', arrayContainsAny: favoriteCategories)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('exercises')
            .where('shared', isEqualTo: true)
            .where('categories', arrayContains: category)
            .orderBy('timestamp', descending: true)
            .get();
      }

      return querySnapshot.docs.map((doc) {
        final Timestamp? timestamp = doc["timestamp"] as Timestamp?;
        final String formattedTime = timestamp != null
            ? formatShortTimeAgo(timestamp.toDate())
            : "Unknown";

        debugPrint("Fetching filtered exercise ${doc.id}: downloadedCount = ${doc['downloadedCount'] ?? 0}");
        return {
          "exerciseId": doc.id,
          "title": doc["title"],
          "description": doc["description"],
          "creatorUsername": doc["creatorUsername"],
          "categories": List<String>.from(doc["categories"] ?? []),
          "downloadedCount": doc["downloadedCount"] ?? 0,
          "shared": doc["shared"] ?? false,
          "timestamp": formattedTime,
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching filtered exercises: $e");
      return [];
    }
  }

  /// Public method to format timestamp in short format (e.g., "5m," "2h," "5d," "1mo")
  String formatShortTimeAgo(DateTime date) {
    final Duration difference = DateTime.now().difference(date);
    final int minutes = difference.inMinutes;
    final int hours = difference.inHours;
    final int days = difference.inDays;
    final int months = (days / 30).floor();
    final int years = (days / 365).floor();

    if (minutes < 60) {
      return "${minutes}m";
    } else if (hours < 24) {
      return "${hours}h";
    } else if (days < 30) {
      return "${days}d";
    } else if (days < 365) {
      return "${months}mo";
    } else {
      return "${years}y";
    }
  }
}