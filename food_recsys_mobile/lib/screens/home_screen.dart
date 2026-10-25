import 'package:flutter/material.dart';
import 'recommendations_tab.dart';
import 'taste_profile_tab.dart';
import 'sms_ingest_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    RecommendationsTab(),
    TasteProfileTab(),
    SmsIngestTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Taste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt),
            label: 'Auto-Ingest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
