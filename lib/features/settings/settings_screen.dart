import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/settings_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Фиксированные шаги зума
  static const List<double> _zoomOptions = [
    1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,
    5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0,
  ];

  double _selectedZoom = 6.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final zoom = await SettingsStorage.getInitialZoom();
    if (!mounted) return;
    setState(() {
      _selectedZoom = zoom;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await SettingsStorage.setInitialZoom(_selectedZoom);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Сохранено: начальное приближение ${_selectedZoom.toStringAsFixed(1)}x',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.blueDark,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickZoom() async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Начальное приближение',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blueDark,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _zoomOptions.length,
                  itemBuilder: (ctx, i) {
                    final z = _zoomOptions[i];
                    final selected = z == _selectedZoom;
                    return ListTile(
                      title: Text(
                        '${z.toStringAsFixed(1)}x',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected
                              ? AppColors.blue
                              : AppColors.textDark,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.blue,
                            )
                          : null,
                      onTap: () => Navigator.pop(ctx, z),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedZoom = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
            const Text(
              'Настройки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.blueDark,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Установка начального приближения',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickZoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.blue.withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.zoom_in_rounded,
                              color: AppColors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                '${_selectedZoom.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppColors.blue,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Значение применяется при запуске камеры',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_alt_rounded, size: 22),
                      label: const Text('Сохранить'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: AppColors.blue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
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