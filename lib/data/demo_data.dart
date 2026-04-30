// 在這裡放城市的list 和問題列表
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/city.dart';
import '../models/question.dart';

class DemoData {
  static const String imageQuestionUniformText = '該圖片中的歌詞對應哪一首歌?';

  // 台詞空耳答案池
  static final List<String> lineMemeAnswers = [
    '氣死偶勒',
    '我練功發自真心',
    '只要史坦那發起進攻，一切都會好起來的',
    '我還有機會',
    '你們這些敗類',
    '我不想再看到你',
    '這都是命運',
    '你給我滾出去',
    '我已經受夠了',
  ];
  // 選擇電影答案池
  static final List<String> movieAnswers = [
    '逃學威龍',
    '破壞之王',
    '九品芝麻官',
    '整人專家',
    '唐伯虎點秋香',
    '食神',
    '功夫',
    '少林足球',
  ];
  // 火影招式答案池
  static final List<String> narutoAnswers = [
    '大鮫彈之術',
    '四紫炎陣',
    '千鳥流',
    '螺旋丸',
    '影分身之術',
    '通靈之術',
    '八門遁甲',
    '月讀',
  ];
  // 圖片題選項池（僅文字）
  static final List<String> imageTextAnswers = [
    '無地自容',
    'In the End',
    '22',
    'Never Gonna Give You Up',
    'We Will Rock You',
    'Drama',
    'DDU-DU DDU-DU',
    'Bury the Light',
    '斯卡雷特警察巡邏貧民區24時',
  ];

