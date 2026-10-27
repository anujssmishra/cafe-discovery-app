import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../models/recommendation.dart';

class RecsProvider with ChangeNotifier {
  final ApiService _apiService;

  RecommendationResponse? _response;
  bool _isLoading = false;
  String? _errorMessage;
  int _request = 0;
  int _filtersRequest = 0;
  String? _filtersEndpoint;
  String? _filtersWarning;
  List<String> _areas = List.of(AppConstants.areaOptions);
  List<String> _meals = List.of(AppConstants.mealOptions);
  List<String> _cuisines = [];

  String _selectedMeal = 'any';
  String _selectedArea = 'All Areas';

  RecsProvider(this._apiService) {
    _apiService.addListener(_dataSourceChanged);
  }

  void _dataSourceChanged() {
    ++_request;
    ++_filtersRequest;
    _response = null;
    _isLoading = false;
    _filtersEndpoint = null;
    _filtersWarning = null;
    _areas = List.of(AppConstants.areaOptions);
    _meals = List.of(AppConstants.mealOptions);
    _cuisines = [];
    _selectedArea = 'All Areas';
    _selectedMeal = 'any';
    _errorMessage = 'Load recommendations from the selected server.';
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.removeListener(_dataSourceChanged);
    super.dispose();
  }

  RecommendationResponse? get response => _response;
  List<RecommendationItem> get recommendations =>
      _response?.recommendations ?? [];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filtersWarning => _filtersWarning;
  List<String> get areaOptions => List.unmodifiable(_areas);
  List<String> get mealOptions => List.unmodifiable(_meals);
  List<String> get cuisineOptions => List.unmodifiable(_cuisines);

  String get selectedMeal => _selectedMeal;
  String get selectedArea => _selectedArea;

  Future<void> loadFilters({bool force = false}) async {
    final endpoint = _apiService.baseUrl;
    if (!force && _filtersEndpoint == endpoint) return;
    final request = ++_filtersRequest;
    try {
      final metadata = await _apiService.getCatalogueMetadata();
      if (request != _filtersRequest || endpoint != _apiService.baseUrl) return;
      final areas = (metadata['areas'] as List<dynamic>? ?? [])
          .whereType<String>()
          .where((area) => area.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final meals = (metadata['meal_options'] as List<dynamic>? ?? [])
          .whereType<String>()
          .where((meal) => meal.isNotEmpty)
          .toSet()
          .toList();
      _areas = ['All Areas', ...areas.where((area) => area != 'All Areas')];
      _meals = ['any', ...meals.where((meal) => meal != 'any')];
      _cuisines = (metadata['cuisines'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList();
      _filtersWarning = null;
      _filtersEndpoint = endpoint;
    } catch (_) {
      if (request != _filtersRequest || endpoint != _apiService.baseUrl) return;
      _areas = List.of(AppConstants.areaOptions);
      _meals = List.of(AppConstants.mealOptions);
      _filtersEndpoint = null;
      _filtersWarning =
          'Catalogue filters could not be updated. Showing default options.';
    }
    if (!_areas.contains(_selectedArea)) _selectedArea = 'All Areas';
    if (!_meals.contains(_selectedMeal)) _selectedMeal = 'any';
    notifyListeners();
  }

  Future<void> fetchRecommendations(String userId) async {
    final request = ++_request;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await loadFilters();
      if (request != _request) return;
      final response = await _apiService.getRecommendations(
        userId,
        meal: _selectedMeal,
        area: _selectedArea,
        n: 10,
      );
      if (request != _request) return;
      _response = response;
    } catch (e) {
      if (request != _request) return;
      _errorMessage = e.toString();
      _response = null;
    } finally {
      if (request == _request) {
        _isLoading = false;
        notifyListeners();
      }
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
