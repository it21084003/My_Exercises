class Question {
  final String id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;

  Question({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
  });

  // Convert Firestore data into a Question object
  factory Question.fromFirestore(Map<String, dynamic> data, String id) {
    return Question(
      id: id,
      questionText: data['questionText'] ?? '',
      optionA: data['optionA'] ?? '',
      optionB: data['optionB'] ?? '',
      optionC: data['optionC'] ?? '',
      optionD: data['optionD'] ?? '',
      correctAnswer: data['correctAnswer'] ?? '',
    );
  }

  // Convert a Question object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'correctAnswer': correctAnswer,
    };
  }
}