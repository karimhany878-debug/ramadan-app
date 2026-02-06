import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/prayer/prayer_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/placeholder/placeholder_screen.dart';
import 'features/settings/settings_screen.dart';

class RamadanKareemApp extends StatelessWidget {
  const RamadanKareemApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B6E4F);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رمضان كريم',
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF6FAF8),
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
  int _index = 0;

  late final List<Widget> _pages = const [
    PrayerScreen(),                          // اليوم + الصلاة (القاهرة)
    ScheduleScreen(days: 30),                // الجدول (List مش DataTable)
    PlaceholderScreen(title: 'القرآن', icon: Icons.menu_book, hint: 'هنضيف النصوص/التلاوات لاحقا'),
    PlaceholderScreen(title: 'الأذكار', icon: Icons.auto_awesome, hint: 'هنضيف كل الأذكار لاحقا'),
    PlaceholderScreen(title: 'الأحاديث والسنن', icon: Icons.library_books, hint: 'هنضيف الأحاديث لاحقا'),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'اليوم'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'الجدول'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'القرآن'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'الأذكار'),
          NavigationDestination(icon: Icon(Icons.library_books), label: 'حديث/سنن'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'إعدادات'),
        ],
      ),
    );
  }
}
