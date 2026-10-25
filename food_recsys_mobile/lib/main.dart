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
        Provider<ApiService>.value(value: apiService),
        Provider<SmsListenerService>.value(value: smsListenerService),
        ChangeNotifierProvider<TasteProvider>.value(value: tasteProvider),
        ChangeNotifierProvider<RecsProvider>.value(value: recsProvider),
      ],
      child: const FoodRecSysApp(),
    ),
  );
}

class FoodRecSysApp extends StatelessWidget {
  const FoodRecSysApp({super.key});

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
