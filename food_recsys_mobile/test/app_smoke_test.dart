import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_recsys_mobile/main.dart';
import 'package:food_recsys_mobile/models/recommendation.dart';
import 'package:food_recsys_mobile/models/taste_profile.dart';
import 'package:food_recsys_mobile/providers/recs_provider.dart';
import 'package:food_recsys_mobile/providers/taste_provider.dart';
import 'package:food_recsys_mobile/services/api_service.dart';
import 'package:food_recsys_mobile/services/sms_listener_service.dart';

class SmokeApi extends ApiService {
  @override
  Future<TasteProfile> getProfile(String userId) async =>
      TasteProfile.empty(userId);
  @override
  Future<Map<String, dynamic>> getCatalogueMetadata() async => {
        'areas': ['Synthetic Area'],
        'cuisines': [],
        'meal_options': ['any'],
      };
  @override
  Future<RecommendationResponse> getRecommendations(String userId,
          {String? meal, String? area, int n = 10}) async =>
      RecommendationResponse.fromJson({
        'user_id': userId,
        'count': 0,
        'recommendations': [],
      });
}

void main() {
  testWidgets(
      'the integrated app opens and all four tabs build without device access',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final api = SmokeApi();
    final service = SmsListenerService(api);
    final taste = TasteProvider(api, service);
    final recs = RecsProvider(api);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiService>.value(value: api),
        ChangeNotifierProvider<SmsListenerService>.value(value: service),
        ChangeNotifierProvider<TasteProvider>.value(value: taste),
        ChangeNotifierProvider<RecsProvider>.value(value: recs),
      ],
      child: const FoodRecSysApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    for (final label in ['Taste', 'Auto-Ingest', 'Settings', 'Recs']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: '$label should open without a platform or provider error');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    taste.dispose();
    recs.dispose();
    service.dispose();
    api.dispose();
  });
}
