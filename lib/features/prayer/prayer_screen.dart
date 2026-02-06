import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'prayer_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  late PrayerTimes _pt;
  late DateTime _dayAnchor;
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _dayAnchor = DateTime(_now.year, _now.month, _now.day);
    _pt = PrayerService.forCairo(_now);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      final newAnchor = DateTime(n.year, n.month, n.day);

      if (newAnchor != _dayAnchor) {
        _dayAnchor = newAnchor;
        _pt = PrayerService.forCairo(n);
      }

      setState(() => _now = n);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(DateTime t) => DateFormat('HH:mm', 'ar_EG').format(t);

  String _labelForPrayer(Prayer p) {
    switch (p) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.sunrise: return 'الشروق';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      default: return '';
    }
  }

  DateTime _timeForPrayer(Prayer p) => _pt.timeForPrayer(p);

  ({String name, DateTime time}) _nextEvent() {
    final next = _pt.nextPrayer();
    if (next != Prayer.none) {
      return (name: _labelForPrayer(next), time: _timeForPrayer(next));
    }
    // after Isha -> next is tomorrow Fajr
    final tomorrow = _now.add(const Duration(days: 1));
    final ptTomorrow = PrayerService.forCairo(tomorrow);
    return (name: 'الفجر', time: ptTomorrow.fajr);
  }

  String _countdown(DateTime target) {
    var d = target.difference(_now);
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextEvent();
    final todayStr = DateFormat('EEEE d MMMM y', 'ar_EG').format(_now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رمضان كريم'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeaderCard(todayStr: todayStr),
          const SizedBox(height: 12),

          _Card(
            title: 'القاهرة (أوفلاين)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوقت الآن: ${_fmt(_now)}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الصلاة القادمة: ${next.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      _countdown(next.time),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _Card(
            title: 'مواقيت اليوم',
            child: Column(
              children: [
                _TimeRow(name: 'الفجر', time: _fmt(_pt.fajr)),
                _TimeRow(name: 'الشروق', time: _fmt(_pt.sunrise)),
                _TimeRow(name: 'الظهر', time: _fmt(_pt.dhuhr)),
                _TimeRow(name: 'العصر', time: _fmt(_pt.asr)),
                _TimeRow(name: 'المغرب', time: _fmt(_pt.maghrib)),
                _TimeRow(name: 'العشاء', time: _fmt(_pt.isha)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String todayStr;
  const _HeaderCard({required this.todayStr});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'مرحبا يا رمضان',
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/logo.png',
              width: 86,
              height: 86,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              todayStr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String name;
  final String time;
  const _TimeRow({required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
          Text(time, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
