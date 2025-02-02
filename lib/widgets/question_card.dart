import 'package:flutter/material.dart';
import '../models/question_model.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final int questionIndex;
  final Function(String) onAnswerSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.onAnswerSelected,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text
            Text(
              "Q${widget.questionIndex + 1}: ${widget.question.questionText}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Options
            Column(
              children: [
                for (var option in ['optionA', 'optionB', 'optionC', 'optionD'])
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 5, // Adjust the width for left alignment
                          child: Radio<String>(
                            value: option,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value!;
                              });
                              widget.onAnswerSelected(value!);
                            },
                          ),
                        ),
                        const SizedBox(
                            width: 4), // Space between Radio and Text
                        Expanded(
                          child: Text(
                            widget.question.toJson()[option]!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
