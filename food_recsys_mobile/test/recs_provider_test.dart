import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recsys_mobile/models/recommendation.dart';
import 'package:food_recsys_mobile/providers/recs_provider.dart';
import 'package:food_recsys_mobile/services/api_service.dart';

class ControlledRecommendationsApi extends ApiService {
  final List<Completer<RecommendationResponse>> requests = [];
  final List<String?> requestedAreas = [];
  bool metadataFails = false;

  @override
  Future<Map<String, dynamic>> getCatalogueMetadata() async {
    if (metadataFails) throw Exception('offline');
    return {
      'areas': ['Area A', 'Area B', 'New neighbourhood'],
      'cuisines': ['bakery'],
      'meal_options': ['breakfast', 'late_night'],
    };
  }

  @override
  Future<RecommendationResponse> getRecommendations(
    String userId, {
    String? meal,
    String? area,
    int n = 10,
  }) {
    requestedAreas.add(area);
    final request = Completer<RecommendationResponse>();
    requests.add(request);
    return request.future;
  }
}

RecommendationResponse recommendationsFor(String area) =>
    RecommendationResponse.fromJson({
      'user_id': 'user',
      'meal_context': 'any',
      'context_message': 'General suggestions',
      'recommendations': [
        {
          'restaurant': {'id': area, 'name': area, 'area': area},
        }
      ],
    });

void main() {
  test('metadata supplies current catalogue areas and late night', () async {
    final provider = RecsProvider(ControlledRecommendationsApi());
    await provider.loadFilters();
    expect(provider.areaOptions, contains('New neighbourhood'));
    expect(provider.mealOptions, contains('late_night'));
    expect(provider.cuisineOptions, ['bakery']);
    expect(provider.filtersWarning, isNull);
  });

  test('metadata failure retains all known catalogue areas', () async {
    final api = ControlledRecommendationsApi()..metadataFails = true;
    final provider = RecsProvider(api);
    await provider.loadFilters();
    expect(
        provider.areaOptions,
        containsAll(
            ['Badshahnagar', 'Cantonment', 'Mall Avenue', 'Nirala Nagar']));
    expect(provider.mealOptions, contains('late_night'));
    expect(provider.filtersWarning, isNotNull);
  });

  test('a slower old filter response cannot replace current recommendations',
      () async {
    final api = ControlledRecommendationsApi();
    final provider = RecsProvider(api);
    await provider.loadFilters();
    provider.setArea('Area A', 'user');
    await Future<void>.delayed(Duration.zero);
    provider.setArea('Area B', 'user');
    await Future<void>.delayed(Duration.zero);
    expect(api.requestedAreas, ['Area A', 'Area B']);
    api.requests[1].complete(recommendationsFor('Area B'));
    await Future<void>.delayed(Duration.zero);
    api.requests[0].complete(recommendationsFor('Area A'));
    await Future<void>.delayed(Duration.zero);
    expect(provider.selectedArea, 'Area B');
    expect(provider.recommendations.single.restaurant.area, 'Area B');
    expect(provider.response!.contextMessage, 'General suggestions');
    expect(provider.isLoading, isFalse);
  });

  test('an old failure cannot clear a successful newer result', () async {
    final api = ControlledRecommendationsApi();
    final provider = RecsProvider(api);
    await provider.loadFilters();
    final older = provider.fetchRecommendations('user');
    await Future<void>.delayed(Duration.zero);
    final newer = provider.fetchRecommendations('user');
    await Future<void>.delayed(Duration.zero);
    api.requests[1].complete(recommendationsFor('Area B'));
    await newer;
    api.requests[0].completeError(Exception('old request failed'));
    await older;
    expect(provider.errorMessage, isNull);
    expect(provider.recommendations.single.restaurant.area, 'Area B');
  });
}
