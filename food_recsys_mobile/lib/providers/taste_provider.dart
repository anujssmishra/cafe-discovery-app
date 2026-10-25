import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/sms_listener_service.dart';
import '../models/taste_profile.dart';
import '../config/constants.dart';

class TasteProvider with ChangeNotifier {
  final ApiService _apiService;
  final SmsListenerService _smsListenerService;

  final String _activeUserId = AppConstants.defaultUserId;
  TasteProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  // DPDP Act 2023 Consent State
  bool _hasDpdpConsent = false;
  String _consentStatus = 'pending';
  DateTime? _consentGrantedAt;

  TasteProvider(this._apiService, this._smsListenerService);

  String get activeUserId => _activeUserId;
  TasteProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasDpdpConsent => _hasDpdpConsent;
  String get consentStatus => _consentStatus;
  DateTime? get consentGrantedAt => _consentGrantedAt;

  int get totalTransactions => _profile?.totalFoodTransactions ?? 0;
  bool get isCleanProfile => totalTransactions == 0;

  Future<void> init() async {
    _smsListenerService.setActiveUserId(_activeUserId);
    await checkConsent();
    await fetchProfile();
  }

  Future<void> checkConsent() async {
    final prefs = await SharedPreferences.getInstance();
    _hasDpdpConsent = prefs.getBool('dpdp_consent_granted') ?? false;
    final grantedStr = prefs.getString('dpdp_consent_granted_at');
    if (grantedStr != null) {
      _consentGrantedAt = DateTime.tryParse(grantedStr);
    }
    _consentStatus = _hasDpdpConsent ? 'granted' : 'pending';

    // Verify / sync with backend if online
    try {
      final consentData = await _apiService.getUserConsent(_activeUserId);
      final backendStatus = consentData['status'] as String?;
      if (backendStatus == 'granted') {
        _hasDpdpConsent = true;
        _consentStatus = 'granted';
        final dt = consentData['granted_at']?.toString();
        if (dt != null) _consentGrantedAt = DateTime.tryParse(dt);
        await prefs.setBool('dpdp_consent_granted', true);
        if (_consentGrantedAt != null) {
          await prefs.setString('dpdp_consent_granted_at', _consentGrantedAt!.toIso8601String());
        }
      } else if (backendStatus == 'revoked') {
        _hasDpdpConsent = false;
        _consentStatus = 'revoked';
        await prefs.setBool('dpdp_consent_granted', false);
      }
    } catch (_) {
      // Offline fallback: keep local SharedPreferences state
    }
    notifyListeners();
  }

  Future<bool> grantConsent() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dpdp_consent_granted', true);
    await prefs.setString('dpdp_consent_granted_at', now.toIso8601String());

    _hasDpdpConsent = true;
    _consentStatus = 'granted';
    _consentGrantedAt = now;
    notifyListeners();

    try {
      await _apiService.updateUserConsent(_activeUserId, granted: true);
    } catch (_) {}
    return true;
  }

  Future<bool> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dpdp_consent_granted', false);
    await prefs.remove('dpdp_consent_granted_at');

    _hasDpdpConsent = false;
    _consentStatus = 'revoked';
    _consentGrantedAt = null;

    // Immediately stop listening
    await _smsListenerService.stopListening();
    notifyListeners();

    try {
      await _apiService.updateUserConsent(_activeUserId, granted: false);
    } catch (_) {}
    return true;
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _apiService.getProfile(_activeUserId);
    } catch (e) {
      _errorMessage = e.toString();
      _profile = TasteProfile.empty(_activeUserId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> clearProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _apiService.clearProfile(_activeUserId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> exerciseRightToErasure() async {
    final cleared = await clearProfile();
    await revokeConsent();
    return cleared;
  }
}
