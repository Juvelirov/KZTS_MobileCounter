import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../../../core/theme/app_theme.dart';

// Линия, по которой считается переход
class CountingLine extends StatelessWidget {
  final Size size;
  final double lineWidth;
  final double lineFraction;

  const CountingLine({
    super.key,
    required this.size,
    required this.lineWidth,
    required this.lineFraction,
  });

  @override
  Widget build(BuildContext context) {
    final x = size.width * lineFraction;
    return Positioned(
      left: x - lineWidth / 2,
      top: 0,
      bottom: 0,
      width: lineWidth,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cyan.withOpacity(0.0),
                AppColors.cyan.withOpacity(0.95),
                AppColors.cyan.withOpacity(0.95),
                AppColors.cyan.withOpacity(0.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blueLight.withOpacity(0.65),
                blurRadius: 16,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Плашка с цифрой в правом верхнем углу
class CounterBadge extends StatelessWidget {
  final int count;

  const CounterBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.blue, AppColors.blueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.blueLight.withOpacity(0.45),
              blurRadius: 26,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ПРОШЛО',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: 1.35, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'изделий',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Индикатор fps
class FpsBadge extends StatelessWidget {
  final double fps;

  const FpsBadge({super.key, required this.fps});

  @override
  Widget build(BuildContext context) {
    final Color accent;
    if (fps >= 20) {
      accent = AppColors.cyan;
    } else if (fps >= 10) {
      accent = AppColors.blueLight;
    } else {
      accent = AppColors.blue;
    }

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.75), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.9),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FPS ${fps.toStringAsFixed(1)}',
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Индикатор текущего зума
class ZoomIndicator extends StatelessWidget {
  final double zoom;

  const ZoomIndicator({super.key, required this.zoom});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cyan.withOpacity(0.75), width: 1),
        ),
        child: Text(
          '${zoom.toStringAsFixed(1)}x',
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

// Точки в центре распознанных объектов
class CenterDotsOverlay extends StatelessWidget {
  final List<YOLOResult> results;

  const CenterDotsOverlay({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: results.map((r) {
        final center = r.boundingBox.center;
        return Positioned(
          left: center.dx - 9,
          top: center.dy - 9,
          child: IgnorePointer(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.cyan,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.9),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Мигающая плашка "ПОДСЧЕТ"
class CountingIndicator extends StatelessWidget {
  const CountingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: _BlinkingBadge(
          color: AppColors.green,
          text: 'ПОДСЧЕТ',
        ),
      ),
    );
  }
}

class _BlinkingBadge extends StatefulWidget {
  final Color color;
  final String text;

  const _BlinkingBadge({required this.color, required this.text});

  @override
  State<_BlinkingBadge> createState() => _BlinkingBadgeState();
}

class _BlinkingBadgeState extends State<_BlinkingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.6),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}