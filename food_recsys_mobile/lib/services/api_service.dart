import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/taste_profile.dart';
import '../models/recommendation.dart';
import '../models/restaurant.dart';

class ApiService extends ChangeNotifier {
  final http.Client _client;
  String _baseUrl = AppConstants.defaultWifiApiUrl;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  String get baseUrl => _baseUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
      // A disconnected configured server must not silently become another data source.
      return;
    }

    // Auto-detect working endpoint (Wi-Fi, USB reverse localhost, or emulator)
    await autoDetectWorkingEndpoint();
  }

  Future<void> setBaseUrl(String newUrl) async {
    final candidate = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('Enter an HTTP or HTTPS server address.');
    }
    final changed = _baseUrl != candidate;
    final prefs = await SharedPreferences.getInstance();
    if (changed) {
      // Background isolates must stop capture before seeing another destination.
      await prefs.setBool('dpdp_consent_granted', false);
      await prefs.remove('dpdp_consent_granted_at');
      await prefs.setBool('sms_tracking_enabled', false);
    }
    await prefs.setString('api_base_url', candidate);
    _baseUrl = candidate;
    if (changed) notifyListeners();
  }

  Future<bool> probeUrl(String url) async {
    try {
      final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null ||
          !['https', 'http'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          uri.userInfo.isNotEmpty) return false;
      final res = await _client
          .get(Uri.parse('$cleanUrl/health'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body);
      return data is Map &&
          data['status'] == 'ok' &&
          data['database'] == 'connected';
    } catch (_) {
      return false;
    }
  }

  Future<String?> autoDetectWorkingEndpoint() async {
    final candidates = [
      _baseUrl,
      AppConstants.defaultWifiApiUrl, // http://192.168.83.100:8000
      AppConstants.defaultLocalhostApiUrl, // http://localhost:8000
      AppConstants.defaultEmulatorApiUrl, // http://10.0.2.2:8000
      'http://127.0.0.1:8000',
    ];

    for (final candidate in candidates) {
      if (await probeUrl(candidate)) {
        await setBaseUrl(candidate);
        return candidate;
      }
    }
    return null;
  }

  Future<bool> checkHealth() async {
    return probeUrl(_baseUrl);
  }

  Future<TasteProfile> getProfile(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId');
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return TasteProfile.fromJson(json);
    } else {
      throw Exception('Failed to fetch profile: HTTP ${res.statusCode}');
    }
  }

  Future<RecommendationResponse> getRecommendations(
    String userId, {
    String? meal,
    String? area,
    int n = 10,
  }) async {
    final queryParams = <String, String>{
      'n': n.toString(),
    };
    if (meal != null && meal != 'any' && meal.isNotEmpty) {
      queryParams['meal'] = meal;
    }
    if (area != null && area != 'All Areas' && area.isNotEmpty) {
      queryParams['area'] = area;
    }

    final uri = Uri.parse('$_baseUrl/api/v1/recommend/$userId')
        .replace(queryParameters: queryParams);
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return RecommendationResponse.fromJson(json);
    } else {
      throw Exception(
          'Failed to fetch recommendations: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> ingestSms(String userId, String smsText) async {
    final uri = Uri.parse('$_baseUrl/api/v1/ingest/sms');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'sms_text': smsText,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to ingest SMS: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> ingestTimestampedSmsBatch(
    String userId,
    List<Map<String, dynamic>> timestampedMessages,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/v1/ingest/sms');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'timestamped_messages': timestampedMessages,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to ingest batch SMS: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> ingestFoodOrders(
    String userId,
    List<Map<String, dynamic>> orders,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/v1/ingest/food-orders');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'orders': orders,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to ingest food orders: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> previewFoodOrders(
    String userId,
    List<Map<String, dynamic>> orders,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/v1/ingest/food-orders/preview'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'orders': orders}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Could not review orders: HTTP ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTransactions(String userId,
      {int limit = 100, String? cursor}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId/transactions')
        .replace(queryParameters: {
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch transactions: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> ingestPayments(
    String userId,
    List<Map<String, dynamic>> payments, {
    String? endpoint,
  }) async {
    final res = await _client
        .post(
          Uri.parse('${endpoint ?? _baseUrl}/api/v1/ingest/payments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'schema_version': 1, 'user_id': userId, 'payments': payments}),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Failed to import payments: HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCatalogueMetadata() async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/api/v1/restaurants/metadata'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load catalogue filters: HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Restaurant> getRestaurant(String id) async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/api/v1/restaurants/$id'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('Failed to load restaurant: HTTP ${res.statusCode}');
    }
    return Restaurant.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<TasteProfile> clearProfile(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId');
    final res = await _client.delete(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return TasteProfile.fromJson(json);
    } else {
      throw Exception('Failed to clear profile: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUserConsent(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId/consent');
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get user consent: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateUserConsent(
    String userId, {
    required bool granted,
    String dpdpVersion = 'DPDP_ACT_2023_V1',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId/consent');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'status': granted ? 'granted' : 'revoked',
            'sms_processing_consent': granted,
            'dpdp_version': dpdpVersion,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update consent: HTTP ${res.statusCode}');
    }
  }
}
