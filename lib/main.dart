import 'dart:async';
import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(RamadanKareemApp(settings: settings));
}

class RamadanKareemApp extends StatefulWidget {
  const RamadanKareemApp({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<RamadanKareemApp> createState() => _RamadanKareemAppState();
}

class _RamadanKareemAppState extends State<RamadanKareemApp> {
  late AppSettings settings;

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
  }

  void updateSettings(AppSettings next) async {
    setState(() => settings = next);
    await next.save();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رمضان كريم',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B6E4F),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MainShell(
          settings: settings,
          onSettingsChanged: updateSettings,
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(settings: widget.settings),
      PrayerScreen(settings: widget.settings),
      LibraryScreen(),
      SettingsScreen(settings: widget.settings, onChanged: widget.onSettingsChanged),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.mosque_rounded), label: 'الصلاة'),
          NavigationDestination(icon: Icon(Icons.menu_book_rounded), label: 'المكتبة'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.lat,
    required this.lon,
    required this.methodKey,
    required this.madhabKey,
    required this.use24h,
  });

  final double lat;
  final double lon;
  final String methodKey; // "egyptian" ...
  final String madhabKey; // "shafi" | "hanafi"
  final bool use24h;

  static const _kLat = 'lat';
  static const _kLon = 'lon';
  static const _kMethod = 'method';
  static const _kMadhab = 'madhab';
  static const _k24h = 'use24h';

  static AppSettings defaults() => const AppSettings(
        lat: 30.0444, // Cairo
        lon: 31.2357,
        methodKey: 'egyptian',
        madhabKey: 'shafi',
        use24h: true,
      );

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final d = defaults();
    return AppSettings(
      lat: p.getDouble(_kLat) ?? d.lat,
      lon: p.getDouble(_kLon) ?? d.lon,
      methodKey: p.getString(_kMethod) ?? d.methodKey,
      madhabKey: p.getString(_kMadhab) ?? d.madhabKey,
      use24h: p.getBool(_k24h) ?? d.use24h,
    );
    }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLat, lat);
    await p.setDouble(_kLon, lon);
    await p.setString(_kMethod, methodKey);
    await p.setString(_kMadhab, madhabKey);
    await p.setBool(_k24h, use24h);
  }

  CalculationParameters toCalculationParameters() {
    CalculationParameters params;
    switch (methodKey) {
      case 'muslim_world_league':
        params = CalculationMethodParameters.muslimWorldLeague()();
        break;
      case 'karachi':
        params = CalculationMethodParameters.karachi();
        break;
      case 'umm_al_qura':
        params = CalculationMethodParameters.ummAlQura()();
        break;
      case 'dubai':
        params = CalculationMethodParameters.dubai();
        break;
      case 'qatar':
        params = CalculationMethodParameters.qatar();
        break;
      case 'kuwait':
        params = CalculationMethodParameters.kuwait();
        break;
      case 'singapore':
        params = CalculationMethodParameters.singapore();
        break;
      case 'north_america':
        params = CalculationMethodParameters.northAmerica()();
        break;
      case 'turkey':
        params = CalculationMethodParameters.turkiye()();
        break;
      case 'tehran':
        params = CalculationMethodParameters.tehran();
        break;
      case 'other':
        params = CalculationMethodParameters.other();
        break;
      case 'egyptian':
      default:
        params = CalculationMethodParameters.egyptian();
    }

    params.madhab = (madhabKey == 'hanafi') ? Madhab.hanafi : Madhab.shafi;
    return params;
  }

  AppSettings copyWith({
    double? lat,
    double? lon,
    String? methodKey,
    String? madhabKey,
    bool? use24h,
  }) {
    return AppSettings(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      methodKey: methodKey ?? this.methodKey,
      madhabKey: madhabKey ?? this.madhabKey,
      use24h: use24h ?? this.use24h,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pt = PrayerService(settings: widget.settings).today();
    final next = PrayerService(settings: widget.settings).nextPrayerInfo(now, pt);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('رمضان كريم', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('مواعيد الصلاة  القاهرة (افتراضيا)', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),

          _card(
            context,
            title: 'الصلاة القادمة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(next.prayerNameAr, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('الوقت: ${formatTime(next.timeLocal, use24h: widget.settings.use24h)}'),
                const SizedBox(height: 6),
                Text('متبقي: ${formatDuration(next.remaining)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _card(
            context,
            title: 'مختصر اليوم',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip('الفجر', formatTime(pt.fajr.toLocal(), use24h: widget.settings.use24h)),
                _chip('الظهر', formatTime(pt.dhuhr.toLocal(), use24h: widget.settings.use24h)),
                _chip('المغرب (الإفطار)', formatTime(pt.maghrib.toLocal(), use24h: widget.settings.use24h)),
                _chip('العشاء', formatTime(pt.isha.toLocal(), use24h: widget.settings.use24h)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('الأقسام', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _menuTile(context, icon: Icons.mosque_rounded, title: 'الصلاة', onTap: () => _goTab(context, 1)),
              _menuTile(context, icon: Icons.menu_book_rounded, title: 'القرآن', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuranScreen()))),
              _menuTile(context, icon: Icons.favorite_rounded, title: 'الأذكار', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(assetPath: 'assets/data/adhkar_sample.json')))),
              _menuTile(context, icon: Icons.volunteer_activism_rounded, title: 'الأدعية', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(assetPath: 'assets/data/dua_sample.json')))),
              _menuTile(context, icon: Icons.auto_stories_rounded, title: 'أحاديث', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlatItemsScreen(assetPath: 'assets/data/hadith_sample.json')))),
              _menuTile(context, icon: Icons.lightbulb_rounded, title: 'سنن', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlatItemsScreen(assetPath: 'assets/data/sunnah_sample.json')))),
              _menuTile(context, icon: Icons.history_edu_rounded, title: 'قصص الأنبياء', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProphetsScreen()))),
              _menuTile(context, icon: Icons.settings_rounded, title: 'الإعدادات', onTap: () => _goTab(context, 3)),
            ],
          ),
        ],
      ),
    );
  }

  void _goTab(BuildContext context, int tabIndex) {
    final st = context.findAncestorStateOfType<_MainShellState>();
    if (st != null) st.setState(() => st.index = tabIndex);
  }
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final service = PrayerService(settings: widget.settings);
    final pt = service.today();
    final next = service.nextPrayerInfo(now, pt);

    final rows = [
      _PrayerRow('الفجر', pt.fajr.toLocal()),
      _PrayerRow('الشروق', pt.sunrise.toLocal()),
      _PrayerRow('الظهر', pt.dhuhr.toLocal()),
      _PrayerRow('العصر', pt.asr.toLocal()),
      _PrayerRow('المغرب', pt.maghrib.toLocal()),
      _PrayerRow('العشاء', pt.isha.toLocal()),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('مواعيد الصلاة', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('الموقع: القاهرة (lat ${widget.settings.lat}, lon ${widget.settings.lon})', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('اليوم: ${DateFormat('EEEE d MMMM', 'ar_EG').format(now)}', style: Theme.of(context).textTheme.bodyMedium),

          const SizedBox(height: 12),
          _card(
            context,
            title: 'الصلاة القادمة',
            child: Row(
              children: [
                Expanded(
                  child: Text('${next.prayerNameAr}  ${formatTime(next.timeLocal, use24h: widget.settings.use24h)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Text(formatDuration(next.remaining), style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _card(
            context,
            title: 'مواعيد اليوم',
            child: Column(
              children: rows.map((r) {
                final isNext = r.name == next.prayerNameAr;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.name, style: TextStyle(fontWeight: isNext ? FontWeight.w900 : FontWeight.w700)),
                  trailing: Text(formatTime(r.time, use24h: widget.settings.use24h),
                      style: TextStyle(fontWeight: isNext ? FontWeight.w900 : FontWeight.w700)),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          _card(
            context,
            title: 'رمضان',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('وقت السحور ينتهي غالبا عند: ${formatTime(pt.fajr.toLocal(), use24h: widget.settings.use24h)}'),
                const SizedBox(height: 6),
                Text('وقت الإفطار عند المغرب: ${formatTime(pt.maghrib.toLocal(), use24h: widget.settings.use24h)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _LibItem('القرآن', Icons.menu_book_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuranScreen()))),
      _LibItem('الأذكار', Icons.favorite_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(assetPath: 'assets/data/adhkar_sample.json')))),
      _LibItem('الأدعية', Icons.volunteer_activism_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(assetPath: 'assets/data/dua_sample.json')))),
      _LibItem('أحاديث', Icons.auto_stories_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlatItemsScreen(assetPath: 'assets/data/hadith_sample.json')))),
      _LibItem('سنن', Icons.lightbulb_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlatItemsScreen(assetPath: 'assets/data/sunnah_sample.json')))),
      _LibItem('قصص الأنبياء', Icons.history_edu_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProphetsScreen()))),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('المكتبة', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  leading: Icon(e.icon),
                  title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: e.onTap,
                ),
              )),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('الإعدادات', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          _card(
            context,
            title: 'الوقت',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('عرض 24 ساعة'),
              value: settings.use24h,
              onChanged: (v) => onChanged(settings.copyWith(use24h: v)),
            ),
          ),

          const SizedBox(height: 12),
          _card(
            context,
            title: 'المذهب (للعصر)',
            child: Column(
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('شافعي'),
                  value: 'shafi',
                  groupValue: settings.madhabKey,
                  onChanged: (v) => onChanged(settings.copyWith(madhabKey: v)),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('حنفي'),
                  value: 'hanafi',
                  groupValue: settings.madhabKey,
                  onChanged: (v) => onChanged(settings.copyWith(madhabKey: v)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _card(
            context,
            title: 'طريقة الحساب',
            child: DropdownButtonFormField<String>(
              value: settings.methodKey,
              items: const [
                DropdownMenuItem(value: 'egyptian', child: Text('Egyptian (مصر)')),
                DropdownMenuItem(value: 'muslim_world_league', child: Text('Muslim World League')),
                DropdownMenuItem(value: 'umm_al_qura', child: Text('Umm Al-Qura')),
                DropdownMenuItem(value: 'karachi', child: Text('Karachi')),
                DropdownMenuItem(value: 'north_america', child: Text('North America')),
                DropdownMenuItem(value: 'dubai', child: Text('Dubai')),
                DropdownMenuItem(value: 'qatar', child: Text('Qatar')),
                DropdownMenuItem(value: 'kuwait', child: Text('Kuwait')),
                DropdownMenuItem(value: 'singapore', child: Text('Singapore')),
                DropdownMenuItem(value: 'turkey', child: Text('Turkey')),
                DropdownMenuItem(value: 'tehran', child: Text('Tehran')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => onChanged(settings.copyWith(methodKey: v)),
            ),
          ),

          const SizedBox(height: 12),
          _card(
            context,
            title: 'الموقع',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('افتراضيا: القاهرة. تقدر تغير الإحداثيات يدويا.'),
                const SizedBox(height: 10),
                _CoordEditor(settings: settings, onChanged: onChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordEditor extends StatefulWidget {
  const _CoordEditor({required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<_CoordEditor> createState() => _CoordEditorState();
}

class _CoordEditorState extends State<_CoordEditor> {
  late final TextEditingController lat;
  late final TextEditingController lon;

  @override
  void initState() {
    super.initState();
    lat = TextEditingController(text: widget.settings.lat.toStringAsFixed(6));
    lon = TextEditingController(text: widget.settings.lon.toStringAsFixed(6));
  }

  @override
  void dispose() {
    lat.dispose();
    lon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: lat,
            decoration: const InputDecoration(labelText: 'Latitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: lon,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: () {
            final la = double.tryParse(lat.text.trim());
            final lo = double.tryParse(lon.text.trim());
            if (la == null || lo == null) return;
            widget.onChanged(widget.settings.copyWith(lat: la, lon: lo));
          },
          child: const Text('حفظ'),
        )
      ],
    );
  }
}

class PrayerService {
  PrayerService({required this.settings});
  final AppSettings settings;

  PrayerTimes today() {
    final coords = Coordinates(settings.lat, settings.lon);
    final params = settings.toCalculationParameters();
    return PrayerTimes(coordinates: coords, date: DateTime.now(), calculationParameters: params, precision: true);
  }

  NextPrayerInfo nextPrayerInfo(DateTime nowLocal, PrayerTimes pt) {
    final nowUtc = nowLocal.toUtc();
    final current = pt.currentPrayer(date: nowUtc);
    final next = pt.nextPrayer(date: nowUtc);

    final DateTime nextTimeUtc = (next != null ? pt.timeForPrayer(next) : null) ?? pt.fajr.add(const Duration(days: 1));
    final nextTimeLocal = nextTimeUtc.toLocal();

    final remaining = nextTimeLocal.difference(nowLocal).isNegative
        ? const Duration(seconds: 0)
        : nextTimeLocal.difference(nowLocal);

    return NextPrayerInfo(
      prayerNameAr: prayerNameAr(next ?? Prayer.fajr),
      timeLocal: nextTimeLocal,
      remaining: remaining,
      currentPrayerAr: prayerNameAr(current),
    );
  }
}

String prayerNameAr(Prayer p) {
  switch (p) {
    case Prayer.fajr:
      return 'الفجر';
    case Prayer.sunrise:
      return 'الشروق';
    case Prayer.dhuhr:
      return 'الظهر';
    case Prayer.asr:
      return 'العصر';
    case Prayer.maghrib:
      return 'المغرب';
    case Prayer.ishaBefore:
    case Prayer.isha:
      return 'العشاء';
    case Prayer.ishaBefore:
    case Prayer.isha:
      return '';
  }
}

String formatTime(DateTime t, {required bool use24h}) {
  final fmt = use24h ? DateFormat('HH:mm', 'ar_EG') : DateFormat('hh:mm a', 'ar_EG');
  return fmt.format(t);
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  String two(int x) => x.toString().padLeft(2, '0');
  if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}

Widget _card(BuildContext context, {required String title, required Widget child}) {
  return Card(
    elevation: 0,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

Widget _chip(String label, String value) {
  return Chip(
    label: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(width: 8),
      Text(value),
    ]),
  );
}

Widget _menuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class NextPrayerInfo {
  const NextPrayerInfo({
    required this.prayerNameAr,
    required this.timeLocal,
    required this.remaining,
    required this.currentPrayerAr,
  });

  final String prayerNameAr;
  final DateTime timeLocal;
  final Duration remaining;
  final String currentPrayerAr;
}

class _PrayerRow {
  _PrayerRow(this.name, this.time);
  final String name;
  final DateTime time;
}

/// ====== المحتوى (JSON) ======

Future<Map<String, dynamic>> loadJsonAsset(String path) async {
  final s = await rootBundle.loadString(path);
  return jsonDecode(s) as Map<String, dynamic>;
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.assetPath});
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: loadJsonAsset(assetPath),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!;
        final title = (data['title'] ?? 'المحتوى').toString();
        final cats = (data['categories'] as List? ?? const []);
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = cats[i] as Map<String, dynamic>;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                title: Text((c['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemsScreen(title: (c['name'] ?? '').toString(), items: (c['items'] as List? ?? const []))),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key, required this.title, required this.items});
  final String title;
  final List items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final it = items[i] as Map<String, dynamic>;
          final text = (it['text'] ?? '').toString();
          final ref = (it['ref'] ?? '').toString();
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w700)),
                  if (ref.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(ref, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FlatItemsScreen extends StatelessWidget {
  const FlatItemsScreen({super.key, required this.assetPath});
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: loadJsonAsset(assetPath),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snap.data!;
        final title = (data['title'] ?? 'المحتوى').toString();
        final items = (data['items'] as List? ?? const []);
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = items[i] as Map<String, dynamic>;
              final source = (it['source'] ?? it['topic'] ?? '').toString();
              final text = (it['text'] ?? '').toString();
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (source.isNotEmpty)
                        Text(source, style: const TextStyle(fontWeight: FontWeight.w900)),
                      if (source.isNotEmpty) const SizedBox(height: 8),
                      Text(text, style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ProphetsScreen extends StatelessWidget {
  const ProphetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: loadJsonAsset('assets/data/prophets_sample.json'),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snap.data!;
        final title = (data['title'] ?? 'قصص الأنبياء').toString();
        final items = (data['items'] as List? ?? const []);
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = items[i] as Map<String, dynamic>;
              final name = (it['name'] ?? '').toString();
              final text = (it['text'] ?? '').toString();
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryDetails(title: name, text: text))),
              );
            },
          ),
        );
      },
    );
  }
}

class StoryDetails extends StatelessWidget {
  const StoryDetails({super.key, required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(text, style: const TextStyle(fontSize: 16, height: 1.7, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: loadJsonAsset('assets/data/quran_sample.json'),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snap.data!;
        final surahs = (data['surahs'] as List? ?? const []);
        return Scaffold(
          appBar: AppBar(title: const Text('القرآن')),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: surahs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = surahs[i] as Map<String, dynamic>;
              final num = (s['number'] ?? '').toString();
              final name = (s['name'] ?? '').toString();
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                title: Text('$num  $name', style: const TextStyle(fontWeight: FontWeight.w900)),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahScreen(surah: s))),
              );
            },
          ),
        );
      },
    );
  }
}

class SurahScreen extends StatelessWidget {
  const SurahScreen({super.key, required this.surah});
  final Map<String, dynamic> surah;

  @override
  Widget build(BuildContext context) {
    final name = (surah['name'] ?? '').toString();
    final ayahs = (surah['ayahs'] as List? ?? const []);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ayahs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final a = ayahs[i] as Map<String, dynamic>;
          final num = (a['number'] ?? '').toString();
          final text = (a['text'] ?? '').toString();
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text('$num)  $text', style: const TextStyle(fontSize: 18, height: 1.9, fontWeight: FontWeight.w800)),
            ),
          );
        },
      ),
    );
  }
}

class _LibItem {
  _LibItem(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
}


