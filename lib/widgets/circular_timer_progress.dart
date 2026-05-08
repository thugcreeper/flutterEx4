import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

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
    Color color;
    // 剩餘時間小於等於3秒時，顏色變紅
    if (timeLeft <= 3) {
      color = Colors.red;
    } else {
      color = const Color.fromARGB(255, 154, 154, 154);
    }

    return ScaleTransition(
      scale: pulse,
      child: CircularCountDownTimer(
        height: 80,
        width: 80,
        duration: totalTime,

        initialDuration: totalTime - timeLeft,

        fillColor: color,
        ringColor: color.withOpacity(0.2),
        strokeWidth: 10.0, // 圓環寬度

        textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),

        isReverse: true,
        isReverseAnimation: true,
        isTimerTextShown: true,
        timeFormatterFunction: (defaultFormatterFunction, duration) {
          return '${duration.inSeconds}';
        },
        onComplete: () {
          debugPrint("倒數結束");
        },
        onChange: (timeString) {},
      ),
    );
  }
}
