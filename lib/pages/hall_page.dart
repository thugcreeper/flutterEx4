//這是進入城市前的大廳頁面，也是啟動app看到的第一個葉面
import 'package:flutter/material.dart';
import '../widgets/lvlAndMoneyBanner.dart';
import '../models/player_account.dart';

// 讓 HallPage 變成 StatefulWidget 以便更新存款進度。
class HallPage extends StatefulWidget {
  const HallPage({super.key});

  @override
  State<HallPage> createState() => _HallPageState();
}

class _HallPageState extends State<HallPage> {
  static const String _fallbackImageUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQs9gUXKwt2KErC_jWWlkZkGabxpeGchT-fyw&s';

  Future<void> _handleBankTap() async {
    final collected = PlayerAccount.collectBankMoney();
    final hasMoney = collected > 0;
    if (hasMoney) {
      PlayerAccount.addMoney(collected);
    }
    _showMoneySnackBar(
      context,
      isSuccess: hasMoney,
      title: hasMoney ? '成功領取 \$$collected' : '目前沒有可領取的金錢!!!',

      //icon saving是撲滿，另一個是沙漏
      icon: hasMoney ? Icons.savings : Icons.hourglass_bottom,
      accent: hasMoney ? const Color(0xFF26C281) : const Color(0xFFFF8A65),
    );
  }

  @override
  void initState() {
    super.initState();
    // 全域銀行計時器由 PlayerAccount 維護，頁面進來時只要確保它已啟動。
    PlayerAccount.ensureBankTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const LvlAndMoneyBanner(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            //上半部分:Yo Battle 進入選擇城市
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/hall/yoBattle.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Image.network(
                          _fallbackImageUrl,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Center(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/cities'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(
                          color: Colors.orangeAccent,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.black87, // 深色底讓文字更跳
                      ),
                      child: const Text(
                        'YO BATTLE!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 5, thickness: 5, color: Colors.grey),
            // 下半部 Bank 區塊
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/hall/bank.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Image.network(
                          _fallbackImageUrl,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  // Bank tap target.
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: _handleBankTap),
                    ),
                  ),
                  // 半透明卡片美化 + 進度條
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ValueListenableBuilder<int>(
                      valueListenable: PlayerAccount.bankValue,
                      builder: (context, bankValue, _) {
                        final progress = bankValue / PlayerAccount.bankMax;
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.6),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 顯示銀行存款數值
                                Text(
                                  'Bank: $bankValue / ${PlayerAccount.bankMax}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 進度條隨時間變化
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 12,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.orangeAccent,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//自訂snack bar
void _showMoneySnackBar(
  BuildContext context, {
  required bool isSuccess,
  required String title,
  required IconData icon,
  required Color accent,
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // 根據成功與否切換不同的漸層顏色
              colors: isSuccess
                  ? [const Color(0xFF0F3D3E), accent, const Color(0xFF8DEB9C)]
                  : [const Color(0xFF5A1E1E), accent, const Color(0xFFFFC857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
