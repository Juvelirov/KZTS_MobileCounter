import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
// Пути к экранам обновлены под новую структуру папок
import '../camera/camera_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Градиент оставил оригинальный
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFEAF1FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Шестерёнка настроек
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.blue,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

              // Основное содержимое экрана
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withOpacity(0.18),
                              blurRadius: 32,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 160,
                          height: 160,
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Кировградский завод\nтвердых сплавов',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.3,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 56,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Счетчик изделий\nна базе искусственного интеллекта',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Кнопка Старт
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CameraScreen()),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: const Text('Старт'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(240, 62),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 52,
                            vertical: 18,
                          ),
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppColors.blue.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Кнопка История
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HistoryScreen()),
                          );
                        },
                        icon: const Icon(Icons.history_rounded, size: 24),
                        label: const Text('История'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(240, 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          foregroundColor: AppColors.blue,
                          side: const BorderSide(
                            color: AppColors.blue,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}