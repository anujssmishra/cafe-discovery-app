import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_recsys_mobile/providers/taste_provider.dart';
import 'package:food_recsys_mobile/services/api_service.dart';
import 'package:food_recsys_mobile/services/sms_listener_service.dart';

class FakeApiService extends ApiService {
  bool consentGrantedOnServer = false;

  @override
  Future<Map<String, dynamic>> getUserConsent(String userId) async {
    return {
      'user_id': userId,
      'status': consentGrantedOnServer ? 'granted' : 'pending',
      'sms_processing_consent': consentGrantedOnServer,
      'dpdp_version': 'DPDP_ACT_2023_V1',
      'granted_at': consentGrantedOnServer ? DateTime.now().toIso8601String() : null,
    };
  }

  @override
  Future<Map<String, dynamic>> updateUserConsent(
    String userId, {
    required bool granted,
    String dpdpVersion = 'DPDP_ACT_2023_V1',
  }) async {
    consentGrantedOnServer = granted;
    return {
      'user_id': userId,
      'status': granted ? 'granted' : 'revoked',
      'sms_processing_consent': granted,
      'dpdp_version': dpdpVersion,
    };
  }
}

class FakeSmsListenerService extends SmsListenerService {
  bool listeningStopped = false;

  FakeSmsListenerService(super.apiService);

  @override
  Future<void> stopListening() async {
    listeningStopped = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasteProvider DPDP Act 2023 Consent Tests', () {
    late FakeApiService fakeApi;
    late FakeSmsListenerService fakeSmsService;
    late TasteProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeApi = FakeApiService();
      fakeSmsService = FakeSmsListenerService(fakeApi);
      provider = TasteProvider(fakeApi, fakeSmsService);
    });

    test('Initial consent state is pending without prior consent', () async {
      await provider.checkConsent();
      expect(provider.hasDpdpConsent, isFalse);
      expect(provider.consentStatus, equals('pending'));
      expect(provider.consentGrantedAt, isNull);
    });

    test('Granting consent persists to SharedPreferences and updates state', () async {
      final success = await provider.grantConsent();
      expect(success, isTrue);
      expect(provider.hasDpdpConsent, isTrue);
      expect(provider.consentStatus, equals('granted'));
      expect(provider.consentGrantedAt, isNotNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dpdp_consent_granted'), isTrue);
      expect(prefs.getString('dpdp_consent_granted_at'), isNotNull);
    });

    test('Revoking consent halts listener and clears consent state under Section 6(4)', () async {
      await provider.grantConsent();
      expect(provider.hasDpdpConsent, isTrue);

      final revoked = await provider.revokeConsent();
      expect(revoked, isTrue);
      expect(provider.hasDpdpConsent, isFalse);
      expect(provider.consentStatus, equals('revoked'));
      expect(provider.consentGrantedAt, isNull);
      expect(fakeSmsService.listeningStopped, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dpdp_consent_granted'), isFalse);
      expect(prefs.getString('dpdp_consent_granted_at'), isNull);
    });
  });
}
