import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Экран, который отображается после успешного сохранения результата.
class SavedScreen extends StatelessWidget {
  final int savedCount;

  const SavedScreen({super.key, required this.savedCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.cyan,
                size: 60,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Сохранено',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$savedCount ${_plural(savedCount)}',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'Детекция остановлена.\nЧтобы начать новый подсчёт,\nвыйдите и зайдите заново.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _plural(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'изделие';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'изделия';
    }
    return 'изделий';
  }
}