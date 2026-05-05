// 使用者的等級、經驗條、金錢資訊欄
import 'package:flutter/material.dart';
import '../models/player_account.dart';

class LvlAndMoneyBanner extends StatelessWidget {
  const LvlAndMoneyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // 最左：個人資料按鈕
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Image.asset(
              'assets/images/icons/player.webp',
              width: 64,
              height: 64,
            ),
          ),
          const SizedBox(width: 10),

          // 中間：等級圖示 + 等級文字 + 經驗進度條（同一 Row）
          Expanded(
            flex: 1,
            child: ValueListenableBuilder<int>(
              valueListenable: PlayerAccount.level,
              builder: (_, level, __) {
                return ValueListenableBuilder<int>(
                  valueListenable: PlayerAccount.experience,
                  builder: (_, __, ___) {
                    final progress = PlayerAccount.getExpProgress();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 等級圖示
                        Image.asset(
                          'assets/images/icons/level.png',
                          width: 60,
                          height: 80,
                        ),
                        const SizedBox(width: 4),

                        // 等級數字
                        Text(
                          '$level.',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(width: 2),

                        // 經驗進度條 + 數字
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 進度條
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    163,
                                    163,
                                    163,
                                  ).withOpacity(0.18),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(255, 95, 95, 95),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // 最右：金幣
          ValueListenableBuilder<int>(
            valueListenable: PlayerAccount.money,
            builder: (_, money, __) {
              return Expanded(flex: 1, child: _MoneyChip(amount: money));
            },
          ),
        ],
      ),
    );
  }
}

// ── 金幣顯示元件 ──────────────────────────────────────

class _MoneyChip extends StatelessWidget {
  const _MoneyChip({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/icons/coin.png', width: 28, height: 28),
          const SizedBox(width: 4),
          Text(
            '$amount',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
