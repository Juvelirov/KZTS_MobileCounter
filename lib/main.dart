import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/menu/main_menu_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'КЗТС: Счетчик изделий ЦЕХ №8',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        // Используем цвет из нашей новой темы
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
      ),
      home: const MainMenuScreen(),
    );
  }
}