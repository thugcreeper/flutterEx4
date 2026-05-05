// 對戰結果畫面
import 'package:flutter/material.dart';
import 'package:flutter_interesting_game/pages/hall_page.dart';
import '../models/player_account.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({
    super.key,
    required this.cityName,
    required this.playerScore,
    required this.cpuScore,
    required this.entryFee, // 該城市入場費，用於計算獎懲金額
  });

  final String cityName;
  final int playerScore;
  final int cpuScore;
  final int entryFee;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  int _moneyDelta = 0; // 本局金錢變動量（正=獲得，負=扣除），預設 0 待結算後更新
  bool _hasSettled = false;

  @override
  void initState() {
    super.initState();

    // 延後到第一個 frame 結束後才結算金錢
    // 原因：initState 期間修改 ValueNotifier 會觸發 listener 通知，
    // 若畫面中有 ValueListenableBuilder 正在 build，就會丟出
    // "setState called during build" 例外。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settleMoney();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  /// 結算金錢並更新顯示（在 postFrameCallback 中呼叫，避免 build 期間觸發 ValueNotifier）
  void _settleMoney() {
    if (_hasSettled) return;
    _hasSettled = true;

    final int reward = widget.entryFee * 3;
    final bool isWin = widget.playerScore >= widget.cpuScore;
    int delta;

    if (isWin) {
      // 贏了：增加獎勵
      PlayerAccount.addMoney(reward);
      PlayerAccount.battleWin();
      delta = reward;
    } else {
      // 輸了：扣除金額；若錢不夠就扣到 0
      final bool success = PlayerAccount.spend(reward);
      if (success) {
        delta = -reward;
      } else {
        // 餘額不足：記錄實際扣除量後歸零
        delta = -PlayerAccount.money.value;
        PlayerAccount.money.value = 0;
      }

      PlayerAccount.battleLose();
    }

    PlayerAccount.recordBattle(isWin);

    setState(() {
      _moneyDelta = delta;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWin = widget.playerScore >= widget.cpuScore;
    const cpuAvatar = 'assets/images/hall/yoBattle.png';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖
          Image.asset(
            isWin
                ? 'assets/images/hall/youwin.jpg'
                : 'assets/images/hall/youlose.jpg',
            fit: BoxFit.cover,
          ),

          // 漸層遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.70),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // 左右頭像區
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<String?>(
                            valueListenable: PlayerAccount.battleAvatar,
                            builder: (_, selectedAvatar, __) {
                              return _AvatarCard(
                                assetPath:
                                    selectedAvatar ??
                                    PlayerAccount.defaultBattleAvatar,
                                label: '你',
                                score: widget.playerScore,
                                color: Colors.blue.shade300,
                                isWinner: isWin,
                                showCrown: isWin,
                              );
                            },
                          ),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              _ResultBadge(isWin: isWin),
                            ],
                          ),
                          _AvatarCard(
                            assetPath: cpuAvatar,
                            label: '電腦',
                            score: widget.cpuScore,
                            color: Colors.red.shade300,
                            isWinner: !isWin,
                            showCrown: !isWin,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // 金錢變動提示
                    _MoneyDeltaBadge(delta: _moneyDelta),
                    const SizedBox(height: 16),

                    // 分數對比卡片
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _ScoreCompareCard(
                        playerScore: widget.playerScore,
                        cpuScore: widget.cpuScore,
                        isWin: isWin,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 按鈕區
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.replay_rounded,
                              label: '返回',
                              onTap: () => Navigator.of(context).pop(),
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.home_rounded,
                              label: '返回首頁',
                              onTap: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const HallPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 金錢變動徽章 ──────────────────────────────────────

class _MoneyDeltaBadge extends StatelessWidget {
  const _MoneyDeltaBadge({required this.delta});
  final int delta;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final color = isPositive ? Colors.amber.shade300 : Colors.red.shade300;
    final label = isPositive ? '+$delta 金幣' : '$delta 金幣';
    final icon = isPositive ? Icons.monetization_on : Icons.money_off;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 頭像卡片 ─────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.assetPath,
    required this.label,
    required this.score,
    required this.color,
    required this.isWinner,
    required this.showCrown,
  });

  final String assetPath;
  final String label;
  final int score;
  final Color color;
  final bool isWinner;
  final bool showCrown;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedOpacity(
          opacity: showCrown ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: const Text('👑', style: TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 4),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isWinner ? Colors.amber.shade400 : color,
              width: isWinner ? 3.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isWinner ? Colors.amber : color).withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image(
              image: PlayerAccount.getBattleAvatarImageProvider(assetPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  label[0],
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Text(
            '$score 分',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 勝負標語徽章 ──────────────────────────────────────

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.isWin});
  final bool isWin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: (isWin ? Colors.amber : Colors.grey).withOpacity(0.20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isWin ? Colors.amber : Colors.grey.shade400).withOpacity(
                0.6,
              ),
              width: 1.5,
            ),
          ),
          child: Text(
            isWin ? '你贏了' : '你輸了!',
            style: TextStyle(
              color: isWin
                  ? Colors.amber.shade300
                  : const Color.fromARGB(255, 250, 250, 250),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 分數對比卡片 ──────────────────────────────────────

class _ScoreCompareCard extends StatelessWidget {
  const _ScoreCompareCard({
    required this.playerScore,
    required this.cpuScore,
    required this.isWin,
  });

  final int playerScore;
  final int cpuScore;
  final bool isWin;

  @override
  Widget build(BuildContext context) {
    final total = (playerScore + cpuScore).abs();
    final playerRatio = total == 0
        ? 0.5
        : (playerScore / total).clamp(0.0, 1.0);
    final playerFlex = (playerRatio * 100).round().clamp(1, 99);
    final cpuFlex = 100 - playerFlex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '分數對比',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: playerFlex,
                  child: Container(height: 10, color: Colors.blue.shade400),
                ),
                Expanded(
                  flex: cpuFlex,
                  child: Container(height: 10, color: Colors.red.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$playerScore',
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'VS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$cpuScore',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 按鈕元件 ──────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? Colors.white.withOpacity(0.90)
          : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.black87 : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.black87 : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
