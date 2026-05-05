//顯示玩家、電腦在對戰中的分數與頭像
import 'package:flutter/material.dart';

import '../models/player_account.dart';

class ScoreBar extends StatelessWidget {
  final int score;
  final int maxScore;
  final bool isLeft;
  final Color color;
  final String label;
  final String avatarAsset;
  final bool? answerCorrect; // 用於顯示玩家或電腦是否答對的狀態
  final bool showThinking;

  const ScoreBar({
    super.key,
    required this.score,
    required this.maxScore,
    required this.isLeft,
    required this.color,
    required this.label,
    required this.avatarAsset,
    this.answerCorrect, // 新增參數
    this.showThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score / maxScore).clamp(0.0, 1.0);
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Image(
                  image: PlayerAccount.getBattleAvatarImageProvider(
                    avatarAsset,
                  ),
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      label.isNotEmpty ? label[0] : '?',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
              if (showThinking)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top,
                    color: Colors.white.withOpacity(0.95),
                    size: 26,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 28), // avatar和長條間距
        RotatedBox(
          quarterTurns: isLeft ? 0 : 2,
          child: Container(
            width: 26,
            height: 480,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            alignment: Alignment.bottomCenter,
            // 長條內的填充部分，根據分數百分比調整高度
            child: FractionallySizedBox(
              heightFactor: percent,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        if (answerCorrect != null)
          Icon(
            answerCorrect! ? Icons.check_circle : Icons.cancel,
            color: answerCorrect! ? Colors.green : Colors.red,
            size: 24,
          ),
      ],
    );
  }
}
