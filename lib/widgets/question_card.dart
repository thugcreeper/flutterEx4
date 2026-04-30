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
  });

  final Question question;
  final ValueChanged<int> onAnswer;
  final int? playerAnswerIndex;
  final int? cpuAnswerIndex;

  @override
  Widget build(BuildContext context) {
    // 圖片題幹＋純文字選項的特殊排版
    if (question.type == QuestionType.imageWithTextPrompt) {
      return Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                              backgroundColor: Colors.transparent,
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
                          width: 160,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.prompt,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 文字選項列表
              ...List.generate(question.options.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OptionTile(
                    index: index,
                    text: question.options[index].text ?? '',
                    correctIndex: question.correctIndex,
                    playerAnswerIndex: playerAnswerIndex,
                    cpuAnswerIndex: cpuAnswerIndex,
                    onTap: () => onAnswer(index),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // 純文字題 或 圖片選項題 的通用排版
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.prompt,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: question.type == QuestionType.image
                  ? _ImageOptions(
                      question: question,
                      onAnswer: onAnswer,
                      playerAnswerIndex: playerAnswerIndex,
                      cpuAnswerIndex: cpuAnswerIndex,
                    )
                  : _TextOptions(
                      question: question,
                      onAnswer: onAnswer,
                      playerAnswerIndex: playerAnswerIndex,
                      cpuAnswerIndex: cpuAnswerIndex,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 輔助：計算選項背景色 ──────────────────────────────

/// 答題後：正確答案 → 淺綠，選錯的選項 → 淺紅，其餘不變
Color _optionColor(
  BuildContext context,
  int index,
  int correctIndex,
  int? playerAnswerIndex,
  int? cpuAnswerIndex,
) {
  final answered = playerAnswerIndex != null || cpuAnswerIndex != null;
  if (!answered) return Theme.of(context).colorScheme.secondaryContainer;

  if (index == correctIndex) return const Color(0xFFB9F6CA); // 淺綠
  if (index == playerAnswerIndex || index == cpuAnswerIndex) {
    return const Color(0xFFFFCDD2); // 淺紅（選錯）
  }
  return Theme.of(context).colorScheme.secondaryContainer;
}

// ── 輔助：組合勾/叉圖示 ──────────────────────────────

/// 玩家選擇該選項 → 實心勾/叉；電腦選擇 → 空心勾/叉（較小）
List<Widget> _buildIndicators(
  int index,
  int correctIndex,
  int? playerAnswerIndex,
  int? cpuAnswerIndex,
) {
  final result = <Widget>[];

  if (playerAnswerIndex == index) {
    final ok = index == correctIndex;
    result.add(
      Icon(
        ok ? Icons.check_circle : Icons.cancel,
        color: ok ? Colors.green.shade700 : Colors.red.shade700,
        size: 20,
      ),
    );
  }

  if (cpuAnswerIndex == index) {
    if (result.isNotEmpty) result.add(const SizedBox(width: 3));
    final ok = index == correctIndex;
    result.add(
      Icon(
        ok ? Icons.check_circle_outline : Icons.cancel_outlined,
        color: ok ? Colors.green.shade700 : Colors.red.shade700,
        size: 18,
      ),
    );
  }

  return result;
}

// ── 純文字選項 ────────────────────────────────────────

class _TextOptions extends StatelessWidget {
  const _TextOptions({
    required this.question,
    required this.onAnswer,
    required this.playerAnswerIndex,
    required this.cpuAnswerIndex,
  });

  final Question question;
  final ValueChanged<int> onAnswer;
  final int? playerAnswerIndex;
  final int? cpuAnswerIndex;

  static const List<String> _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < question.options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Expanded(
            child: _OptionTile(
              index: i,
              label: i < _labels.length ? _labels[i] : '${i + 1}',
              text: question.options[i].text ?? '',
              correctIndex: question.correctIndex,
              playerAnswerIndex: playerAnswerIndex,
              cpuAnswerIndex: cpuAnswerIndex,
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
    required this.onTap,
    this.label,
  });

  final int index;
  final String text;
  final int correctIndex;
  final int? playerAnswerIndex;
  final int? cpuAnswerIndex;
  final VoidCallback onTap;
  final String? label; // 選項標籤（A/B/C/D），部分排版不傳

  @override
  Widget build(BuildContext context) {
    final bgColor = _optionColor(
      context,
      index,
      correctIndex,
      playerAnswerIndex,
      cpuAnswerIndex,
    );
    final indicators = _buildIndicators(
      index,
      correctIndex,
      playerAnswerIndex,
      cpuAnswerIndex,
    );
    final answered = playerAnswerIndex != null || cpuAnswerIndex != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: answered ? null : onTap, // 答題後禁止再次點擊
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // 選項標籤圓圈（A/B/C/D）
                if (label != null) ...[
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black12,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // 選項文字
                Expanded(
                  child: Text(text, style: const TextStyle(fontSize: 15)),
                ),
                // 勾/叉圖示（答題後才出現）
                if (indicators.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...indicators,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 圖片選項（2×2 格） ────────────────────────────────

/// 圖片選項：以 2×2 格線排列，答題後同樣染色並在右上角疊加勾/叉
class _ImageOptions extends StatelessWidget {
  const _ImageOptions({
    required this.question,
    required this.onAnswer,
    required this.playerAnswerIndex,
    required this.cpuAnswerIndex,
  });

  final Question question;
  final ValueChanged<int> onAnswer;
  final int? playerAnswerIndex;
  final int? cpuAnswerIndex;

  // 當選項圖片載入失敗時使用的備用圖片
  static const String _fallbackImageUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQs9gUXKwt2KErC_jWWlkZkGabxpeGchT-fyw&s';

  @override
  Widget build(BuildContext context) {
    final answered = playerAnswerIndex != null || cpuAnswerIndex != null;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final bgColor = _optionColor(
          context,
          index,
          question.correctIndex,
          playerAnswerIndex,
          cpuAnswerIndex,
        );
        final indicators = _buildIndicators(
          index,
          question.correctIndex,
          playerAnswerIndex,
          cpuAnswerIndex,
        );

        return InkWell(
          onTap: answered ? null : () => onAnswer(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: bgColor,
            ),
            child: Stack(
              children: [
                // 圖片與文字置中
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          option.imageUrl ?? _fallbackImageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.network(
                            _fallbackImageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.text ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // 勾/叉圖示疊加在右上角
                if (indicators.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: indicators,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
