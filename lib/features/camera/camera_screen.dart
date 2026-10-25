import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart' hide ZoomIndicator;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/history_storage.dart';
import '../../../data/settings_storage.dart';
import 'logic/counting_tracker.dart';
import 'widgets/camera_hud.dart';
import 'widgets/camera_buttons.dart';
import 'widgets/setup_overlay.dart';
import 'widgets/fullscreen_overlay.dart';
import 'widgets/saved_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Настройки, не относящиеся к математике подсчета
  static const double _lineWidth = 3.0;
  static const double _minConfidence = 0.6;
  static const int _skipFrames = 5;

  // Зум
  double _initialZoom = 6.0;
  double _baseZoom = 6.0;
  static const double _minZoom = 1.0;
  static const double _maxZoom = 10.0;

  // Трекер для подсчета. Вся математика инкапсулирована в нем.
  final _tracker = CountingTracker();

  // Состояния экрана
  bool _cameraReady = false;
  bool _detectionStopped = false;
  bool _counterFullscreen = false;
  bool _zoomApplied = false;
  int _savedCount = 0;

  late final YOLOViewController _controller;

  bool _permissionGranted = false;
  String? _modelPath;
  String _status = 'Инициализация...';

  Size _viewSize = Size.zero;

  // FPS
  final List<DateTime> _frameTimestamps = [];
  static const int _fpsWindow = 30;
  DateTime _lastFpsUpdate = DateTime.now();

  // ValueNotifier для точечного обновления UI без перерисовки всего экрана
  final _countNotifier = ValueNotifier<int>(0);
  final _trackedNotifier = ValueNotifier<List<YOLOResult>>([]);
  final _zoomNotifier = ValueNotifier<double>(6.0);
  final _fpsNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _controller = YOLOViewController();
    _init();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _countNotifier.dispose();
    _trackedNotifier.dispose();
    _zoomNotifier.dispose();
    _fpsNotifier.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _status = 'Нет разрешения на камеру');
      return;
    }

    WakelockPlus.enable();

    try {
      setState(() => _status = 'Копирование модели...');
      final byteData = await rootBundle
          .load('assets/models/rezec_road_2210_640px.tflite');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/rezec_road_2210_640px.tflite');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      final savedZoom = await SettingsStorage.getInitialZoom();

      setState(() {
        _modelPath = file.path;
        _permissionGranted = true;
        _status = 'Готово';
        _initialZoom = savedZoom;
        _baseZoom = savedZoom;
        _zoomNotifier.value = savedZoom;
      });
    } catch (e) {
      setState(() => _status = 'Ошибка: $e');
    }
  }

  void _tickFps() {
    final now = DateTime.now();
    _frameTimestamps.add(now);

    while (_frameTimestamps.length > _fpsWindow) {
      _frameTimestamps.removeAt(0);
    }

    if (now.difference(_lastFpsUpdate).inMilliseconds >= 500 &&
        _frameTimestamps.length >= 2) {
      final elapsed = _frameTimestamps.last
          .difference(_frameTimestamps.first)
          .inMilliseconds;
      if (elapsed > 0) {
        final newFps = (_frameTimestamps.length - 1) * 1000 / elapsed;
        _lastFpsUpdate = now;
        _fpsNotifier.value = newFps;
      }
    }
  }

  // Главный коллбэк от YOLO. Вызывается на каждый обработанный кадр.
  void _onResults(List<YOLOResult> results) {
    // Однократно применяем сохраненный зум при первом кадре
    if (!_zoomApplied) {
      _zoomApplied = true;
      try {
        _controller.setZoomLevel(_initialZoom);
        _zoomNotifier.value = _initialZoom;
      } catch (_) {
        _zoomApplied = false;
      }
    }

    if (!_cameraReady || _detectionStopped) {
      _trackedNotifier.value = [];
      return;
    }

    // Фильтруем по порогу уверенности
    final filtered = results
        .where((r) => r.confidence >= _minConfidence)
        .toList();

    _tickFps();

    // Отдаем точки трекеру. Он вернет количество новых пересечений линии.
    if (_viewSize.width > 0) {
      final crossedCount = _tracker.processResults(filtered, _viewSize);
      if (crossedCount > 0) {
        _countNotifier.value += crossedCount;
      }
    }

    _trackedNotifier.value = filtered;
  }

  void _onCameraReady() {
    setState(() {
      _cameraReady = true;
      _tracker.reset(); // Сбрасываем старые точки при старте
      _countNotifier.value = 0;
      _frameTimestamps.clear();
      _fpsNotifier.value = 0.0;
    });
  }

  Future<void> _saveAndStop() async {
    final count = _countNotifier.value;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нечего сохранять — счётчик пуст'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await HistoryStorage.add(DateTime.now(), count);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _savedCount = count;
      _detectionStopped = true;
      _trackedNotifier.value = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Сохранено: $count изделий'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.blueDark,
      ),
    );
  }

  void _toggleFullscreenCounter() {
    setState(() => _counterFullscreen = !_counterFullscreen);
  }

  // Управление зумом (жесты и кнопки)
  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _zoomNotifier.value;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_detectionStopped || _counterFullscreen) return;
    final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    _controller.setZoomLevel(newZoom);
    _zoomNotifier.value = newZoom;
  }

  void _zoomIn() {
    final newZoom = (_zoomNotifier.value + 0.5).clamp(_minZoom, _maxZoom);
    _controller.setZoomLevel(newZoom);
    _zoomNotifier.value = newZoom;
  }

  void _zoomOut() {
    final newZoom = (_zoomNotifier.value - 0.5).clamp(_minZoom, _maxZoom);
    _controller.setZoomLevel(newZoom);
    _zoomNotifier.value = newZoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.blueDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleSpacing: 0,
        // Кнопка "Назад" появляется только когда открыт полноэкранный счетчик
        leading: (_counterFullscreen && _cameraReady && !_detectionStopped)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 26),
                tooltip: 'Назад к камере',
                onPressed: _toggleFullscreenCounter,
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Счетчик изделий ЦЕХ №8',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: !_permissionGranted || _modelPath == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _status,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _detectionStopped
              // Экран успешного сохранения
              ? SavedScreen(savedCount: _savedCount)
              // Рабочий экран с камерой
              : Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                            constraints.maxWidth, constraints.maxHeight);
                        // Слушаем изменения размера вьюпорта (например, при повороте экрана)
                        if (_viewSize != size) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _viewSize = size);
                          });
                        }
                        return Stack(
                          children: [
                            GestureDetector(
                              onScaleStart: _onScaleStart,
                              onScaleUpdate: _onScaleUpdate,
                              child: YOLOView(
                                modelPath: _modelPath!,
                                controller: _controller,
                                useGpu: true,
                                cameraResolution: '480p',
                                streamingConfig: YOLOStreamingConfig(
                                  skipFrames: _skipFrames,
                                ),
                                onResult: _onResults,
                              ),
                            ),

                            // Фаза настройки камеры (до нажатия "Готово")
                            if (!_cameraReady) ...[
                              Positioned(
                                top: 16,
                                left: 16,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _zoomNotifier,
                                  builder: (context, zoom, _) =>
                                      ZoomIndicator(zoom: zoom),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ZoomButton(
                                          icon: Icons.add, onPressed: _zoomIn),
                                      const SizedBox(height: 10),
                                      ZoomButton(
                                          icon: Icons.remove,
                                          onPressed: _zoomOut),
                                    ],
                                  ),
                                ),
                              ),
                              SetupOverlay(onReady: _onCameraReady),
                            ],

                            // Фаза активного подсчета
                            if (_cameraReady) ...[
                              CountingLine(
                                size: size,
                                lineWidth: _lineWidth,
                                lineFraction: CountingTracker.lineFraction,
                              ),

                              if (!_detectionStopped) const CountingIndicator(),

                              ValueListenableBuilder<List<YOLOResult>>(
                                valueListenable: _trackedNotifier,
                                builder: (context, tracked, _) {
                                  return CenterDotsOverlay(results: tracked);
                                },
                              ),

                              Positioned(
                                top: 16,
                                right: 16,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _countNotifier,
                                  builder: (context, count, _) =>
                                      CounterBadge(count: count),
                                ),
                              ),

                              Positioned(
                                top: 16,
                                left: 16,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _fpsNotifier,
                                  builder: (context, fps, _) =>
                                      FpsBadge(fps: fps),
                                ),
                              ),

                              Positioned(
                                top: 60,
                                left: 16,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _zoomNotifier,
                                  builder: (context, zoom, _) =>
                                      ZoomIndicator(zoom: zoom),
                                ),
                              ),

                              Positioned(
                                bottom: 24,
                                left: 16,
                                right: 16,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _countNotifier,
                                        builder: (context, count, _) {
                                          return SaveButton(
                                            count: count,
                                            onTap: _saveAndStop,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CounterScreenButton(
                                        onTap: _toggleFullscreenCounter,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Positioned(
                                bottom: 150,
                                right: 16,
                                child: Column(
                                  children: [
                                    ZoomButton(
                                        icon: Icons.add, onPressed: _zoomIn),
                                    const SizedBox(height: 8),
                                    ZoomButton(
                                        icon: Icons.remove,
                                        onPressed: _zoomOut),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    // Полноэкранный оверлей поверх камеры
                    if (_counterFullscreen &&
                        _cameraReady &&
                        !_detectionStopped)
                      ValueListenableBuilder<int>(
                        valueListenable: _countNotifier,
                        builder: (context, count, _) =>
                            FullscreenOverlay(count: count),
                      ),
                  ],
                ),
    );
  }
}