// Hall Page - Cyber Style Version
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/player_account.dart';
import '../widgets/lvlAndMoneyBanner.dart';

class HallPage extends StatefulWidget {
  const HallPage({super.key});

  @override
  State<HallPage> createState() => _HallPageState();
}

class _HallPageState extends State<HallPage>
    with SingleTickerProviderStateMixin {
  static const String _fallbackImageUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQs9gUXKwt2KErC_jWWlkZkGabxpeGchT-fyw&s';

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    PlayerAccount.ensureBankTimer();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleBankTap() async {
    final collected = PlayerAccount.collectBankMoney();
    final hasMoney = collected > 0;

    if (hasMoney) {
      PlayerAccount.addMoney(collected);
    }

    _showMoneySnackBar(
      context,
      isSuccess: hasMoney,
      title: hasMoney ? '領取 \$$collected' : '銀行沒錢啦!',
      icon: hasMoney ? Icons.savings : Icons.hourglass_bottom,
      accent: hasMoney ? const Color(0xFF00E676) : Colors.orangeAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: const LvlAndMoneyBanner(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===================== TOP =====================
            Expanded(
              flex: 7,
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

                  // overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // title
                  Positioned(
                    top: 40,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                              "YO BATTLE",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Colors.orangeAccent.withOpacity(0.8),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            )
                            .animate(
                              onPlay: (controller) {
                                controller.repeat(reverse: true);
                              },
                            )
                            .fade(duration: 1200.ms)
                            .shimmer(duration: 2000.ms, color: Colors.white),
                      ],
                    ),
                  ),

                  // enter button
                  Center(
                    child:
                        GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/cities');
                              },
                              child: AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1 + (_glowController.value * 0.04),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 42,
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00D1FF),
                                            Color(0xFF66E6FF),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00D1FF)
                                                .withOpacity(
                                                  0.6 +
                                                      (_glowController.value *
                                                          0.3),
                                                ),
                                            blurRadius: 30,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.black,
                                            size: 34,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "開始知識king!",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 900.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: 700.ms,
                              curve: Curves.easeOutBack,
                            ),
                  ),
                ],
              ),
            ),

            // ===================== BOTTOM =====================
            Expanded(
              flex: 3,
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

                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.65)),
                  ),

                  // 改為把點擊事件綁在銀行卡片本身，讓 ripple 在卡片上顯示
                  ValueListenableBuilder<int>(
                    valueListenable: PlayerAccount.bankValue,
                    builder: (context, bankValue, _) {
                      final progress = bankValue / PlayerAccount.bankMax;

                      final isReady = bankValue >= PlayerAccount.bankMax;

                      return Center(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          child: InkWell(
                            onTap: _handleBankTap,
                            borderRadius: BorderRadius.circular(25),
                            splashColor: Colors.white24,
                            highlightColor: Colors.white10,
                            child:
                                AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      margin: const EdgeInsets.all(20),
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        gradient: LinearGradient(
                                          colors: isReady
                                              ? [
                                                  const Color(0xFF00C853),
                                                  const Color(0xFFB2FF59),
                                                ]
                                              : [
                                                  const Color(0xFF1B1B1B),
                                                  const Color(0xFF303030),
                                                ],
                                        ),
                                        border: Border.all(
                                          color: isReady
                                              ? Colors.white
                                              : Colors.orangeAccent,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isReady
                                                ? Colors.greenAccent
                                                      .withOpacity(0.7)
                                                : Colors.orangeAccent
                                                      .withOpacity(0.3),
                                            blurRadius: isReady ? 30 : 15,
                                            spreadRadius: isReady ? 3 : 1,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons
                                                .account_balance_wallet_rounded,
                                            color: isReady
                                                ? Colors.black
                                                : Colors.orangeAccent,
                                            size: 42,
                                          ),

                                          const SizedBox(height: 10),

                                          Text(
                                            isReady ? "銀行金庫已滿!" : "銀行",
                                            style: TextStyle(
                                              color: isReady
                                                  ? Colors.black
                                                  : Colors.orangeAccent,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          Text(
                                            "\$$bankValue / ${PlayerAccount.bankMax}",
                                            style: TextStyle(
                                              color: isReady
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 0),

                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 14,
                                              backgroundColor: Colors.black
                                                  .withOpacity(0.3),
                                              //銀行進度條顏色
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    isReady
                                                        ? Colors.black
                                                        : const Color.fromARGB(
                                                            255,
                                                            246,
                                                            239,
                                                            51,
                                                          ),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) {
                                        if (isReady) {
                                          controller.repeat(reverse: true);
                                        }
                                      },
                                    )
                                    .shimmer(
                                      duration: 2000.ms,
                                      color: isReady
                                          ? Colors.white
                                          : Colors.orangeAccent,
                                    ),
                          ),
                        ),
                      );
                    },
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

// ===================== SNACKBAR =====================

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        content: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: isSuccess
                  ? [const Color(0xFF00C853), const Color(0xFFB2FF59)]
                  : [const Color(0xFFFF6D00), const Color(0xFFFFD54F)],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: 32),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
