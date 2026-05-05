//這是進入城市前的大廳頁面，也是啟動app看到的第一個葉面
import 'package:flutter/material.dart';
import '../widgets/lvlAndMoneyBanner.dart';
import 'dart:async';
import '../models/player_account.dart';

// 讓 HallPage 變成 StatefulWidget 以便更新存款進度。
class HallPage extends StatefulWidget {
  const HallPage({super.key});

  @override
  State<HallPage> createState() => _HallPageState();
}

class _HallPageState extends State<HallPage> {
  static const int _bankMax = 200;
  static const String _fallbackImageUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQs9gUXKwt2KErC_jWWlkZkGabxpeGchT-fyw&s';

  int _bankValue = 0;
  Timer? _bankTimer;

  void _ensureBankTimer() {
    if (_bankTimer?.isActive ?? false) return;
    _bankTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_bankValue < _bankMax) {
          _bankValue += 1;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleBankTap() async {
    final hasMoney = _bankValue > 0;
    final collected = _bankValue;
    if (hasMoney) {
      setState(() {
        _bankValue = 0;
      });
      PlayerAccount.addMoney(collected);
      _ensureBankTimer();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasMoney ? '成功領取 $collected 元' : '目前沒有可領取的金錢',
          style: const TextStyle(fontSize: 24),
        ),
        backgroundColor: hasMoney ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 每秒增加 1 元，超過上限就停。
    _ensureBankTimer();
  }

  @override
  void dispose() {
    _bankTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _bankValue / _bankMax;

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
                    child: Padding(
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
                              'Bank: $_bankValue / $_bankMax',
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
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
