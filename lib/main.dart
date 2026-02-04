import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AmoonWorshipApp());
}

class AmoonWorshipApp extends StatelessWidget {
  const AmoonWorshipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amoon Worship',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
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

  final pages = const [
    PlannerPage(),
    QuranPage(),
    AdhkarPage(),
    SunnahHadithDuaPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'الجدول'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'القرآن'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'الأذكار'),
          NavigationDestination(icon: Icon(Icons.bookmarks), label: 'سنن/حديث/دعاء'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'إعدادات'),
        ],
      ),
    );
  }
}

/* -------------------- Data Loader -------------------- */

class AssetsRepo {
  static Future<Map<String, dynamic>> loadJson(String path) async {
    final s = await rootBundle.loadString(path);
    return jsonDecode(s) as Map<String, dynamic>;
  }
}

/* -------------------- Planner (Daily Table) -------------------- */

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final List<_Task> tasks = [
    _Task(id: 'q_pages', title: 'قراءة قرآن', target: 10, unit: 'صفحات'),
    _Task(id: 'adhkar', title: 'أذكار', target: 200, unit: 'تسبيحة'),
    _Task(id: 'dua', title: 'دعاء', target: 10, unit: 'أدعية'),
    _Task(id: 'sunnah', title: 'سنة عملية', target: 3, unit: 'سنن'),
    _Task(id: 'study', title: 'مذاكرة', target: 2, unit: 'ساعات'),
  ];

  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in tasks) {
      t.value = prefs.getInt('task_${t.id}') ?? 0;
    }
    loaded = true;
    if (mounted) setState(() {});
  }

  Future<void> _saveTask(_Task t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('task_${t.id}', t.value);
  }

  Future<void> _resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in tasks) {
      t.value = 0;
      await prefs.setInt('task_${t.id}', 0);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const _PageScaffold(title: 'جدول اليوم', child: Center(child: CircularProgressIndicator()));
    }

    return _PageScaffold(
      title: 'جدول اليوم',
      actions: [
        IconButton(
          onPressed: _resetAll,
          tooltip: 'تصفير اليوم',
          icon: const Icon(Icons.restart_alt),
        )
      ],
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _HintCard(
            title: 'فكرة سريعة',
            body:
                'ده جدول بسيط للتتبع (offline). بعدين نضيف منبهات وإعداد أوقات وربط بالصلاة.',
            icon: Icons.lightbulb,
          ),
          const SizedBox(height: 12),
          ...tasks.map((t) => _TaskCard(
                task: t,
                onMinus: () async {
                  setState(() => t.value = (t.value - 1).clamp(0, 1000000));
                  await _saveTask(t);
                },
                onPlus: () async {
                  setState(() => t.value = (t.value + 1).clamp(0, 1000000));
                  await _saveTask(t);
                },
              )),
        ],
      ),
    );
  }
}

