import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch questions by exercise number
  Future<List<Question>> fetchQuestions(int exerciseId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('questions')
          .where('exerciseId', isEqualTo: exerciseId) // Filter by exerciseId
          .get();

      return querySnapshot.docs.map((doc) {
        return Question.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("❌ Error fetching questions: $e");
      return [];
    }
  }

  // Function to add a question to Firestore
  Future<void> addQuestion(Question question) async {
    try {
      await _firestore.collection('questions').add(question.toJson());
      print("✅ Question added successfully!");
    } catch (e) {
      print("❌ Error adding question: $e");
    }
  }

  // Function to delete a question from Firestore
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
      print("✅ Question deleted successfully!");
    } catch (e) {
      print("❌ Error deleting question: $e");
    }
  }
}