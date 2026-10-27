import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:food_recsys_mobile/models/taste_profile.dart';
import 'package:food_recsys_mobile/providers/taste_provider.dart';
import 'package:food_recsys_mobile/screens/taste_profile_tab.dart';
import 'package:food_recsys_mobile/services/api_service.dart';
import 'package:food_recsys_mobile/services/sms_listener_service.dart';

class ProfileWidgetApi extends ApiService {
  bool fail = false;

  @override
  Future<TasteProfile> getProfile(String userId) async {
    if (fail) throw Exception('offline');
    return TasteProfile.fromJson({
      'user_id': userId,
      'total_food_transactions': 7,
      'avg_spend': 250.25,
    });
  }
}

Widget profileApp(ProfileWidgetApi api, TasteProvider provider) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiService>.value(value: api),
        ChangeNotifierProvider<TasteProvider>.value(value: provider),
      ],
      child: const MaterialApp(home: TasteProfileTab()),
    );

void main() {
  testWidgets('unavailable history never appears as zero orders',
      (tester) async {
    final api = ProfileWidgetApi()..fail = true;
    final provider = TasteProvider(api, SmsListenerService(api));
    await provider.fetchProfile();
    await tester.pumpWidget(profileApp(api, provider));
    expect(
        find.text('Your dining history is unavailable. Retry when connected.'),
        findsOneWidget);
    expect(find.text('0 orders'), findsNothing);
    expect(find.text('No dining transactions yet'), findsNothing);
    expect(find.text('Retry profile'), findsOneWidget);
  });

  testWidgets(
      'failed refresh explains stale state while retaining displayed history',
      (tester) async {
    final api = ProfileWidgetApi();
    final provider = TasteProvider(api, SmsListenerService(api));
    await provider.fetchProfile();
    api.fail = true;
    await provider.fetchProfile();
    await tester.pumpWidget(profileApp(api, provider));
    expect(find.text('7 orders'), findsOneWidget);
    expect(find.text('₹250.25'), findsOneWidget);
    expect(
        find.text(
            'Showing the last loaded profile. Your saved history has not been cleared.'),
        findsOneWidget);
  });
}