class _Task {
  _Task({required this.id, required this.title, required this.target, required this.unit});
  final String id;
  final String title;
  final int target;
  final String unit;
  int value = 0;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onMinus, required this.onPlus});
  final _Task task;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final progress = task.target == 0 ? 0.0 : (task.value / task.target).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text('${task.value}/${task.target} ${task.unit}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(onPressed: onMinus, icon: const Icon(Icons.remove), label: const Text('ناقص')),
                const Spacer(),
                FilledButton.icon(onPressed: onPlus, icon: const Icon(Icons.add), label: const Text('زود')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/* -------------------- Quran -------------------- */

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  List<_Surah> surahs = [];
  String q = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await AssetsRepo.loadJson('assets/data/quran_sample.json');
    final list = (m['surahs'] as List).cast<Map<String, dynamic>>();
    surahs = list.map(_Surah.fromJson).toList();
    loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _PageScaffold(title: 'القرآن', child: Center(child: CircularProgressIndicator()));
    }

    final filtered = surahs.where((s) => s.nameAr.contains(q) || s.id.toString() == q).toList();

    return _PageScaffold(
      title: 'القرآن',
      child: Column(
        children: [
          _SearchBox(
            hint: 'ابحث باسم السورة أو رقمها… (تجربة)',
            onChanged: (v) => setState(() => q = v.trim()),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final s = filtered[i];
                return Card(
                  child: ListTile(
                    title: Text('${s.id} - ${s.nameAr}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('عدد الآيات: ${s.ayahs.length}'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SurahPage(surah: s))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SurahPage extends StatelessWidget {
  const SurahPage({super.key, required this.surah});
  final _Surah surah;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: surah.nameAr,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...surah.ayahs.map((a) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${a.no}. ${a.textAr}', style: const TextStyle(fontSize: 18, height: 1.6)),
                ),
              )),
        ],
      ),
    );
  }
}

class _Surah {
  _Surah({required this.id, required this.nameAr, required this.ayahs});
  final int id;
  final String nameAr;
  final List<_Ayah> ayahs;

  static _Surah fromJson(Map<String, dynamic> j) {
    return _Surah(
      id: (j['id'] as num).toInt(),
      nameAr: (j['name_ar'] as String),
      ayahs: (j['ayahs'] as List).map((x) => _Ayah.fromJson((x as Map).cast<String, dynamic>())).toList(),
    );
  }
}

class _Ayah {
  _Ayah({required this.no, required this.textAr});
  final int no;
  final String textAr;

  static _Ayah fromJson(Map<String, dynamic> j) => _Ayah(
        no: (j['no'] as num).toInt(),
        textAr: (j['text_ar'] as String),
      );
}

/* -------------------- Adhkar -------------------- */

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  List<_ZikrCategory> cats = [];
  String q = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await AssetsRepo.loadJson('assets/data/adhkar_sample.json');
    final list = (m['categories'] as List).cast<Map<String, dynamic>>();
    cats = list.map(_ZikrCategory.fromJson).toList();
    loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _PageScaffold(title: 'الأذكار', child: Center(child: CircularProgressIndicator()));

    final filtered = cats.where((c) => c.nameAr.contains(q)).toList();

    return _PageScaffold(
      title: 'الأذكار',
      child: Column(
        children: [
          _SearchBox(hint: 'ابحث في أقسام الأذكار…', onChanged: (v) => setState(() => q = v.trim())),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: filtered
                  .map((c) => Card(
                        child: ListTile(
                          title: Text(c.nameAr, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('عدد الأذكار: ${c.items.length}'),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => ZikrCategoryPage(category: c))),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ZikrCategoryPage extends StatefulWidget {
  const ZikrCategoryPage({super.key, required this.category});
  final _ZikrCategory category;

  @override
  State<ZikrCategoryPage> createState() => _ZikrCategoryPageState();
}

class _ZikrCategoryPageState extends State<ZikrCategoryPage> {
  late List<int> done; // per item counter done

  @override
  void initState() {
    super.initState();
    done = List<int>.filled(widget.category.items.length, 0);
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: widget.category.nameAr,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.category.items.length,
        itemBuilder: (context, i) {
          final item = widget.category.items[i];
          final left = (item.count - done[i]).clamp(0, item.count);
          final finished = left == 0;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.textAr, style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('المتبقي: $left / ${item.count}', style: TextStyle(fontWeight: FontWeight.w700, color: finished ? Colors.green : null)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: finished
                            ? null
                            : () => setState(() => done[i] = (done[i] + 1).clamp(0, item.count)),
                        icon: const Icon(Icons.check),
                        label: const Text('تم'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() => done[i] = 0),
                        tooltip: 'إعادة',
                        icon: const Icon(Icons.refresh),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ZikrCategory {
  _ZikrCategory({required this.id, required this.nameAr, required this.items});
  final String id;
  final String nameAr;
  final List<_ZikrItem> items;

  static _ZikrCategory fromJson(Map<String, dynamic> j) => _ZikrCategory(
        id: j['id'] as String,
        nameAr: j['name_ar'] as String,
        items: (j['items'] as List).map((x) => _ZikrItem.fromJson((x as Map).cast<String, dynamic>())).toList(),
      );
}

class _ZikrItem {
  _ZikrItem({required this.textAr, required this.count});
  final String textAr;
  final int count;

  static _ZikrItem fromJson(Map<String, dynamic> j) => _ZikrItem(
        textAr: j['text_ar'] as String,
        count: (j['count'] as num).toInt(),
      );
}

/* -------------------- Sunnah + Hadith + Dua -------------------- */

class SunnahHadithDuaPage extends StatelessWidget {
  const SunnahHadithDuaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PageScaffold(
      title: 'سنن / حديث / دعاء',
      child: _TripleHub(),
    );
  }
}

class _TripleHub extends StatefulWidget {
  const _TripleHub();

  @override
  State<_TripleHub> createState() => _TripleHubState();
}

class _TripleHubState extends State<_TripleHub> with SingleTickerProviderStateMixin {
  late final TabController controller;
  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: controller,
          tabs: const [
            Tab(text: 'سنن'),
            Tab(text: 'أحاديث'),
            Tab(text: 'أدعية'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: const [
              SunnahPage(),
              HadithPage(),
              DuaPage(),
            ],
          ),
        ),
      ],
    );
  }
}

class SunnahPage extends StatefulWidget {
  const SunnahPage({super.key});
  @override
  State<SunnahPage> createState() => _SunnahPageState();
}

class _SunnahPageState extends State<SunnahPage> {
  List<_Sunnah> items = [];
  String q = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await AssetsRepo.loadJson('assets/data/sunnah_sample.json');
    final list = (m['items'] as List).cast<Map<String, dynamic>>();
    items = list.map(_Sunnah.fromJson).toList();
    loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final filtered = items.where((x) => x.titleAr.contains(q) || x.descAr.contains(q)).toList();

    return Column(
      children: [
        _SearchBox(hint: 'بحث في السنن…', onChanged: (v) => setState(() => q = v.trim())),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: filtered
                .map((s) => Card(
                      child: ListTile(
                        title: Text(s.titleAr, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(s.descAr),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _Sunnah {
  _Sunnah({required this.id, required this.titleAr, required this.descAr});
  final String id;
  final String titleAr;
  final String descAr;

  static _Sunnah fromJson(Map<String, dynamic> j) => _Sunnah(
        id: j['id'] as String,
        titleAr: j['title_ar'] as String,
        descAr: j['desc_ar'] as String,
      );
}

class HadithPage extends StatefulWidget {
  const HadithPage({super.key});
  @override
  State<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends State<HadithPage> {
  List<_Hadith> items = [];
  String q = '';
  bool loading = true;

  final Set<int> fav = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    fav.addAll((prefs.getStringList('fav_hadith') ?? []).map(int.parse));

    final m = await AssetsRepo.loadJson('assets/data/hadith_sample.json');
    final list = (m['items'] as List).cast<Map<String, dynamic>>();
    items = list.map(_Hadith.fromJson).toList();
    loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _toggleFav(int id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (fav.contains(id)) {
        fav.remove(id);
      } else {
        fav.add(id);
      }
    });
    await prefs.setStringList('fav_hadith', fav.map((e) => e.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final filtered = items.where((x) => x.textAr.contains(q) || x.sourceAr.contains(q)).toList();

    return Column(
      children: [
        _SearchBox(hint: 'بحث في الأحاديث…', onChanged: (v) => setState(() => q = v.trim())),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: filtered
                .map((h) => Card(
                      child: ListTile(
                        title: Text(h.textAr, style: const TextStyle(height: 1.5, fontWeight: FontWeight.w700)),
                        subtitle: Text(h.sourceAr),
                        trailing: IconButton(
                          onPressed: () => _toggleFav(h.id),
                          icon: Icon(fav.contains(h.id) ? Icons.favorite : Icons.favorite_border),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _Hadith {
  _Hadith({required this.id, required this.textAr, required this.sourceAr});
  final int id;
  final String textAr;
  final String sourceAr;

  static _Hadith fromJson(Map<String, dynamic> j) => _Hadith(
        id: (j['id'] as num).toInt(),
        textAr: j['text_ar'] as String,
        sourceAr: j['source_ar'] as String,
      );
}

class DuaPage extends StatefulWidget {
  const DuaPage({super.key});
  @override
  State<DuaPage> createState() => _DuaPageState();
}

class _DuaPageState extends State<DuaPage> {
  List<_DuaCategory> cats = [];
  String q = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await AssetsRepo.loadJson('assets/data/dua_sample.json');
    final list = (m['categories'] as List).cast<Map<String, dynamic>>();
    cats = list.map(_DuaCategory.fromJson).toList();
    loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final filtered = cats
        .where((c) =>
            c.nameAr.contains(q) ||
            c.items.any((i) => i.textAr.contains(q)))
        .toList();

    return Column(
      children: [
        _SearchBox(hint: 'بحث في الأدعية…', onChanged: (v) => setState(() => q = v.trim())),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: filtered
                .map((c) => Card(
                      child: ListTile(
                        title: Text(c.nameAr, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('عدد الأدعية: ${c.items.length}'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => DuaCategoryPage(category: c))),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class DuaCategoryPage extends StatelessWidget {
  const DuaCategoryPage({super.key, required this.category});
  final _DuaCategory category;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: category.nameAr,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: category.items
            .map((d) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(d.textAr, style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w700)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _DuaCategory {
  _DuaCategory({required this.id, required this.nameAr, required this.items});
  final String id;
  final String nameAr;
  final List<_DuaItem> items;

  static _DuaCategory fromJson(Map<String, dynamic> j) => _DuaCategory(
        id: j['id'] as String,
        nameAr: j['name_ar'] as String,
        items: (j['items'] as List).map((x) => _DuaItem.fromJson((x as Map).cast<String, dynamic>())).toList(),
      );
}

class _DuaItem {
  _DuaItem({required this.id, required this.textAr});
  final String id;
  final String textAr;

  static _DuaItem fromJson(Map<String, dynamic> j) => _DuaItem(
        id: j['id'] as String,
        textAr: j['text_ar'] as String,
      );
}

/* -------------------- Settings -------------------- */

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'إعدادات',
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _HintCard(
            title: 'المنبهات والصلاة',
            body:
                'المرحلة الجاية: منبهات للأذكار/الورد + حساب أوقات الصلاة (offline) حسب المدينة + تذكير قبل الأذان.',
            icon: Icons.notifications_active,
          ),
          SizedBox(height: 12),
          _HintCard(
            title: 'البيانات',
            body:
                'دلوقتي البيانات Sample للتجربة. بعدين ندخل مصادر موثوقة (ملفات JSON كاملة) ونضيف فهرسة وبحث أسرع.',
            icon: Icons.storage,
          ),
        ],
      ),
    );
  }
}

/* -------------------- Shared UI -------------------- */

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.title, required this.child, this.actions});
  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: actions,
      ),
      body: child,
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.title, required this.body, required this.icon});
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
