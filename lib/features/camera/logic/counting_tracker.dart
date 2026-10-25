import 'dart:ui';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

// Внутреннее состояние точки между кадрами.
class _Dot {
  double centerX;
  double centerY;
  bool wasOnRight;

  _Dot({
    required this.centerX,
    required this.centerY,
    required this.wasOnRight,
  });
}

class CountingTracker {
  static const double lineFraction = 0.35;
  static const double matchRadius = 150.0;
  static const double hysteresisBand = 35.0;

  List<_Dot> _prevDots = [];

  // Сброс состояния при старте нового подсчета или перезапуске камеры
  void reset() {
    _prevDots = [];
  }

  // Основной метод обработки. Принимает уже отфильтрованные результаты YOLO.
  // Возвращает количество новых пересечений (0 или больше).
  int processResults(List<YOLOResult> filteredResults, Size viewSize) {
    if (viewSize.width <= 0) return 0;

    final lineX = viewSize.width * lineFraction;
    final leftEdge = lineX - hysteresisBand / 2;
    final rightEdge = lineX + hysteresisBand / 2;

    final currentDots = <_Dot>[];
    final usedPrevIdx = <int>{};
    int newCrossings = 0;

    for (final r in filteredResults) {
      final cx = r.boundingBox.center.dx;
      final cy = r.boundingBox.center.dy;

      int bestIdx = -1;
      double bestDistSq = double.infinity;

      // Ищем ближайшую точку из предыдущего кадра
      for (int i = 0; i < _prevDots.length; i++) {
        if (usedPrevIdx.contains(i)) continue;
        final p = _prevDots[i];
        final dx = p.centerX - cx;
        final dy = p.centerY - cy;
        final distSq = dx * dx + dy * dy;
        if (distSq < bestDistSq) {
          bestDistSq = distSq;
          bestIdx = i;
        }
      }

      final matched = bestIdx >= 0 && bestDistSq < matchRadius * matchRadius;

      bool nowOnRight;
      if (cx >= rightEdge) {
        nowOnRight = true;
      } else if (cx <= leftEdge) {
        nowOnRight = false;
      } else {
        nowOnRight = matched ? _prevDots[bestIdx].wasOnRight : cx >= lineX;
      }

      if (matched) {
        usedPrevIdx.add(bestIdx);
        final prevWasOnRight = _prevDots[bestIdx].wasOnRight;
        
        // Фиксация пересечения справа налево
        if (prevWasOnRight && !nowOnRight) {
          newCrossings++;
        }
      }

      currentDots.add(_Dot(
        centerX: cx,
        centerY: cy,
        wasOnRight: nowOnRight,
      ));
    }

    _prevDots = currentDots;
    return newCrossings;
  }
}