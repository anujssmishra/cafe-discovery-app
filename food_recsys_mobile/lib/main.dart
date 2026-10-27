import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/api_service.dart';
import 'services/sms_listener_service.dart';
import 'providers/taste_provider.dart';
import 'providers/recs_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  await apiService.init();

  final smsListenerService = SmsListenerService(apiService);
  await smsListenerService.init();

  final tasteProvider = TasteProvider(apiService, smsListenerService);
  await tasteProvider.init();

  final recsProvider = RecsProvider(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<SmsListenerService>.value(
            value: smsListenerService),
        ChangeNotifierProvider<TasteProvider>.value(value: tasteProvider),
        ChangeNotifierProvider<RecsProvider>.value(value: recsProvider),
      ],
      child: const FoodRecSysApp(),
    ),
  );
}

class FoodRecSysApp extends StatefulWidget {
  const FoodRecSysApp({super.key});

  @override
  State<FoodRecSysApp> createState() => _FoodRecSysAppState();
}

class _FoodRecSysAppState extends State<FoodRecSysApp>
    with WidgetsBindingObserver {
  bool _resumingImports = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeImports());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _resumeImports();
  }

  Future<void> _resumeImports() async {
    if (_resumingImports || !mounted) return;
    _resumingImports = true;
    final taste = context.read<TasteProvider>();
    final recs = context.read<RecsProvider>();
    try {
      await context.read<SmsListenerService>().resumePendingImports(
        onNewIngestion: () async {
          await taste.fetchProfile();
          await recs.fetchRecommendations(taste.activeUserId);
        },
      );
    } catch (_) {
      // Captures remain on disk and can be retried from the import screen.
    } finally {
      _resumingImports = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food RecSys',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
