import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Полноэкранный оверлей со счетчиком.
// Накладывается поверх камеры, чтобы не прерывать процесс распознавания.
class FullscreenOverlay extends StatelessWidget {
  final int count;

  const FullscreenOverlay({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.blueDark,
        child: Stack(
          children: [
            // Крупные цифры по центру
            Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(count),
                tween: Tween(begin: 1.15, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 200,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Подпись внизу
            Positioned(
              left: 0,
              right: 0,
              bottom: 60,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'ИЗДЕЛИЙ ПРОШЛО',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}