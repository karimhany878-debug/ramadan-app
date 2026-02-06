import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../prayer/prayer_service.dart';

class ScheduleScreen extends StatelessWidget {
  final int days;
  const ScheduleScreen({super.key, required this.days});

  String _fmt(DateTime t) => DateFormat('HH:mm', 'ar_EG').format(t);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الجدول (القاهرة)'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: days,
        itemBuilder: (context, i) {
          final d = start.add(Duration(days: i));
          final pt = PrayerService.forCairo(d);
          final dayTitle = DateFormat('EEEE d MMM', 'ar_EG').format(d);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Chip(label: 'فجر', value: _fmt(pt.fajr)),
                      _Chip(label: 'شروق', value: _fmt(pt.sunrise)),
                      _Chip(label: 'ظهر', value: _fmt(pt.dhuhr)),
                      _Chip(label: 'عصر', value: _fmt(pt.asr)),
                      _Chip(label: 'مغرب', value: _fmt(pt.maghrib)),
                      _Chip(label: 'عشاء', value: _fmt(pt.isha)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.55),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
