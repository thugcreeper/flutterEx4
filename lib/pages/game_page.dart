import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../widgets/question_card.dart';
import '../widgets/score_bar.dart';
import '../widgets/circular_timer_progress.dart';
import '../models/city.dart';
import 'result_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.city});

  final CityLevel city;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  static const int _secondsPerQuestion = 15;
  final Random _random = Random();

  late final AnimationController _pulseController;
  Timer? _timer;
  int _timeLeft = _secondsPerQuestion;
  int _questionIndex = 0;
  int _playerScore = 0;
  int _cpuScore = 0;
  bool _isLocked = false;

  // 玩家這題選擇的索引（null 表示尚未作答或超時）
  int? _playerAnswerIndex;
  // 電腦這題選擇的索引（null 表示尚未揭曉）
  int? _cpuAnswerIndex;

  Question get _currentQuestion => widget.city.questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _isLocked = false;
    _timeLeft = _secondsPerQuestion;
    _playerAnswerIndex = null;
    _cpuAnswerIndex = null;
    _timer?.cancel();
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  // 當玩家超時未答題時的處理邏輯
  void _onTimeout() {
    if (_isLocked) return; // 防止重複執行超時邏輯
    _isLocked = true;
    _pulseController.stop();
    debugPrint('Timeout on ${_currentQuestion.id}');
    setState(() {
      _playerScore -= 5; // 玩家超時扣分
    });
    _goNextQuestion();
  }

  // 玩家選擇答案後的處理邏輯
  void _onAnswerSelected(int index) {
    if (_isLocked) return; // 防止重複答題
    _isLocked = true;
    _timer?.cancel();
    _pulseController.stop();

    final isCorrect = index == _currentQuestion.correctIndex;
    debugPrint('Answer ${_currentQuestion.id}: $index (correct: $isCorrect)');
    setState(() {
      _playerAnswerIndex = index; // 記錄玩家選擇，觸發選項顏色變化
      _playerScore += isCorrect ? 10 : -5;
    });
    _goNextQuestion();
  }

  // 電腦答題，決定電腦選擇並更新分數與顯示索引
  void _applyCpuAnswer() {
    final correct = _currentQuestion.correctIndex;
    final cpuPickCorrect = _random.nextDouble() < 0.6; // 電腦答對機率 60%
    final cpuIndex = cpuPickCorrect
        ? correct
        : _random.nextInt(_currentQuestion.options.length);
    setState(() {
      _cpuAnswerIndex = cpuIndex; // 記錄電腦選擇，觸發勾/叉顯示
      if (cpuIndex == correct) {
        _cpuScore += 10;
      } else {
        _cpuScore -= 5;
      }
    });
  }

  Future<void> _goNextQuestion() async {
    // 先揭曉電腦答案，讓玩家看到勾叉結果
    _applyCpuAnswer();
    await Future.delayed(const Duration(milliseconds: 900)); // 停頓讓玩家看清楚結果
    if (!mounted) return;

    if (_questionIndex == widget.city.questions.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultPage(
            cityName: widget.city.name,
            playerScore: _playerScore,
            cpuScore: _cpuScore,
            entryFee: widget.city.entryFee,
          ),
        ),
      );
      return;
    }

    setState(() {
      _questionIndex += 1;
      _timeLeft = _secondsPerQuestion;
    });
    _pulseController.reset();
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;
    final progressText =
        '第 ${_questionIndex + 1} 題 / 共 ${widget.city.questions.length} 題';
    final maxScore = widget.city.questions.length * 10;
    const playerAvatar = 'assets/images/avatar/me.png';
    const cpuAvatar = 'assets/images/avatar/bot.png';

    // 判斷玩家與電腦是否答對，用於左右大頭貼的勾叉顯示
    final int correct = question.correctIndex;
    final bool? playerCorrect = _playerAnswerIndex == null
        ? null
        : _playerAnswerIndex == correct;
    final bool? cpuCorrect = _cpuAnswerIndex == null
        ? null
        : _cpuAnswerIndex == correct;

    return Scaffold(
      appBar: AppBar(title: Text(widget.city.name), centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            // ── 左側：玩家分數長條＋大頭貼 ──
            Positioned(
              top: 80,
              width: 110,
              left: -20,
              child: ScoreBar(
                score: _playerScore,
                maxScore: maxScore,
                isLeft: true,
                color: Colors.blue,
                label: '你',
                avatarAsset: playerAvatar,
                answerCorrect: playerCorrect, // 傳入勾叉狀態
              ),
            ),

            // ── 右側：電腦分數長條＋大頭貼 ──
            Positioned(
              top: 80,
              right: -20,
              width: 110,
              child: ScoreBar(
                score: _cpuScore,
                maxScore: maxScore,
                isLeft: true,
                color: Colors.red,
                label: '電腦',
                avatarAsset: cpuAvatar,
                answerCorrect: cpuCorrect, // 傳入勾叉狀態
              ),
            ),

            // ── 中央主要內容 ──
            Positioned.fill(
              top: 50,
              bottom: 100,
              left: 60,
              right: 60,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // 題目進度
                  Text(
                    progressText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 圓形計時器
                  CircularTimerProgress(
                    timeLeft: _timeLeft,
                    totalTime: _secondsPerQuestion,
                    pulse: _pulseController,
                  ),
                  const SizedBox(height: 50),
                  // 題目卡片
                  Expanded(
                    child: QuestionCard(
                      question: question,
                      onAnswer: _onAnswerSelected,
                      playerAnswerIndex: _playerAnswerIndex, // 玩家選擇索引
                      cpuAnswerIndex: _cpuAnswerIndex, // 電腦選擇索引
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
