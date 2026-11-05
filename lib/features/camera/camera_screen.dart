import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Пакет для озвучки
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart' hide ZoomIndicator;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:gal/gal.dart';

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

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  static const MethodChannel _recordChannel = MethodChannel('com.example.yolo_tracker_app_5x/screen_recorder');

  static const double _lineWidth = 3.0;
  static const double _minConfidence = 0.6;
  static const int _skipFrames = 5;

  double _initialZoom = 6.0;
  double _baseZoom = 6.0;
  static const double _minZoom = 1.0;
  static const double _maxZoom = 10.0;

  final _tracker = CountingTracker();

  bool _cameraReady = false;
  bool _detectionStopped = false;
  bool _counterFullscreen = false;
  bool _zoomApplied = false;
  int _savedCount = 0;

  late final YOLOViewController _controller;
  late final FlutterTts _flutterTts; // Объект для синтеза речи

  bool _permissionGranted = false;
  String? _modelPath;
  String _status = 'Инициализация...';

  Size _viewSize = Size.zero;

  final List<DateTime> _frameTimestamps = [];
  static const int _fpsWindow = 30;
  DateTime _lastFpsUpdate = DateTime.now();

  // --- ПЕРЕМЕННЫЕ ЗАПИСИ ЭКРАНА ---
  bool _isRecording = false;
  Timer? _screenRecordTimer;
  // ---------------------------------

  // --- ПЕРЕМЕННЫЕ АВТО-ЗАХВАТА КАДРОВ ---
  bool _isCapturing = false;
  bool _autoCaptureDisabled = false;
  int _capturedFrames = 0;
  Timer? _captureTimer;
  DateTime _lastDetectionTime = DateTime.now();
  // -------------------------------------

  // --- ПЕРЕМЕННАЯ ДЛЯ ОЗВУЧКИ ---
  Timer? _ttsTimer;
  // ------------------------------

  final _countNotifier = ValueNotifier<int>(0);
  final _trackedNotifier = ValueNotifier<List<YOLOResult>>([]);
  final _zoomNotifier = ValueNotifier<double>(6.0);
  final _fpsNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = YOLOViewController();
    
    // Инициализация TTS
    _flutterTts = FlutterTts();
    _initTts();

    _init();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _captureTimer?.cancel();
    _screenRecordTimer?.cancel();
    _ttsTimer?.cancel(); // Отменяем таймер озвучки
    _flutterTts.stop();  // Останавливаем речь при выходе
    
    if (_isRecording) {
      _recordChannel.invokeMethod('stopRecording');
    }
    _recordChannel.invokeMethod('stopProjection');

    if (!_detectionStopped && _countNotifier.value > 0) {
      SettingsStorage.setUnsavedCount(_countNotifier.value);
    }

    _countNotifier.dispose();
    _trackedNotifier.dispose();
    _zoomNotifier.dispose();
    _fpsNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (!_detectionStopped && _countNotifier.value > 0) {
        SettingsStorage.setUnsavedCount(_countNotifier.value);
      }
    }
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
      final byteData = await rootBundle.load('assets/models/rezec_road_2210_640px.tflite');
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

    if (now.difference(_lastFpsUpdate).inMilliseconds >= 500 && _frameTimestamps.length >= 2) {
      final elapsed = _frameTimestamps.last.difference(_frameTimestamps.first).inMilliseconds;
      if (elapsed > 0) {
        final newFps = (_frameTimestamps.length - 1) * 1000 / elapsed;
        _lastFpsUpdate = now;
        _fpsNotifier.value = newFps;
      }
    }
  }

  // --- ЛОГИКА ЗАПИСИ ЭКРАНА ---
  Future<void> _startScreenRecording() async {
    if (_isRecording) return;
    try {
      await _recordChannel.invokeMethod('startRecording');
      setState(() => _isRecording = true);
      debugPrint('Запись экрана запущена');
    } catch (e) {
      debugPrint('ОШИБКА ЗАПУСКА ЗАПИСИ: $e');
    }
  }

  Future<void> _stopScreenRecording() async {
    if (!_isRecording) return;
    _screenRecordTimer?.cancel();
    try {
      await _recordChannel.invokeMethod('stopRecording');
      setState(() => _isRecording = false);
      debugPrint('Запись экрана остановлена');
    } catch (e) {
      debugPrint('ОШИБКА ОСТАНОВКИ ЗАПИСИ: $e');
    }
  }

  void _resetScreenRecordTimer() {
    _screenRecordTimer?.cancel();
    _screenRecordTimer = Timer(const Duration(seconds: 180), () {
      if (_isRecording) {
        debugPrint('Таймаут 3 минуты без инкрементов. Останавливаем запись.');
        _stopScreenRecording();
      }
    });
  }
  // -------------------------------------

  // --- ЛОГИКА АВТО-ЗАХВАТА КАДРОВ ---
  void _triggerAutoCapture() {
    if (_isCapturing || _autoCaptureDisabled) return;

    _isCapturing = true;
    _capturedFrames = 0;

    _captureAndSaveFrame();
    _capturedFrames++;

    _captureTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (DateTime.now().difference(_lastDetectionTime).inMinutes >= 2) {
        timer.cancel();
        _isCapturing = false;
        _autoCaptureDisabled = true;
        return;
      }

      await _captureAndSaveFrame();
      _capturedFrames++;

      if (_capturedFrames >= 10) {
        timer.cancel();
        _isCapturing = false;
        _autoCaptureDisabled = true;
      }
    });
  }

  Future<void> _captureAndSaveFrame() async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      final Uint8List? photoBytes = await _controller.capturePhoto(withOverlays: false);

      if (photoBytes != null) {
        await Gal.putImageBytes(
          photoBytes,
          name: 'yolo_capture_${DateTime.now().millisecondsSinceEpoch}',
        );
        debugPrint('Чистый кадр сохранен в галерею!');
      }
    } catch (e) {
      debugPrint('Ошибка сохранения кадра: $e');
    }
  }
  // -------------------------------------

  void _onResults(List<YOLOResult> results) {
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

    final filtered = results.where((r) => r.confidence >= _minConfidence).toList();

    _tickFps();

    if (_viewSize.width > 0) {
      final crossedCount = _tracker.processResults(filtered, _viewSize);
      
      if (crossedCount > 0) {
        _countNotifier.value += crossedCount;
        SettingsStorage.setUnsavedCount(_countNotifier.value);
        _lastDetectionTime = DateTime.now();
        
        if (!_isRecording) {
          _startScreenRecording();
        }
        _resetScreenRecordTimer();
        
        if (!_isCapturing && !_autoCaptureDisabled) {
          _triggerAutoCapture();
        }
      }
    }

    _trackedNotifier.value = filtered;
  }

  void _onCameraReady() async {
    setState(() {
      _cameraReady = true;
      _tracker.reset();
      _countNotifier.value = 0;
      _frameTimestamps.clear();
      _fpsNotifier.value = 0.0;
      
      _isCapturing = false;
      _autoCaptureDisabled = false;
      _capturedFrames = 0;
      _captureTimer?.cancel();
    });
    
    SettingsStorage.clearUnsavedSession();

    // Таймер на озвучку через 10 секунд
    _ttsTimer?.cancel();
    _ttsTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _cameraReady && !_detectionStopped) {
        _flutterTts.speak('Режим подсчета изделий активирован. Не перекрывайте видимость камеры!');
      }
    });

    // Показываем инструкцию ПЕРЕД системным запросом
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Внимание'),
        content: const Text(
          'Сейчас появится системное окно запроса разрешения на запись экрана.\n\n'
          'Пожалуйста, нажмите «Начать», чтобы приложение могло вести запись конвейера.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Понятно', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    try {
      await _recordChannel.invokeMethod('requestPermission');
      debugPrint('Запрошено разрешение на запись экрана');
    } catch (e) {
      debugPrint('Ошибка запроса разрешения: $e');
    }
  }

  Future<void> _saveAndStop() async {
    final count = _countNotifier.value;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нечего сохранять — счётчик пуст'), duration: Duration(seconds: 2)),
      );
      return;
    }

    try {
      await HistoryStorage.add(DateTime.now(), count);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      return;
    }

    if (!mounted) return;
    
    _captureTimer?.cancel();
    _screenRecordTimer?.cancel();
    _ttsTimer?.cancel(); // Отменяем озвучку, если сохранили до 10 секунд
    _flutterTts.stop();
    await SettingsStorage.clearUnsavedSession();
    
    await _stopScreenRecording();
    await _recordChannel.invokeMethod('stopProjection');

    setState(() {
      _savedCount = count;
      _detectionStopped = true;
      _trackedNotifier.value = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сохранено: $count изделий'), duration: const Duration(seconds: 2), backgroundColor: AppColors.blueDark),
    );
  }

  void _toggleFullscreenCounter() {
    setState(() => _counterFullscreen = !_counterFullscreen);
  }

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
        leading: (_counterFullscreen && _cameraReady && !_detectionStopped)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 26),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.contain)),
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
                child: Text(_status, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
              ),
            )
          : _detectionStopped
              ? SavedScreen(savedCount: _savedCount)
              : Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
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
                                streamingConfig: YOLOStreamingConfig(skipFrames: _skipFrames),
                                onResult: _onResults,
                              ),
                            ),
                            if (!_cameraReady) ...[
                              Positioned(
                                top: 16, left: 16,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _zoomNotifier,
                                  builder: (context, zoom, _) => ZoomIndicator(zoom: zoom),
                                ),
                              ),
                              Positioned(
                                right: 16, top: 0, bottom: 0,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ZoomButton(icon: Icons.add, onPressed: _zoomIn),
                                      const SizedBox(height: 10),
                                      ZoomButton(icon: Icons.remove, onPressed: _zoomOut),
                                    ],
                                  ),
                                ),
                              ),
                              SetupOverlay(onReady: _onCameraReady),
                            ],
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
                                top: 16, right: 16,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _countNotifier,
                                  builder: (context, count, _) => CounterBadge(count: count),
                                ),
                              ),
                              Positioned(
                                top: 16, left: 16,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _fpsNotifier,
                                  builder: (context, fps, _) => FpsBadge(fps: fps),
                                ),
                              ),
                              Positioned(
                                top: 60, left: 16,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _zoomNotifier,
                                  builder: (context, zoom, _) => ZoomIndicator(zoom: zoom),
                                ),
                              ),
                              Positioned(
                                bottom: 24, left: 16, right: 16,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _countNotifier,
                                        builder: (context, count, _) {
                                          return SaveButton(count: count, onTap: _saveAndStop);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: CounterScreenButton(onTap: _toggleFullscreenCounter)),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 150, right: 16,
                                child: Column(
                                  children: [
                                    ZoomButton(icon: Icons.add, onPressed: _zoomIn),
                                    const SizedBox(height: 8),
                                    ZoomButton(icon: Icons.remove, onPressed: _zoomOut),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    if (_counterFullscreen && _cameraReady && !_detectionStopped)
                      ValueListenableBuilder<int>(
                        valueListenable: _countNotifier,
                        builder: (context, count, _) => FullscreenOverlay(count: count),
                      ),
                  ],
                ),
    );
  }
}