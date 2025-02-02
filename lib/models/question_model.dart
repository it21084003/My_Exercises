class Question {
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;

  Question({
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
  });

factory Question.fromJson(Map<String, dynamic> json) {
  return Question(
    questionText: json['questionText'],
    optionA: json['optionA'],
    optionB: json['optionB'],
    optionC: json['optionC'],
    optionD: json['optionD'],
    correctAnswer: json['correctAnswer'],
  );
}

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