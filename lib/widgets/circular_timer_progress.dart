import 'package:flutter/material.dart';

class CircularTimerProgress extends StatelessWidget {
  final int timeLeft;
  final int totalTime;
  final Animation<double> pulse;

  const CircularTimerProgress({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (timeLeft / totalTime).clamp(0.0, 1.0);
    final isUrgent = timeLeft <= 5;
    final color = isUrgent
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return ScaleTransition(
      scale: pulse,
      child: SizedBox(
        width: 160,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: percent,
              strokeWidth: 45, // 圓環寬度
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Padding(
              padding: const EdgeInsets.all(50.0), // 數字與圓環間距
              child: Text(
                '$timeLeft',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
