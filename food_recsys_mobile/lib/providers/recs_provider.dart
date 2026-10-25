import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recommendation.dart';

class RecsProvider with ChangeNotifier {
  final ApiService _apiService;

  RecommendationResponse? _response;
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedMeal = 'any';
  String _selectedArea = 'All Areas';

  RecsProvider(this._apiService);

  RecommendationResponse? get response => _response;
  List<RecommendationItem> get recommendations => _response?.recommendations ?? [];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedMeal => _selectedMeal;
  String get selectedArea => _selectedArea;

  Future<void> fetchRecommendations(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _response = await _apiService.getRecommendations(
        userId,
        meal: _selectedMeal,
        area: _selectedArea,
        n: 10,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _response = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMeal(String meal, String userId) {
    if (_selectedMeal != meal) {
      _selectedMeal = meal;
      fetchRecommendations(userId);
    }
  }

  void setArea(String area, String userId) {
    if (_selectedArea != area) {
      _selectedArea = area;
      fetchRecommendations(userId);
    }
  }
}
