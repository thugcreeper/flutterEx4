// 選擇城市進行對戰的頁面，包含城市列表和倒數計時功能
import 'package:flutter/material.dart';
import 'package:flutter_interesting_game/models/player_account.dart';
import 'dart:async';
import '../models/city.dart';
import '../data/demo_data.dart';
import '../widgets/city_card.dart';
import 'game_page.dart';
import '../widgets/lvlAndMoneyBanner.dart';

class CitySelectionPage extends StatefulWidget {
  const CitySelectionPage({super.key});

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  CityLevel? _pendingCity;

  void _startCountdown(CityLevel city) {
    if (PlayerAccount.money.value < city.entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('金額不足，先去銀行領錢!!!', style: const TextStyle(fontSize: 24)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _pendingCity = city;
    });
  }

  void _cancelCountdown() {
    setState(() {
      _pendingCity = null;
    });
  }

  void _enterCity(CityLevel city) {
    // 扣除入場費用
    final ok = PlayerAccount.spend(city.entryFee);
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額不足，先去銀行領錢!!!')));
      setState(() {
        _pendingCity = null;
      });
      return;
    }
    setState(() {
      _pendingCity = null;
    });
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GamePage(city: city)));
  }

  @override
  Widget build(BuildContext context) {
    final cities = DemoData.cities;
    const pageBackgroundColor = Color.fromARGB(255, 255, 246, 234);
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        // Use title area to avoid cramped leading width.
        backgroundColor: Colors.white,
        title: Wrap(children: [const LvlAndMoneyBanner()]),
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: cities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final CityLevel city = cities[index];
              return CityCard(
                city: city,
                onSelect: (selected) {
                  _startCountdown(selected);
                },
              );
            },
          ),
          if (_pendingCity != null)
            _CountdownOverlay(
              cityName: _pendingCity!.name,
              onCancel: _cancelCountdown,
              onComplete: () => _enterCity(_pendingCity!),
            ),
        ],
      ),
    );
  }
}

//這是選擇程式後的倒數計時畫面
class _CountdownOverlay extends StatefulWidget {
  const _CountdownOverlay({
    required this.cityName,
    required this.onCancel,
    required this.onComplete,
  });

  final String cityName;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  @override
  State<_CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<_CountdownOverlay>
    with SingleTickerProviderStateMixin {
  //倒數5秒後開始
  static const int _startSeconds = 5;
  int _secondsLeft = _startSeconds;
  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    //這是用來控制倒數數字的縮放動畫
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.9, //縮小到90%
      upperBound: 1.1,
    )..repeat(reverse: true);
    // Auto-enter after countdown unless cancelled.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
      });
      if (_secondsLeft <= 0) {
        timer.cancel();
        widget.onComplete(); //倒數結束後進入遊戲
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //text rich是用來搭配textSpan的，讓不同部分的文字可以有不同的樣式
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '進入 ',
                      style: TextStyle(
                        color: Colors.white, // 或者您原本的預設顏色
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: widget.cityName,
                      style: const TextStyle(
                        color: Colors.orangeAccent, // 只對城市名套用橘色
                        fontSize: 26, // 稍微加大一點點可以增加視覺重點
                        fontWeight: FontWeight.bold, // 甚至可以更粗一點
                      ),
                    ),
                    const TextSpan(
                      text: '？',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),
              ScaleTransition(
                scale: _pulseController,
                child: Text(
                  '$_secondsLeft',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 254, 254, 254),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onCancel,
                child: const Text(
                  '取消',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
