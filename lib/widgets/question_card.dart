// 問題卡片：根據題目類型顯示不同的題幹與選項排版
// 答題後會根據玩家與電腦的選擇，將選項染色並顯示勾/叉圖示
import 'package:flutter/material.dart';

import '../models/question.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.onAnswer,
    this.playerAnswerIndex, // 玩家選擇的索引，null 表示未作答
    this.cpuAnswerIndex, // 電腦選擇的索引，null 表示尚未揭曉
    this.questionLocked = false,
  });

  final Question question;
  final ValueChanged<int> onAnswer;
  final int? playerAnswerIndex;
  final int? cpuAnswerIndex;
  final bool questionLocked;

  @override
  Widget build(BuildContext context) {
    // 圖片題幹＋純文字選項的特殊排版
    if (question.type == QuestionType.imageWithTextPrompt) {
      return Container(
        height: 600,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1.6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 圖片題幹置中
            mainAxisSize: MainAxisSize.max,
            children: [
              Center(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: InteractiveViewer(
                                child: Image.asset(
                                  question.imageUrl ?? '',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Image.asset(
                          question.imageUrl ?? '',
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.prompt, //題目敘述
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: .w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 文字選項列表
              Expanded(
                child: Column(
                  crossAxisAlignment: .center,
                  children: [
                    ...List.generate(question.options.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OptionTile(
                          index: index,
                          text: question.options[index].text ?? '',
                          correctIndex: question.correctIndex,
                          playerAnswerIndex: playerAnswerIndex,
                          cpuAnswerIndex: cpuAnswerIndex,
                          questionLocked: questionLocked,
                          onTap: () => onAnswer(index),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 純文字題 或 圖片選項題 的通用排版
    return Container(
      height: 600,
      decoration: BoxDecoration(
        //color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // 文字題的題幹置中
          children: [
            Text(
              question.prompt,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _TextOptions(
                question: question,
                onAnswer: onAnswer,
                playerAnswerIndex: playerAnswerIndex,
                cpuAnswerIndex: cpuAnswerIndex,
                questionLocked: questionLocked,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 答題後：正確答案 → 淺綠，選錯的選項 → 淺紅，其餘不變
Color _optionColor(
  BuildContext context,
  int index,
  int correctIndex,
  int? playerAnswerIndex,
  int? cpuAnswerIndex,
) {
  final answered = playerAnswerIndex != null || cpuAnswerIndex != null;
  if (!answered) return Colors.white;

  // 玩家選對 → 綠色
  if (playerAnswerIndex == index && playerAnswerIndex == correctIndex) {
    return Colors.green.shade700;
  }
  // 玩家選錯 → 紅色
  if (playerAnswerIndex == index && playerAnswerIndex != correctIndex) {
    return Colors.red.shade700;
  }
  // 電腦選對 → 綠色
  if (cpuAnswerIndex == index && cpuAnswerIndex == correctIndex) {
    return Colors.green.shade700;
  }
  // 電腦選錯 → 紅色
  if (cpuAnswerIndex == index && cpuAnswerIndex != correctIndex) {
    return Colors.red.shade700;
  }

  return Colors.white;
}

// 答題後：選項邊框顏色變化，正確答案 → 綠色邊框，選錯的選項 → 紅色邊框，未作答或未揭曉 → 淺灰邊框
Color _optionBorderColor(
  BuildContext context,
  int index,
  int correctIndex,
  int? playerAnswerIndex,
  int? cpuAnswerIndex,
) {
  final answered = playerAnswerIndex != null || cpuAnswerIndex != null;
  if (!answered) return Colors.black12;

  if (index == correctIndex) return Colors.green.shade500;
  if (index == playerAnswerIndex || index == cpuAnswerIndex) {
    return Colors.red.shade400;
  }
  return Colors.white.withOpacity(0.18);
}

//根據狀態調整選項邊框粗細的函數
double _optionBorderWidth(
  int index,
  int correctIndex,
  int? playerAnswerIndex,
  int? cpuAnswerIndex,
) {
  final answered = playerAnswerIndex != null || cpuAnswerIndex != null;
  if (!answered) return 1.2;

  final isCorrect = index == correctIndex;
  final isPlayerPick = index == playerAnswerIndex;
  final isCpuPick = index == cpuAnswerIndex;

  if (isCorrect) return 2.0;
  // 玩家或電腦選錯的選項邊框稍微加粗
  if (isPlayerPick || isCpuPick) return 1.6;
  return 1.2;
}

// ── 純文字選項 ────────────────────────────────────────

class _TextOptions extends StatelessWidget {
  const _TextOptions({
    required this.question,
    required this.onAnswer,
    required this.playerAnswerIndex,
    required this.cpuAnswerIndex,
    required this.questionLocked,
  });

  final Question question;
  final ValueChanged<int> onAnswer;
  final int? playerAnswerIndex;
  final int? cpuAnswerIndex;
  final bool questionLocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        for (int i = 0; i < question.options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Expanded(
            child: _OptionTile(
              index: i,
              text: question.options[i].text ?? '',
              correctIndex: question.correctIndex,
              playerAnswerIndex: playerAnswerIndex,
              cpuAnswerIndex: cpuAnswerIndex,
              questionLocked: questionLocked,
              onTap: () => onAnswer(i),
            ),
          ),
        ],
      ],
    );
  }
}

// ── 單一選項 Tile ─────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.text,
    required this.correctIndex,
    required this.playerAnswerIndex,
    required this.cpuAnswerIndex,
    required this.questionLocked,
    required this.onTap,
  });

  final int index;
  final String text;
  final int correctIndex;
  final int? playerAnswerIndex;
  final int? cpuAnswerIndex;
  final bool questionLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = _optionColor(
      context,
      index,
      correctIndex,
      playerAnswerIndex,
      cpuAnswerIndex,
    );

    final answered = questionLocked || playerAnswerIndex != null;
    final borderColor = _optionBorderColor(
      context,
      index,
      correctIndex,
      playerAnswerIndex,
      cpuAnswerIndex,
    );
    final borderWidth = _optionBorderWidth(
      index,
      correctIndex,
      playerAnswerIndex,
      cpuAnswerIndex,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: answered ? null : onTap, // 答題後禁止再次點擊
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: answered && index == correctIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: answered && index == correctIndex
                          ? Colors.green.shade900
                          : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