  // 題目設定（正確答案與題幹）
  static final List<Map<String, dynamic>> _textQuestionsData = [
    {
      'id': 'txt1',
      'prompt': '哪一個是"帝國的毀滅"中元首的台詞空耳?',
      'answer': lineMemeAnswers[0],
    },
    {'id': 'txt2', 'prompt': '哪一個是"德國瘋小子"的台詞空耳', 'answer': lineMemeAnswers[1]},
    {'id': 'txt3', 'prompt': '"我還沒上車啊!"是哪部電影的名台詞?', 'answer': movieAnswers[0]},
    {
      'id': 'txt4',
      'prompt': '"我不是針對你，我是說在做的各位都是🗑️"是哪部電影的名台詞?',
      'answer': movieAnswers[1],
    },
    {
      'id': 'txt5',
      'prompt': '"我又跳出去了，唉呀，我又跳進來啦！打我啊笨蛋"是哪部電影的名台詞?',
      'answer': movieAnswers[2],
    },
    {
      'id': 'txt6',
      'prompt': '誠實豆沙包、慚愧棒棒糖是出自哪部電影的道具?',
      'answer': movieAnswers[3],
    },
    {
      'id': 'txt7',
      'prompt': '火影忍者中"大口痰拿去吃"的空耳是哪個忍術?',
      'answer': narutoAnswers[0],
    },
    {
      'id': 'txt8',
      'prompt': '火影忍者中"洗洗眼睛"的空耳是哪個忍術?',
      'answer': narutoAnswers[1],
    },
  ];
  // 圖片題設定（正確答案與題幹，並包含圖片路徑）
  static final List<Map<String, dynamic>> _imageQuestionsData = [
    {
      //喔啊啊欸欸喔喔啊啊
      'id': 'img1',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/1.jpg',
        'text': imageTextAnswers[0],
      },
      'type': QuestionType.imageWithTextPrompt,
    },
    {
      //in the end
      'id': 'img2',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/2.jpg',
        'text': imageTextAnswers[1],
      },
      'type': QuestionType.image,
    },
    {
      //22
      'id': 'img3',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/3.jpg',
        'text': imageTextAnswers[2],
      },
      'type': QuestionType.image,
    },
    {
      //never gonna give you up
      'id': 'img4',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/4.jpg',
        'text': imageTextAnswers[3],
      },
      'type': QuestionType.image,
    },
    {
      //we will rock you
      'id': 'img5',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/5.jpg',
        'text': imageTextAnswers[4],
      },
      'type': QuestionType.image,
    },
    {
      //aespa drama
      'id': 'img6',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/6.jpg',
        'text': imageTextAnswers[5],
      },
      'type': QuestionType.image,
    },
    {
      //DDU-DU DDU-DU
      'id': 'img7',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/7.jpg',
        'text': imageTextAnswers[6],
      },
      'type': QuestionType.image,
    },
    {
      //Bury the Light (I'm the strom that is approaching)
      'id': 'img8',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/8.jpg',
        'text': imageTextAnswers[7],
      },
      'type': QuestionType.image,
    },
    {
      //斯卡雷特警察巡邏貧民區24時
      'id': 'img9',
      'prompt': imageQuestionUniformText,
      'answer': {
        'image': 'assets/images/songQuestion/9.png',
        'text': imageTextAnswers[8],
      },
      'type': QuestionType.image,
    },
  ];

  static final List<CityLevel> cities = [
    CityLevel(
      name: '哈蘭',
      entryFee: 50,
      questions: _buildRandomQuestions(),
      backgroundImage: 'assets/images/cityBg/harran.jpg',
    ),
    CityLevel(
      name: '浣熊市',
      entryFee: 120,
      questions: _buildRandomQuestions(),
      backgroundImage: 'assets/images/cityBg/raccoon.webp',
    ),
    CityLevel(
      name: '高譚市',
      entryFee: 220,
      questions: _buildRandomQuestions(),
      backgroundImage: 'assets/images/cityBg/gotham.jpg',
    ),
  ];

  static List<Question> _buildRandomQuestions() {
    final rand = UniqueKey().hashCode ^ DateTime.now().millisecondsSinceEpoch;
    final random = Random(rand);
    // 2 圖片題 + 2 文字題
    final imgData = List<Map<String, dynamic>>.from(_imageQuestionsData)
      ..shuffle(random);
    final txtData = List<Map<String, dynamic>>.from(_textQuestionsData)
      ..shuffle(random);
    final selected = <Question>[];
    // 圖片題
    for (var q in imgData.take(2)) {
      final answer = q['answer'];
      final correctText = (answer is Map && answer['text'] != null)
          ? answer['text']
          : (answer is String ? answer : '');
      final imageUrl = (answer is Map && answer['image'] != null)
          ? answer['image']
          : '';
      final distractors = List<String>.from(
        imageTextAnswers.where((a) => a != correctText),
      );
      distractors.shuffle(random);
      final options = [
        AnswerOption(text: correctText),
        ...distractors.take(3).map((a) => AnswerOption(text: a)),
      ]..shuffle(random);
      final correctIndex = options.indexWhere((o) => o.text == correctText);
      selected.add(
        Question(
          id: q['id'],
          prompt: q['prompt'],
          type: QuestionType.imageWithTextPrompt,
          options: options,
          correctIndex: correctIndex,
          imageUrl: imageUrl,
        ),
      );
    }
    // 文字題（支援多種答案池）
    final textCount = txtData.length < 2 ? txtData.length : 2;
    for (int i = 0; i < textCount; i++) {
      final q = txtData[i];
      final answer = q['answer'];
      if (answer == null || answer is! String) continue;
      final prompt = q['prompt']?.toString() ?? '';
      List<String> pool;
      if (prompt.contains('台詞空耳')) {
        pool = lineMemeAnswers.where((a) => a != answer).toList();
      } else if (prompt.contains('火影忍者')) {
        pool = narutoAnswers.where((a) => a != answer).toList();
      } else if (prompt.contains('電影')) {
        pool = movieAnswers.where((a) => a != answer).toList();
      } else {
        pool = [];
      }
      if (pool.length < 3) continue; // 選項不夠
      pool.shuffle(random);
      final options = [
        AnswerOption(text: answer),
        ...pool.take(3).map((a) => AnswerOption(text: a)),
      ]..shuffle(random);
      final correctIndex = options.indexWhere((o) => o.text == answer);
      if (correctIndex == -1) continue;
      selected.add(
        Question(
          id: q['id'],
          prompt: q['prompt'],
          type: QuestionType.text,
          options: options,
          correctIndex: correctIndex,
        ),
      );
    }
    selected.shuffle(random);
    return selected;
  }
}
