import 'package:flutter/material.dart';
import '/pages/hall_page.dart';
import 'pages/city_selection_page.dart';

void main() {
  // App entry point.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root widget wiring theme and initial page.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Duel',
      initialRoute: '/hall',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routes: {
        '/hall': (context) => const HallPage(),
        '/cities': (context) => const CitySelectionPage(),
      },
    );
  }
}
