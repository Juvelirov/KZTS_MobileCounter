import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/history_storage.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await HistoryStorage.load();
    // Сортируем по убыванию, чтобы свежие записи были сверху
    records.sort((a, b) {
      final ta = a['ts'] as int? ?? 0;
      final tb = b['ts'] as int? ?? 0;
      return tb.compareTo(ta);
    });
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Все записи будут удалены безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HistoryStorage.clear();
      await _load();
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
              'Просмотр истории',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.blueDark,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Очистить историю',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmpty()
              : _buildTable(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: AppColors.blue.withOpacity(0.35),
          ),
          const SizedBox(height: 20),
          const Text(
            'Пока нет записей',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Сохраняйте результаты\nпосле каждого подсчёта',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              AppColors.blue.withOpacity(0.08),
            ),
            headingTextStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.blueDark,
              letterSpacing: 0.3,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 15,
              color: AppColors.textDark,
            ),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('Дата')),
              DataColumn(label: Text('Время')),
              DataColumn(label: Text('Количество'), numeric: true),
            ],
            rows: _records.map((r) {
              return DataRow(cells: [
                DataCell(Text(r['date']?.toString() ?? '—')),
                DataCell(Text(r['time']?.toString() ?? '—')),
                DataCell(
                  Text(
                    '${r['count'] ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}