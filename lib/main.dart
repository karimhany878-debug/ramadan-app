import "dart:convert";
import "package:adhan/adhan.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:flutter_localizations/flutter_localizations.dart";
import "package:intl/intl.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RamadanKareemApp());
}

class RamadanKareemApp extends StatelessWidget {
  const RamadanKareemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "رمضان كريم",
      debugShowCheckedModeBanner: false,
      locale: const Locale("ar", "EG"),
      supportedLocales: const [Locale("ar", "EG"), Locale("en", "US")],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B6E69),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final progress = DailyProgress();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(progress: progress),
      const QuranPage(),
      const AdhkarPage(),
      const LibraryPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: "الجدول"),
          NavigationDestination(icon: Icon(Icons.menu_book), label: "القرآن"),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: "الأذكار"),
          NavigationDestination(icon: Icon(Icons.library_books), label: "المكتبة"),
          NavigationDestination(icon: Icon(Icons.settings), label: "إعدادات"),
        ],
      ),
    );
  }
}

class DailyProgress extends ChangeNotifier {
  int quranPages = 0; // target 10 (MVP)
  int tasbeeh = 0;    // target 200
  int dua = 0;        // target 10
  int sunnah = 0;     // target 3

  void incQuran() { quranPages++; notifyListeners(); }
  void decQuran() { if (quranPages > 0) quranPages--; notifyListeners(); }

  void incTasbeeh() { tasbeeh++; notifyListeners(); }
  void decTasbeeh() { if (tasbeeh > 0) tasbeeh--; notifyListeners(); }

  void incDua() { dua++; notifyListeners(); }
  void decDua() { if (dua > 0) dua--; notifyListeners(); }

  void incSunnah() { sunnah++; notifyListeners(); }
  void decSunnah() { if (sunnah > 0) sunnah--; notifyListeners(); }
}

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.progress});
  final DailyProgress progress;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final df = DateFormat("EEEE d MMMM", "ar_EG");

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final times = _cairoPrayerTimesSafe();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "جدول اليوم",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 6),
            Text(df.format(now), textAlign: TextAlign.right),
            const SizedBox(height: 16),

            _Card(
              title: "أوقات الصلاة (القاهرة)",
              child: times == null
                  ? const Text("تعذر حساب أوقات الصلاة. تأكد أن dependency adhan موجودة.")
                  : Column(
                      children: [
                        _timeRow("الفجر", times.fajr),
                        _timeRow("الشروق", times.sunrise),
                        _timeRow("الظهر", times.dhuhr),
                        _timeRow("العصر", times.asr),
                        _timeRow("المغرب", times.maghrib),
                        _timeRow("العشاء", times.isha),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            _Card(
              title: "تحدي اليوم (MVP)",
              child: Column(
                children: [
                  _progressRow(
                    label: "قراءة قرآن",
                    value: progress.quranPages,
                    target: 10,
                    onPlus: progress.incQuran,
                    onMinus: progress.decQuran,
                  ),
                  const SizedBox(height: 10),
                  _progressRow(
                    label: "تسبيح",
                    value: progress.tasbeeh,
                    target: 200,
                    onPlus: progress.incTasbeeh,
                    onMinus: progress.decTasbeeh,
                  ),
                  const SizedBox(height: 10),
                  _progressRow(
                    label: "دعاء",
                    value: progress.dua,
                    target: 10,
                    onPlus: progress.incDua,
                    onMinus: progress.decDua,
                  ),
                  const SizedBox(height: 10),
                  _progressRow(
                    label: "سنة عملية",
                    value: progress.sunnah,
                    target: 3,
                    onPlus: progress.incSunnah,
                    onMinus: progress.decSunnah,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  PrayerTimes? _cairoPrayerTimesSafe() {
    try {
      final coords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.egyptian.getParameters();
      return PrayerTimes.today(coords, params);
    } catch (_) {
      return null;
    }
  }

  Widget _timeRow(String name, DateTime time) {
    final t = DateFormat("HH:mm").format(time);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _progressRow({
    required String label,
    required int value,
    required int target,
    required VoidCallback onPlus,
    required VoidCallback onMinus,
  }) {
    final v = value.clamp(0, target);
    final p = target == 0 ? 0.0 : (v / target);
    return Column(
      children: [
        Row(
          children: [
            _pill("-", onMinus),
            const SizedBox(width: 8),
            _pill("+", onPlus),
            const Spacer(),
            Text("$v/$target", style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: p),
      ],
    );
  }

  Widget _pill(String text, VoidCallback onTap) {
    return SizedBox(
      width: 44,
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _FutureScaffold(
      title: "القرآن",
      future: AssetRepo.loadQuran(),
      builder: (context, data) {
        final surahs = data.surahs;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final s = surahs[i];
            return ListTile(
              title: Text(s.nameAr, textAlign: TextAlign.right),
              subtitle: Text("سورة رقم ${s.id}  ${s.ayahs.length} آية", textAlign: TextAlign.right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SurahView(surah: s)),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: surahs.length,
        );
      },
    );
  }
}

class SurahView extends StatelessWidget {
  const SurahView({super.key, required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(surah.nameAr)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: surah.ayahs.length,
        itemBuilder: (_, i) {
          final a = surah.ayahs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "${a.textAr}  ${a.no}",
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 20, height: 1.6),
            ),
          );
        },
      ),
    );
  }
}

class AdhkarPage extends StatelessWidget {
  const AdhkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _FutureScaffold(
      title: "الأذكار",
      future: AssetRepo.loadAdhkar(),
      builder: (context, data) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.categories.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final c = data.categories[i];
            return ListTile(
              title: Text(c.nameAr, textAlign: TextAlign.right),
              subtitle: Text("${c.items.length} عنصر", textAlign: TextAlign.right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CategoryView(title: c.nameAr, items: c.items.map((e) => e.textAr).toList())),
              ),
            );
          },
        );
      },
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <_LibCardData>[
      _LibCardData("أدعية", Icons.favorite, () => _open(context, "دعاء", AssetRepo.loadDuaTexts)),
      _LibCardData("أحاديث", Icons.format_quote, () => _open(context, "حديث", AssetRepo.loadHadithTexts)),
      _LibCardData("سنن عملية", Icons.check_circle, () => _open(context, "سنة", AssetRepo.loadSunnahTexts)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("المكتبة")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: Icon(c.icon),
              title: Text(c.title, textAlign: TextAlign.right),
              trailing: const Icon(Icons.chevron_left),
              onTap: c.onTap,
            ),
          ),
        )).toList(),
      ),
    );
  }

  void _open(BuildContext context, String title, Future<List<String>> Function() loader) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FutureScaffold(
        title: title,
        future: loader(),
        builder: (context, items) => CategoryView(title: title, items: items),
      ),
    ));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إعدادات")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "MVP فقط.\n"
          "الخطوة الجاية: حفظ التقدم (Persistence) + إشعارات + اختيار مدينة/طريقة حساب.",
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

