import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Кнопка сохранения результата.
// Если count == 0, кнопка неактивна и затенена.
class SaveButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const SaveButton({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [AppColors.blue, AppColors.blueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.shade700,
                      Colors.grey.shade900,
                    ],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: AppColors.blueLight.withOpacity(0.4),
                      blurRadius: 22,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.save_alt_rounded,
                color: enabled ? Colors.white : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'СОХРАНИТЬ',
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Кнопка перехода в полноэкранный режим счетчика
class CounterScreenButton extends StatelessWidget {
  final VoidCallback onTap;

  const CounterScreenButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.cyan, AppColors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.cyan.withOpacity(0.4),
                blurRadius: 22,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'СЧЕТЧИК',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Круглая кнопка для ручной регулировки зума (+ / -)
class ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ZoomButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cyan.withOpacity(0.6), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: AppColors.cyan, size: 22),
        ),
      ),
    );
  }
}