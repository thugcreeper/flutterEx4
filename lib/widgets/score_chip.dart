// 分數顯示的Chip元件，顯示玩家的分數和金錢
import 'package:flutter/material.dart';

class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}
