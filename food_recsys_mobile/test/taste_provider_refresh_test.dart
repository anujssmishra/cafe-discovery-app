import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_recsys_mobile/models/taste_profile.dart';
import 'package:food_recsys_mobile/providers/taste_provider.dart';
import 'package:food_recsys_mobile/services/api_service.dart';
import 'package:food_recsys_mobile/services/sms_listener_service.dart';

class ControlledProfileApi extends ApiService {
  final List<Completer<TasteProfile>> requests = [];

  @override
  Future<TasteProfile> getProfile(String userId) {
    final request = Completer<TasteProfile>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<TasteProfile> clearProfile(String userId) async =>
      TasteProfile.empty(userId);
}

class QuietSmsService extends SmsListenerService {
  QuietSmsService(super.apiService);
}

TasteProfile profileWithOrders(int count) => TasteProfile.fromJson({
      'user_id': 'user_my_real_data',
      'total_food_transactions': count,
      'avg_spend': 250.0,
      'version': 2,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changing servers invalidates snapshots and old in-flight responses',
      () async {
    SharedPreferences.setMockInitialValues({});
    final api = ControlledProfileApi();
    final provider = TasteProvider(api, QuietSmsService(api));
    final first = provider.fetchProfile();
    api.requests[0].complete(profileWithOrders(7));
    await first;
    final oldServerRequest = provider.fetchProfile();
    await api.setBaseUrl('http://another-server.invalid:8000');
    expect(provider.profile, isNull);
    api.requests[1].complete(profileWithOrders(50));
    await oldServerRequest;
    expect(provider.profile, isNull);
    expect(provider.isCleanProfile, false);
    provider.dispose();
  });

  test('a failed first refresh is unavailable, not an empty profile', () async {
    final api = ControlledProfileApi();
    final provider = TasteProvider(api, QuietSmsService(api));
    final fetch = provider.fetchProfile();
    api.requests.single.completeError(Exception('offline'));
    await fetch;
    expect(provider.profile, isNull);
    expect(provider.isCleanProfile, isFalse);
    expect(provider.errorMessage, contains('offline'));
    expect(provider.isLoading, isFalse);
  });

  test('a failed refresh preserves the last successful profile', () async {
    final api = ControlledProfileApi();
    final provider = TasteProvider(api, QuietSmsService(api));
    final original = profileWithOrders(7);
    final first = provider.fetchProfile();
    api.requests[0].complete(original);
    await first;
    final retry = provider.fetchProfile();
    api.requests[1].completeError(Exception('offline'));
    await retry;
    expect(provider.profile, same(original));
    expect(provider.totalTransactions, 7);
    expect(provider.errorMessage, isNotNull);
  });

  test('only the latest profile request can update data and loading state',
      () async {
    final api = ControlledProfileApi();
    final provider = TasteProvider(api, QuietSmsService(api));
    final older = provider.fetchProfile();
    final newer = provider.fetchProfile();
    api.requests[0].complete(profileWithOrders(2));
    await older;
    expect(provider.isLoading, isTrue);
    expect(provider.profile, isNull);
    api.requests[1].complete(profileWithOrders(9));
    await newer;
    expect(provider.totalTransactions, 9);
    expect(provider.isLoading, isFalse);
  });

  test('a profile response started before erasure cannot restore erased data',
      () async {
    final api = ControlledProfileApi();
    final provider = TasteProvider(api, QuietSmsService(api));
    final older = provider.fetchProfile();
    expect(await provider.clearProfile(), isTrue);
    api.requests.single.complete(profileWithOrders(40));
    await older;
    expect(provider.totalTransactions, 0);
    expect(provider.isCleanProfile, isTrue);
  });
}
