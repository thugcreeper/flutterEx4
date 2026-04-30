//city 資料類別
import 'question.dart';

class CityLevel {
  const CityLevel({
    required this.name,
    required this.entryFee,
    required this.questions,
    required this.backgroundImage,
  });

  final String name;
  final int entryFee;
  final List<Question> questions;
  final String backgroundImage;
}
