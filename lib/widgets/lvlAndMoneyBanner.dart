//使用者的等級、錢那條資訊欄
import 'package:flutter/material.dart';
import '../models/player_account.dart';

class LvlAndMoneyBanner extends StatelessWidget {
  const LvlAndMoneyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: PlayerAccount.level,
          builder: (_, level, __) {
            return _buildStatChip(Icons.star, Colors.amber, 'Lv. $level');
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: PlayerAccount.money,
          builder: (_, money, __) {
            return _buildStatChip(Icons.attach_money, Colors.green, '\$$money');
          },
        ),
      ],
    );
  }
}

//繪製等級和金錢的統計資訊
Widget _buildStatChip(IconData icon, Color color, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Row(
      mainAxisSize: .min,
      mainAxisAlignment: .spaceEvenly,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
