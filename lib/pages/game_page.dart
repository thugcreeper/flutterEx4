/// 對戰介面主Widget
/// 功能：
///  - 顯示玩家與電腦的實時分數和頭像
///  - 呈現題目選項，玩家進行作答
///  - 管理10秒倒數計時器與分數計算
///  - 處理隱藏式CPU答題邏輯（CPU答案先隱藏，玩家回答後才揭曉）
///  - 實現最後一題雙倍獎懲的特殊機制
import 'dart:async';
import 'dart:math';

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
  /// 每題的作答時間(秒)
  static const int _secondsPerQuestion = 10;
  final Random _random = Random();

  /// 計時器脈搏動畫控制器（用於計時器視覺反饋）
  late final AnimationController _pulseController;

  /// 主計時器：每秒倒數一次，驅動時間流逝與分數衰減
  Timer? _timer;

  /// 當前問題的剩餘時間(秒)
  int _timeLeft = _secondsPerQuestion;

  /// 當前問題索引(0-based)
  int _questionIndex = 0;

  /// 玩家累積分數
  int _playerScore = 0;

  /// 電腦累積分數
  int _cpuScore = 0;

  /// 標記當前題目是否已結束(玩家和電腦都已作答，或時間已結束)
  bool _isQuestionClosed = false;

  /// 當前題目的分數：起始10分，每秒衰減1分(最低0分)
  /// 用於同時應用於玩家和電腦，實現時間越久得分越低的機制
  int _currentScorePerQuestion = 10;

  /// CPU答題延遲計時器(1-7秒隨機延遲)
  Timer? _cpuAnswerTimer;

  /// 玩家本題選擇的選項索引
  /// null = 尚未作答或超時未選擇
  int? _playerAnswerIndex;

  /// 電腦本題已揭曉的選項索引
  /// null = 尚未揭曉(可能是未答題，或CPU答案還未決定)
  int? _cpuAnswerIndex;

  /// CPU已在背景決定的答案，但尚未揭曉給玩家看
  /// 流程：CPU隨機決定→存入_cpuPendingAnswerIndex → 玩家作答後→移至_cpuAnswerIndex
  /// 這樣可以隱藏CPU答案，直到玩家回答，保持遊戲公平性
  int? _cpuPendingAnswerIndex;

  /// 判斷是否為最後一題
  bool get _isFinalQuestion =>
      _questionIndex == widget.city.questions.length - 1;

  /// 獲取當前題目的分數倍數：最後一題為2倍，其他為1倍
  int get _questionMultiplier => _isFinalQuestion ? 2 : 1;

  /// 獲取本題答對分數：基礎分數(時間衰減後) × 倍數
  int get _correctAnswerScore => _currentScorePerQuestion * _questionMultiplier;

  /// 獲取本題答錯扣分：-5 × 倍數
  int get _wrongAnswerPenalty => -5 * _questionMultiplier;

  /// 獲取當前題目物件
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

  /// 初始化新一題的計時和答題狀態
  /// 功能：
  ///  1. 重置題目狀態(時間、答題狀況)
  ///  2. 重置分數為10(最高分)
  ///  3. 啟動10秒倒數計時器
  ///  4. 啟動CPU答題延遲器
  void _startQuestionTimer() {
    // 重置題目狀態
    _isQuestionClosed = false;
    _timeLeft = _secondsPerQuestion;
    _playerAnswerIndex = null;
    _cpuAnswerIndex = null;
    _cpuPendingAnswerIndex = null;
    _timer?.cancel();
    _cpuAnswerTimer?.cancel();

    // 啟動脈搏動畫
    _pulseController.repeat(reverse: true);

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

  /// 排程CPU答題(延遲1-7秒後執行)
  /// 目的：模擬CPU思考時間，保持遊戲節奏
  /// 流程：
  ///  1. 隨機延遲1-7秒
  ///  2. 調用_resolveCpuAnswer()決定CPU答案
  ///  3. 若玩家已作答，立即結束此題並進行下一題
  ///  4. 若玩家未作答，CPU答案保持隱藏直到玩家作答
  void _scheduleCpuAnswer() {
    _cpuAnswerTimer?.cancel();
    // 隨機延遲1到7秒(模擬CPU思考)
    final delaySeconds = _random.nextInt(7) + 1;

    _cpuAnswerTimer = Timer(Duration(seconds: delaySeconds), () {
      // 防止重複執行或已結束的題目
      if (!mounted || _isQuestionClosed || _cpuPendingAnswerIndex != null) {
        return;
      }

      // 解析CPU答案(決定答對或答錯、選擇哪個選項)
      // revealImmediately: 若玩家已答題，立即揭曉；否則隱藏
      _resolveCpuAnswer(revealImmediately: _playerAnswerIndex != null);

      // 若玩家已答題，立即結束此題
      if (_playerAnswerIndex != null) {
        _isQuestionClosed = true;
        _timer?.cancel();
        _cpuAnswerTimer?.cancel();
        _pulseController.stop();
        _advanceToNextQuestionOrResult();
      }
    });
  }

  /// 處理玩家超時未作答的情況(10秒倒完)
  /// 流程：
  ///  1. 若玩家未作答，扣5分(最後一題扣10分)
  ///  2. 若CPU還未決定，強制CPU立即決定
  ///  3. 若CPU已決定但未揭曉，立即揭曉
  ///  4. 進行下一題
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
        _playerScore += _wrongAnswerPenalty; // 未答扣分
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

    _advanceToNextQuestionOrResult();
  }

  /// 處理玩家選擇答案
  /// 流程：
  ///  1. 記錄玩家選擇並立即計算分數(答對或答錯)
  ///  2. 檢查CPU答案狀態：
  ///     a. CPU已揭曉 → 立即結束此題
  ///     b. CPU已決定但隱藏 → 揭曉CPU答案並結束此題
  ///     c. CPU未決定 → 等待CPU決定
  void _onAnswerSelected(int index) {
    // 防止重複答題(一題只能選一個答案)
    if (_isQuestionClosed || _playerAnswerIndex != null) return;

    // 判斷玩家答案是否正確
    final isCorrect = index == _currentQuestion.correctIndex;
    debugPrint('Answer ${_currentQuestion.id}: $index (correct: $isCorrect)');

    // 記錄玩家選擇並更新分數
    setState(() {
      _playerAnswerIndex = index; // 觸發題目卡片顯示玩家選擇
      _playerScore += isCorrect ? _correctAnswerScore : _wrongAnswerPenalty;
    });

    // 情境1：CPU已揭曉答案，可以立即結束此題
    if (_cpuAnswerIndex != null) {
      _isQuestionClosed = true;
      _timer?.cancel();
      _cpuAnswerTimer?.cancel();
      _pulseController.stop();
      _advanceToNextQuestionOrResult();
      return;
    }

    // 情境2：CPU已決定但隱藏答案，現在揭曉並結束此題
    if (_cpuPendingAnswerIndex != null) {
      setState(() {
        _cpuAnswerIndex = _cpuPendingAnswerIndex;
        _cpuPendingAnswerIndex = null;
      });
      _isQuestionClosed = true;
      _timer?.cancel();
      _cpuAnswerTimer?.cancel();
      _pulseController.stop();
      _advanceToNextQuestionOrResult();
    }
    // 情境3：CPU還未決定，等待CPU決定
  }

  /// 決定CPU答案並計算CPU分數
  /// 參數：revealImmediately
  ///   true  = 直接揭曉答案(玩家已答題或時間已到)
  ///   false = 隱藏答案直到玩家作答
  /// 流程：
  ///  1. 隨機決定CPU答對或答錯(60%答對率)
  ///  2. 選擇具體選項(答對→選正確答案；答錯→隨機選其他)
  ///  3. 根據結果更新CPU分數(使用時間衰減後的分數)
  ///  4. 根據revealImmediately決定立即揭曉或隱藏
  void _resolveCpuAnswer({required bool revealImmediately}) {
    final correct = _currentQuestion.correctIndex;
    // CPU答對機率為60%
    final cpuPickCorrect = _random.nextDouble() < 0.6;
    // 決定CPU選擇的選項
    final cpuIndex = cpuPickCorrect
        ? correct // 答對：選擇正確答案
        : _random.nextInt(_currentQuestion.options.length); // 答錯：隨機選其他

    setState(() {
      // 計算CPU分數(使用相同的時間衰減機制和倍數)
      _cpuScore += cpuIndex == correct
          ? _correctAnswerScore // 答對加分
          : _wrongAnswerPenalty; // 答錯扣分

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

  /// 推進到下一題或進入結果頁面
  /// 流程：
  ///  1. 檢查是否已是最後一題
  ///  2. 最後一題 → 跳轉到ResultPage結算戰鬥
  ///  3. 非最後一題 → 題目索引+1，重新初始化計時器並開始下一題
  void _advanceToNextQuestionOrResult() {
    if (!mounted) return;

    // 檢查是否已是最後一題
    if (_questionIndex == widget.city.questions.length - 1) {
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

    // 判斷玩家與電腦是否答對，用於左右大頭貼的勾叉顯示
    final int correct = question.correctIndex;
    final bool? playerCorrect = _playerAnswerIndex == null
        ? null
        : _playerAnswerIndex == correct;
    final bool? cpuCorrect = _cpuAnswerIndex == null
        ? null
        : _cpuAnswerIndex == correct;
    final bool cpuThinking = _cpuAnswerIndex == null && !_isQuestionClosed;

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
                showThinking: cpuThinking, // CPU思考中時顯示問號
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
                  child: const Center(child: _FinalQuestionBanner()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 最後一題提示橫幅
/// 功能：在最後一題時顯示動畫警告橫幅
/// 說明：提醒玩家本題分數翻倍(答對雙倍加分，答錯雙倍扣分)
class _FinalQuestionBanner extends StatefulWidget {
  const _FinalQuestionBanner();

  @override
  State<_FinalQuestionBanner> createState() => _FinalQuestionBannerState();
}

/// 最後一題橫幅的狀態管理類
/// 動畫效果：
///  - 縮放：0.78 → 1.2(彈性過度)
///  - 透明度：0 → 1(漸顯)
///  - 持續時間：900毫秒
class _FinalQuestionBannerState extends State<_FinalQuestionBanner>
    with SingleTickerProviderStateMixin {
  /// 動畫控制器
  late final AnimationController _controller;

  /// 縮放動畫(使用彈性曲線)
  late final Animation<double> _scale;

  /// 透明度動畫(使用淡出曲線)
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // 初始化動畫控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // 0.9秒動畫
    )..forward(); // 立即啟動動畫

    // 縮放動畫：使用彈性過度效果
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
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
          child: Transform.scale(
            // 縮放從0.78(初始小)漸變到1.2(最大)
            scale: 0.78 + (0.42 * _scale.value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }
}
