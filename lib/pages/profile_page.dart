import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/player_account.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLocalAvatar() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1024,
    );

    if (!mounted || pickedFile == null) {
      return;
    }

    PlayerAccount.setBattleAvatar(pickedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('個人資料')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ValueListenableBuilder<String?>(
                valueListenable: PlayerAccount.battleAvatar,
                builder: (_, selectedAvatar, __) {
                  final avatarPath =
                      selectedAvatar ?? PlayerAccount.defaultBattleAvatar;

                  return Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: PlayerAccount.getBattleAvatarImageProvider(
                              avatarPath,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedAvatar == null ? '目前使用預設頭像' : '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 28, thickness: 1.2),
            _SectionHeader(
              title: '頭像設定',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickLocalAvatar,
                    icon: const Icon(Icons.upload),
                    label: const Text('從本機上傳頭像'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => PlayerAccount.setBattleAvatar(null),
                    child: const Text('重設'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 28, thickness: 1.2),
            const _SectionHeader(title: '等級資訊'),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: PlayerAccount.level,
              builder: (_, level, __) {
                return Text('Lv. $level', style: const TextStyle(fontSize: 16));
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: PlayerAccount.experience,
              builder: (_, experience, __) {
                final currentRequired =
                    PlayerAccount.getCurrentLevelRequiredExp();
                final nextRequired = PlayerAccount.getNextLevelRequiredExp();
                final expInCurrentLevel = experience - currentRequired;
                final expNeededForNextLevel = nextRequired - currentRequired;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ' $expInCurrentLevel / $expNeededForNextLevel',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: PlayerAccount.getExpProgress(),
                        minHeight: 15,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.amber.shade400,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            const Divider(height: 28, thickness: 1.2),
            const _SectionHeader(title: '戰績分布'),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: PlayerAccount.battleTotal,
              builder: (_, totalBattles, __) {
                return ValueListenableBuilder<int>(
                  valueListenable: PlayerAccount.battleWins,
                  builder: (_, wins, ___) {
                    return ValueListenableBuilder<int>(
                      valueListenable: PlayerAccount.battleLosses,
                      builder: (_, losses, ____) {
                        final hasBattleData = totalBattles > 0;

                        return Column(
                          children: [
                            SizedBox(
                              height: 190,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 48,
                                  sectionsSpace: 2,
                                  sections: hasBattleData
                                      ? [
                                          PieChartSectionData(
                                            value: wins.toDouble(),
                                            color: Colors.green,
                                            radius: 24,
                                            title: '',
                                          ),
                                          PieChartSectionData(
                                            value: losses.toDouble(),
                                            color: Colors.red,
                                            radius: 24,
                                            title: '',
                                          ),
                                        ]
                                      : [
                                          PieChartSectionData(
                                            value: 1,
                                            color: Colors.grey.shade300,
                                            radius: 24,
                                            title: '',
                                          ),
                                        ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _BattleLegendItem(
                                  color: Colors.green,
                                  label: '勝場',
                                  value: wins,
                                ),
                                _BattleLegendItem(
                                  color: Colors.red,
                                  label: '敗場',
                                  value: losses,
                                ),
                                _BattleLegendItem(
                                  color: Colors.blueGrey,
                                  label: '總場',
                                  value: totalBattles,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            const Divider(height: 28, thickness: 1.2),
            const _SectionHeader(title: '財務資訊'),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: PlayerAccount.money,
              builder: (_, money, __) {
                return Text(
                  '\$$money',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _BattleLegendItem extends StatelessWidget {
  const _BattleLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label $value', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
