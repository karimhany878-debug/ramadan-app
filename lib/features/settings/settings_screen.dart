import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('التنبيهات'),
              subtitle: Text('هنضيف تنبيهات الصلاة لاحقا (بدون نت).'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const ListTile(
              leading: Icon(Icons.storage),
              title: Text('البيانات'),
              subtitle: Text('الأذكار/الأحاديث/القصص/القرآن: هنضيفهم في ملفات منظمة لاحقا.'),
            ),
          ),
        ],
      ),
    );
  }
}
