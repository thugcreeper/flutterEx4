// question資料類別，包含問題的id、提示、類型、選項和正確答案的索引

enum QuestionType { text, image, imageWithTextPrompt }

class AnswerOption {
  const AnswerOption({this.text, this.imageUrl});

  final String? text;
  final String? imageUrl;
}

class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.type,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
    this.audioPath,
  });

  final String id;
  final String prompt;
  final QuestionType type;
  final List<AnswerOption> options;
  final int correctIndex;
  final String? imageUrl;
  final String? audioPath;
}
