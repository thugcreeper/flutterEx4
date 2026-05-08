# flutter_interesting_game

專案架構如下：

```text
flutter_interesting_game/
├── lib/
│   ├── main.dart                     
│   ├── data/
│   │   └── demo_data.dart #題目、城市資料
│   ├── models/
│   │   ├── city.dart
│   │   ├── player_account.dart
│   │   └── question.dart
│   ├── pages/
│   │   ├── city_selection_page.dart
│   │   ├── game_page.dart
│   │   ├── hall_page.dart #大廳/入口頁面
│   │   ├── profile_page.dart
│   │   └── result_page.dart #對戰結果頁面
│   └── widgets/
│       ├── circular_timer_progress.dart 
│       ├── city_card.dart
│       ├── lvlAndMoneyBanner.dart #上方顯示金錢與等級的widget
│       ├── question_card.dart
│       ├── score_bar.dart #玩家、機器人的分數條
├── assets/
│   ├── audios/
│   └── images/
│       ├── appIcon.png
│       ├── avatar/
│       ├── cityBg/
│       ├── hall/
│       ├── icons/
│       └── songQuestion/
└── pubspec.yaml
```

