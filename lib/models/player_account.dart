// palyer_account資料類別，管理user的金錢、等級和經驗
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlayerAccount {
  //value notifier 是一種簡單的狀態管理工具，可以讓我們在數據變化時通知 UI 更新
  static final ValueNotifier<int> money = ValueNotifier<int>(500); //初始金額為500
  static final ValueNotifier<int> level = ValueNotifier<int>(1);
  static final ValueNotifier<int> experience = ValueNotifier<int>(0); //目前經驗值
  static final ValueNotifier<int> battleTotal = ValueNotifier<int>(0);
  static final ValueNotifier<int> battleWins = ValueNotifier<int>(0);
  static final ValueNotifier<int> battleLosses = ValueNotifier<int>(0);
  static final ValueNotifier<String?> battleAvatar = ValueNotifier<String?>(
    null,
  );
  static final ValueNotifier<int> bankValue = ValueNotifier<int>(0);
  static const String defaultBattleAvatar = 'assets/images/avatar/me.png';
  static const int bankMax = 200;
  static Timer? _bankTimer;

  // 計算達到某個等級所需的總經驗值
  // 公式：基數 * (等級 - 1)^1.5，隨等級提高而增加
  static int getRequiredExpForLevel(int lv) {
    if (lv <= 1) return 0;
    const baseExp = 200;
    return (baseExp * ((lv - 1) * (lv - 1) * 1.5)).toInt();
  }

  // 獲取當前等級所需的總經驗值
  static int getCurrentLevelRequiredExp() {
    return getRequiredExpForLevel(level.value);
  }

  // 獲取下一個等級所需的總經驗值
  static int getNextLevelRequiredExp() {
    return getRequiredExpForLevel(level.value + 1);
  }

  // 根據累積經驗值直接推算目前等級，避免同步 while 迴圈造成主執行緒卡住
  static int getLevelForExperience(int exp) {
    if (exp <= 0) return 1;

    final estimated = math.sqrt(exp / 300).floor() + 1;
    var levelGuess = estimated < 1 ? 1 : estimated;

    while (getRequiredExpForLevel(levelGuess + 1) <= exp) {
      levelGuess += 1;
    }

    while (levelGuess > 1 && getRequiredExpForLevel(levelGuess) > exp) {
      levelGuess -= 1;
    }

    return levelGuess;
  }

  // 獲取當前進度條百分比 (0.0 - 1.0)
  static double getExpProgress() {
    int currentRequired = getCurrentLevelRequiredExp();
    int nextRequired = getNextLevelRequiredExp();
    int expInCurrentLevel = experience.value - currentRequired;
    int expNeededForNextLevel = nextRequired - currentRequired;

    if (expNeededForNextLevel <= 0) return 0.0;
    return (expInCurrentLevel / expNeededForNextLevel).clamp(0.0, 1.0);
  }

  // 增加經驗值，會自動處理升級
  static void addExperience(int amount) {
    if (amount <= 0) return;
    experience.value += amount;
    level.value = getLevelForExperience(experience.value);
  }

  // 升級
  static void levelUp() {
    level.value += 1;
  }

  static void recordBattle(bool isWin) {
    battleTotal.value += 1;
    if (isWin) {
      battleWins.value += 1;
    } else {
      battleLosses.value += 1;
    }
  }

  static String getCurrentBattleAvatar() {
    return battleAvatar.value ?? defaultBattleAvatar;
  }

  static ImageProvider getBattleAvatarImageProvider([String? avatarPath]) {
    final resolvedPath = avatarPath ?? getCurrentBattleAvatar();
    if (resolvedPath.startsWith('assets/')) {
      return AssetImage(resolvedPath);
    }
    return FileImage(File(resolvedPath));
  }

  static void setBattleAvatar(String? avatarAssetPath) {
    battleAvatar.value = avatarAssetPath;
  }

  // 對戰成功：獲得 100-150 經驗
  static void battleWin() {
    final expGain = 100 + (DateTime.now().millisecond % 51); // 100-150
    addExperience(expGain);
  }

  // 對戰失敗：獲得 20 經驗
  static void battleLose() {
    addExperience(20);
  }

  static void addMoney(int amount) {
    if (amount <= 0) return;
    money.value += amount;
  }

  //銀行進度和計時器不再掛在 hall_page.dart 的頁面 state 上，
  //而是移到 player_account.dart 裡統一管理，所以你從對戰頁回到首頁時，
  //銀行不會因為 HallPage 重建就歸零。
  static void ensureBankTimer() {
    if (_bankTimer?.isActive ?? false) return;
    _bankTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (bankValue.value < bankMax) {
        bankValue.value += 1;
      } else {
        timer.cancel();
      }
    });
  }

  static int collectBankMoney() {
    final collected = bankValue.value;
    bankValue.value = 0;
    ensureBankTimer();
    return collected;
  }

  static bool spend(int amount) {
    if (amount <= 0) return true;
    if (money.value < amount) return false;
    money.value -= amount;
    return true;
  }
}
