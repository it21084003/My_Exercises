class Question {
  final String questionText;
  final String A;
  final String B;
  final String C;
  final String D;
  final String correctAnswer;

  Question({
    required this.questionText,
    required this.A,
    required this.B,
    required this.C,
    required this.D,
    required this.correctAnswer,
  });

factory Question.fromJson(Map<String, dynamic> json) {
  return Question(
    questionText: json['questionText'],
    A: json['A'],
    B: json['B'],
    C: json['C'],
    D: json['D'],
    correctAnswer: json['correctAnswer'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'A': A,
      'B': B,
      'C': C,
      'D': D,
      'correctAnswer': correctAnswer,
    };
  }
}