// palyer_account資料類別，管理user的金錢和等級
import 'package:flutter/foundation.dart';

class PlayerAccount {
  //value notifier 是一種簡單的狀態管理工具，可以讓我們在數據變化時通知 UI 更新
  static final ValueNotifier<int> money = ValueNotifier<int>(500); //初始金額為500
  static final ValueNotifier<int> level = ValueNotifier<int>(1);

  static void addMoney(int amount) {
    if (amount <= 0) return;
    money.value += amount;
  }

  static bool spend(int amount) {
    if (amount <= 0) return true;
    if (money.value < amount) return false;
    money.value -= amount;
    return true;
  }
}
