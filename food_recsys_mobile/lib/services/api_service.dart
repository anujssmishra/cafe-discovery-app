import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/taste_profile.dart';
import '../models/recommendation.dart';

class ApiService {
  String _baseUrl = AppConstants.defaultWifiApiUrl;

  String get baseUrl => _baseUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
      if (await checkHealth()) return;
    }

    // Auto-detect working endpoint (Wi-Fi, USB reverse localhost, or emulator)
    await autoDetectWorkingEndpoint();
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrl);
  }

  Future<bool> probeUrl(String url) async {
    try {
      final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      final res = await http.get(Uri.parse('$cleanUrl/health')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
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
    try {
      final res = await http.get(Uri.parse('$_baseUrl/health')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<TasteProfile> getProfile(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));

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

    final uri = Uri.parse('$_baseUrl/api/v1/recommend/$userId').replace(queryParameters: queryParams);
    final res = await http.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return RecommendationResponse.fromJson(json);
    } else {
      throw Exception('Failed to fetch recommendations: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> ingestSms(String userId, String smsText) async {
    final uri = Uri.parse('$_baseUrl/api/v1/ingest/sms');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'sms_text': smsText,
      }),
    ).timeout(const Duration(seconds: 8));

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
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'timestamped_messages': timestampedMessages,
      }),
    ).timeout(const Duration(seconds: 30));

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
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'orders': orders,
      }),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to ingest food orders: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getTransactions(String userId, {int limit = 200}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId/transactions?limit=$limit');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch transactions: HTTP ${res.statusCode}');
    }
  }

  Future<TasteProfile> clearProfile(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId');
    final res = await http.delete(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return TasteProfile.fromJson(json);
    } else {
      throw Exception('Failed to clear profile: HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUserConsent(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/profile/$userId/consent');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));

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
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': granted ? 'granted' : 'revoked',
        'sms_processing_consent': granted,
        'dpdp_version': dpdpVersion,
      }),
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update consent: HTTP ${res.statusCode}');
    }
  }
}