class CategoryView extends StatelessWidget {
  const CategoryView({super.key, required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(items[i], textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, height: 1.6)),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: items.length,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _FutureScaffold<T> extends StatelessWidget {
  const _FutureScaffold({
    required this.title,
    required this.future,
    required this.builder,
  });

  final String title;
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<T>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "خطأ في تحميل الداتا:\n${snap.error}",
                textAlign: TextAlign.right,
              ),
            );
          }
          return builder(context, snap.data as T);
        },
      ),
    );
  }
}

class _LibCardData {
  _LibCardData(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class AssetRepo {
  static Future<AdhkarData> loadAdhkar() async {
    final m = await _loadMap("assets/data/adhkar_sample.json");
    final cats = (m["categories"] as List).map((e) => Category.fromMap(e)).toList();
    return AdhkarData(categories: cats);
  }

  static Future<QuranData> loadQuran() async {
    final m = await _loadMap("assets/data/quran_sample.json");
    final surahs = (m["surahs"] as List).map((e) => Surah.fromMap(e)).toList();
    return QuranData(surahs: surahs);
  }

  static Future<List<String>> loadDuaTexts() async {
    final m = await _loadMap("assets/data/dua_sample.json");
    final cats = (m["categories"] as List).map((e) => Category.fromMap(e)).toList();
    return cats.expand((c) => c.items.map((i) => i.textAr)).toList();
  }

  static Future<List<String>> loadHadithTexts() async {
    final m = await _loadMap("assets/data/hadith_sample.json");
    final items = (m["items"] as List).cast<Map<String, dynamic>>();
    return items.map((x) => "${x["text_ar"]}\n ${x["source_ar"]}").toList();
  }

  static Future<List<String>> loadSunnahTexts() async {
    final m = await _loadMap("assets/data/sunnah_sample.json");
    final items = (m["items"] as List).cast<Map<String, dynamic>>();
    return items.map((x) => "${x["title_ar"]}\n${x["desc_ar"]}").toList();
  }

  static Future<Map<String, dynamic>> _loadMap(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

class AdhkarData {
  AdhkarData({required this.categories});
  final List<Category> categories;
}

class QuranData {
  QuranData({required this.surahs});
  final List<Surah> surahs;
}

class Category {
  Category({required this.id, required this.nameAr, required this.items});
  final String id;
  final String nameAr;
  final List<TextItem> items;

  factory Category.fromMap(Map<String, dynamic> m) {
    return Category(
      id: m["id"].toString(),
      nameAr: (m["name_ar"] ?? "").toString(),
      items: (m["items"] as List).map((e) => TextItem.fromMap(e)).toList(),
    );
  }
}

class TextItem {
  TextItem({required this.id, required this.textAr, this.repeat});
  final String id;
  final String textAr;
  final int? repeat;

  factory TextItem.fromMap(Map<String, dynamic> m) {
    return TextItem(
      id: m["id"].toString(),
      textAr: (m["text_ar"] ?? "").toString(),
      repeat: m["repeat"] is int ? m["repeat"] as int : null,
    );
  }
}

class Surah {
  Surah({required this.id, required this.nameAr, required this.ayahs});
  final int id;
  final String nameAr;
  final List<Ayah> ayahs;

  factory Surah.fromMap(Map<String, dynamic> m) {
    return Surah(
      id: (m["id"] as num).toInt(),
      nameAr: (m["name_ar"] ?? "").toString(),
      ayahs: (m["ayahs"] as List).map((e) => Ayah.fromMap(e)).toList(),
    );
  }
}

class Ayah {
  Ayah({required this.no, required this.textAr});
  final int no;
  final String textAr;

  factory Ayah.fromMap(Map<String, dynamic> m) {
    return Ayah(
      no: (m["no"] as num).toInt(),
      textAr: (m["text_ar"] ?? "").toString(),
    );
  }
}
