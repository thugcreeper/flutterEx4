// 這是對戰介面，顯示玩家與機器人的頭像並答題比賽
import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/question.dart';
import '../widgets/question_card.dart';
import '../widgets/score_bar.dart';
import '../widgets/circular_timer_progress.dart';
import '../models/city.dart';
import '../models/player_account.dart';
import 'result_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.city});

  final CityLevel city;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  // 每題的作答時間10秒，時間越久分數越低(每秒扣1分)，最低0分
  static const int _secondsPerQuestion = 10;
  final Random _random = Random();

  // 計時器脈搏動畫控制器
  late final AnimationController _pulseController;
  late final AudioPlayer _questionAudioPlayer;

  // 主計時器：每秒倒數一次
  Timer? _timer;
  Timer? _questionTransitionTimer;
  int _timeLeft = _secondsPerQuestion;
  int _questionIndex = 0;
  int _playerScore = 0;
  int _cpuScore = 0;

  // 標記當前題目是否已結束(玩家和電腦都已作答，或時間已結束)
  bool _isQuestionClosed = false;

  // 當前題目的分數：起始10分，每秒衰減1分(最低0分)
  int _currentScorePerQuestion = 10;
  // 電腦答題延遲計時器(1-7秒隨機延遲)
  Timer? _cpuAnswerTimer;

  // 玩家本題選擇的選項索引
  // null = 尚未作答或超時未選擇
  int? _playerAnswerIndex;

  // 電腦本題已揭曉的選項索引
  // null = 尚未揭曉(可能是未答題，或CPU答案還未決定)
  int? _cpuAnswerIndex;

  // 顯示在分數條下方的上一題結果
  bool? _lastPlayerAnswerCorrect;
  bool? _lastCpuAnswerCorrect;

  // CPU已在背景決定的答案，但尚未揭曉給玩家看
  // 流程：CPU隨機決定→存入_cpuPendingAnswerIndex → 玩家作答後→移至_cpuAnswerIndex
  // 這樣可以隱藏CPU答案，直到玩家回答，保持遊戲公平性
  int? _cpuPendingAnswerIndex;

  // 判斷是否為最後一題
  bool get _isFinalQuestion =>
      _questionIndex == widget.city.questions.length - 1;
  // 獲取當前題目的分數倍數：最後一題為2倍
  int get _questionMultiplier => _isFinalQuestion ? 2 : 1;
  // 獲取本題答對分數
  int get _correctAnswerScore => _currentScorePerQuestion * _questionMultiplier;
  // 動態扣分：依已過秒數（越慢扣越多）。
  // 例如：若玩家在第9秒才答錯（_timeLeft == 1），則已過秒數為 9，扣 9 分。
  int _dynamicWrongPenalty({int? timeLeft}) {
    final elapsed = _secondsPerQuestion - (timeLeft ?? _timeLeft);
    final clamped = elapsed.clamp(1, _secondsPerQuestion);
    return -clamped.toInt() * _questionMultiplier;
  }

  // 獲取當前題目物件
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
    _questionAudioPlayer = AudioPlayer();
    _startQuestionTimer();
  }

  Future<void> _playCurrentQuestionAudio() async {
    final audioPath = _currentQuestion.audioPath;
    if (audioPath == null || audioPath.isEmpty) {
      return;
    }

    final questionId = _currentQuestion.id;

    try {
      await _questionAudioPlayer.stop();
      if (!mounted || _currentQuestion.id != questionId) {
        return;
      }

      debugPrint('Play audio for $questionId: $audioPath');
      await _questionAudioPlayer.play(AssetSource(audioPath));
    } catch (error) {
      debugPrint('Audio play failed for $questionId: $error');
    }
  }

  Future<void> _stopCurrentQuestionAudio() async {
    try {
      await _questionAudioPlayer.stop();
    } catch (_) {
      // ignore stop errors during fast question switching or dispose
    }
  }

  // 初始化新一題的計時和答題狀態
  void _startQuestionTimer() {
    // 重置題目狀態
    _isQuestionClosed = false;
    _timeLeft = _secondsPerQuestion;
    _playerAnswerIndex = null;
    _cpuAnswerIndex = null;
    _cpuPendingAnswerIndex = null;
    _lastPlayerAnswerCorrect = null;
    _lastCpuAnswerCorrect = null;
    _timer?.cancel();
    _cpuAnswerTimer?.cancel();
    _questionTransitionTimer?.cancel();

    // 啟動脈搏動畫
    _pulseController.repeat(reverse: true);

    // 換題時先停掉上一題音訊，再播放目前題目音訊
    unawaited(_playCurrentQuestionAudio());

    // 重置分數為最高分
    _currentScorePerQuestion = 10;

    // 觸發CPU答題邏輯
    _scheduleCpuAnswer();

    // 啟動每秒倒數的主計時器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // mounted: 檢查State是否仍在Widget樹中(防止disposed後的setState)
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        // 分數隨時間流逝而衰減(每秒扣1分)，但最低不低於0
        _currentScorePerQuestion = max(0, _currentScorePerQuestion - 1).toInt();
      });
      // 時間到，觸發超時處理
      if (_timeLeft <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  // 排程CPU答題(延遲1-7秒後執行)
  // 目的：模擬CPU思考時間，保持遊戲節奏
  // 流程：
  //  1. 隨機延遲1-7秒
  //  2. 調用_resolveCpuAnswer()決定CPU答案
  //  3. 若玩家已作答，立即結束此題並進行下一題
  //  4. 若玩家未作答，CPU答案保持隱藏直到玩家作答
  void _scheduleCpuAnswer() {
    _cpuAnswerTimer?.cancel();
    // 隨機延遲1到7秒(模擬CPU思考)
    final delaySeconds = _random.nextInt(7) + 1;

    _cpuAnswerTimer = Timer(Duration(seconds: delaySeconds), () {
      // 防止重複執行或已結束的題目
      if (!mounted || _cpuPendingAnswerIndex != null) {
        return;
      }

      // 解析CPU答案(決定答對或答錯、選擇哪個選項)
      // revealImmediately: 若玩家已答題，立即揭曉；否則隱藏
      _resolveCpuAnswer(revealImmediately: _playerAnswerIndex != null);

      // 若玩家已答題，立即結束此題
      if (_playerAnswerIndex != null) {
        _finishQuestionAndPause();
      }
    });
  }

  // 處理玩家超時未作答的情況(10秒倒完)
  // 流程：
  //  1. 若玩家未作答，扣5分(最後一題扣10分)
  //  2. 若CPU還未決定，強制CPU立即決定
  //  3. 若CPU已決定但未揭曉，立即揭曉
  //  4. 進行下一題
  void _onTimeout() {
    if (_isQuestionClosed) return; // 防止重複執行
    _isQuestionClosed = true;
    _pulseController.stop();
    debugPrint('Timeout on ${_currentQuestion.id}');
    _timer?.cancel();
    _cpuAnswerTimer?.cancel();

    // 若玩家未作答，扣分
    if (_playerAnswerIndex == null) {
      setState(() {
        // 未答視為耗盡時間，按最大懲罰（等同於整題已過秒數）扣分
        _playerScore += _dynamicWrongPenalty(timeLeft: 0); // 未答扣分
        _lastPlayerAnswerCorrect = false;
      });
    }

    // 若CPU還未決定答案，強制現在決定
    if (_cpuAnswerIndex == null && _cpuPendingAnswerIndex == null) {
      _resolveCpuAnswer(revealImmediately: true);
    }

    // 若CPU已決定但未揭曉，現在揭曉
    if (_cpuPendingAnswerIndex != null && _cpuAnswerIndex == null) {
      setState(() {
        _cpuAnswerIndex = _cpuPendingAnswerIndex;
        _cpuPendingAnswerIndex = null;
      });
    }

    _finishQuestionAndPause();
  }

  // 處理玩家選擇答案
  // 流程：
  //  1. 記錄玩家選擇並立即計算分數(答對或答錯)
  //  2. 檢查CPU答案狀態：
  //     a. CPU已揭曉 → 立即結束此題
  //     b. CPU已決定但隱藏 → 揭曉CPU答案並結束此題
  //     c. CPU未決定 → 等待CPU決定
  void _onAnswerSelected(int index) {
    // 防止重複答題(一題只能選一個答案)
    if (_isQuestionClosed || _playerAnswerIndex != null) return;

    // 判斷玩家答案是否正確
    final isCorrect = index == _currentQuestion.correctIndex;
    debugPrint('Player ${_currentQuestion.id}: $index (correct: $isCorrect)');

    // 記錄玩家選擇並更新分數
    setState(() {
      _playerAnswerIndex = index; // 觸發題目卡片顯示玩家選擇
      final scoreToAdd = isCorrect
          ? _correctAnswerScore
          : _dynamicWrongPenalty();
      _playerScore += scoreToAdd;
      _lastPlayerAnswerCorrect = isCorrect;
      debugPrint(
        'Player score: $_currentScorePerQuestion, add: $scoreToAdd, total: $_playerScore',
      );
    });

    // 情境1：CPU已揭曉答案，可以立即結束此題
    if (_cpuAnswerIndex != null) {
      _finishQuestionAndPause();
      return;
    }

    // 情境2：CPU已決定但隱藏答案，現在揭曉並結束此題
    if (_cpuPendingAnswerIndex != null) {
      setState(() {
        _cpuAnswerIndex = _cpuPendingAnswerIndex;
        _cpuPendingAnswerIndex = null;
      });
      _finishQuestionAndPause();
      return;
    }

    // 情境3：CPU還未決定，鎖定題目並等待CPU決定
    // 當CPU定時器觸發時，會自動揭曉並進行下一題
    _isQuestionClosed = true;
    _pulseController.stop();
  }

  void _finishQuestionAndPause() {
    if (!mounted) return;
    _isQuestionClosed = true;
    _timer?.cancel();
    _cpuAnswerTimer?.cancel();
    _pulseController.stop();

    _questionTransitionTimer?.cancel();
    _questionTransitionTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _advanceToNextQuestionOrResult();
    });
  }

  // 決定CPU答案並計算CPU分數
  // 參數：revealImmediately
  //   true  = 直接揭曉答案(玩家已答題或時間已到)
  //   false = 隱藏答案直到玩家作答
  // 流程：
  //  1. 隨機決定CPU答對或答錯(60%答對率)
  //  2. 選擇具體選項(答對→選正確答案；答錯→隨機選其他)
  //  3. 根據結果更新CPU分數(使用時間衰減後的分數)
  //  4. 根據revealImmediately決定立即揭曉或隱藏
  void _resolveCpuAnswer({required bool revealImmediately}) {
    final cpuScoreSnapshot = _currentScorePerQuestion;
    final correct = _currentQuestion.correctIndex;
    // CPU答對機率為60%
    final cpuPickCorrect = _random.nextDouble() < 0.6;
    // 決定CPU選擇的選項
    final cpuIndex = cpuPickCorrect
        ? correct // 答對：選擇正確答案
        : _random.nextInt(_currentQuestion.options.length); // 答錯：隨機選其他

    setState(() {
      // 計算CPU分數(使用相同的時間衰減機制和倍數)
      final scoreToAdd = cpuIndex == correct
          ? cpuScoreSnapshot *
                _questionMultiplier // 答對加分
          : _dynamicWrongPenalty(); // 答錯扣分
      _cpuScore += scoreToAdd;
      _lastCpuAnswerCorrect = cpuIndex == correct;
      debugPrint(
        'CPU ${_currentQuestion.id}: index=$cpuIndex, timeLeft=$_timeLeft, score=$_currentScorePerQuestion, add=$scoreToAdd, total=$_cpuScore',
      );

      if (revealImmediately) {
        // 立即揭曉CPU答案(觸發題目卡片顯示CPU勾/叉)
        _cpuAnswerIndex = cpuIndex;
        _cpuPendingAnswerIndex = null;
      } else {
        // 隱藏CPU答案直到玩家作答
        _cpuPendingAnswerIndex = cpuIndex;
      }
    });
  }

  // 推進到下一題或進入結果頁面
  // 流程：
  //  1. 檢查是否已是最後一題
  //  2. 最後一題 → 跳轉到ResultPage結算戰鬥
  //  3. 非最後一題 → 題目索引+1，重新初始化計時器並開始下一題
  void _advanceToNextQuestionOrResult() {
    if (!mounted) return;

    // 檢查是否已是最後一題
    if (_questionIndex == widget.city.questions.length - 1) {
      unawaited(_stopCurrentQuestionAudio());
      // 進入結果頁面結算分數
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

    // 進行下一題
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
    _cpuAnswerTimer?.cancel();
    _questionTransitionTimer?.cancel();
    unawaited(_questionAudioPlayer.dispose());
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;
    final progressText =
        '第 ${_questionIndex + 1} 題 / 共 ${widget.city.questions.length} 題';

    final maxScore = (widget.city.questions.length - 1) * 10 + 20;
    const cpuAvatar = 'assets/images/avatar/bot.png';

    // 顯示上一題結果，避免下一題開始時被清掉
    final bool? playerCorrect = _lastPlayerAnswerCorrect;
    final bool? cpuCorrect = _lastCpuAnswerCorrect;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.city.name),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 背景圖：城市大圖
            Positioned.fill(
              child: Image.asset(
                widget.city.backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
            // 深色遮罩提升可讀性
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.22),
                      Colors.black.withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ),
            // ── 左側：玩家分數長條＋大頭貼 ──
            Positioned(
              top: 80,
              width: 110,
              left: -20,
              child: ValueListenableBuilder<String?>(
                valueListenable: PlayerAccount.battleAvatar,
                builder: (_, selectedAvatar, __) {
                  return ScoreBar(
                    score: _playerScore,
                    maxScore: maxScore,
                    isLeft: true,
                    color: Colors.blue,
                    label: '你',
                    avatarAsset:
                        selectedAvatar ?? PlayerAccount.defaultBattleAvatar,
                    answerCorrect: playerCorrect, // 傳入勾叉狀態
                  );
                },
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
                  // 題目進度顯示
                  Text(
                    progressText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 圓形計時器(會隨著脈搏動畫放大縮小)
                  CircularTimerProgress(
                    key: ValueKey(_questionIndex),
                    timeLeft: _timeLeft,
                    totalTime: _secondsPerQuestion,
                    pulse: _pulseController,
                  ),
                  const SizedBox(height: 50),
                  // 題目卡片(顯示題目和選項，玩家在此作答)
                  Expanded(
                    child: QuestionCard(
                      question: question,
                      onAnswer: _onAnswerSelected,
                      playerAnswerIndex:
                          _playerAnswerIndex, // 玩家選擇索引(用於顯示玩家的勾/叉)
                      cpuAnswerIndex: _cpuAnswerIndex, // 電腦選擇索引(用於顯示CPU的勾/叉)
                      questionLocked: _isQuestionClosed, // 題目鎖定(玩家和CPU都答完時)
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── 最後一題動畫橫幅(放在最上方) ──
            if (_isFinalQuestion)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: const SizedBox(
                    width: double.infinity,
                    child: _FinalQuestionBanner(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 最後一題，本題分數翻倍(答錯也雙倍扣分)
class _FinalQuestionBanner extends StatefulWidget {
  const _FinalQuestionBanner();

  @override
  State<_FinalQuestionBanner> createState() => _FinalQuestionBannerState();
}

// 最後一題的動畫橫幅
class _FinalQuestionBannerState extends State<_FinalQuestionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 透明度動畫(使用淡出曲線)
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // 初始化動畫控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // 0.9秒動畫
    )..forward(); // 立即啟動動畫

    // 透明度動畫：使用淡出效果
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          // 透明度從0漸變到1
          opacity: _opacity.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.transparent, // 徹底去掉背景
        ),
        child: ShaderMask(
          // 1. 為文字套用高級感漸層 (冷調紫藍 或 暖調金橙)
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFE0E0E0), // 淺亮灰
              Color(0xFFFFFFFF), // 純白
              Color(0xFFBDBDBD), // 中灰
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              '最後一題！ 雙倍獎懲！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: .w900, // 使用最粗體
                letterSpacing: 4, // 增加字間距營造高級感
                // 2. 利用多層陰影製造「文字懸浮」效果
                shadows: [
                  Shadow(
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  Shadow(
                    offset: const Offset(0, 0),
                    blurRadius: 20,
                    color: Colors.white.withOpacity(0.2), // 微弱的外發光
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
