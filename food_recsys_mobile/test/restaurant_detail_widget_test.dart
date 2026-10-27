import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recsys_mobile/models/restaurant.dart';
import 'package:food_recsys_mobile/screens/restaurant_detail_screen.dart';
import 'package:food_recsys_mobile/services/api_service.dart';

class RestaurantDetailsApi extends ApiService {
  int requests = 0;

  @override
  Future<Restaurant> getRestaurant(String id) async {
    requests++;
    return Restaurant.fromJson({
      'id': id,
      'name': 'Example cafe',
      'area': 'Mall Avenue',
      'city': 'Lucknow',
      'address': 'Example street',
      'is_active': true,
      'website': 'https://example.com/cafe',
      'vibe_tags': ['Quiet seating'],
      'food_highlights': ['Sourdough'],
      'offerings': [
        {
          'drink_type': 'Coffee',
          'brewing_method': 'Pour over',
          'price': null,
          'currency': 'INR',
          'checked_on': '2026-10-20',
          'source': 'Example menu'
        }
      ],
    });
  }
}

void main() {
  testWidgets(
      'details expose public metadata with honest unknown prices and rating',
      (tester) async {
    final api = RestaurantDetailsApi();
    await tester.pumpWidget(MaterialApp(
        home: RestaurantDetailScreen(apiService: api, restaurantId: 'cafe')));
    await tester.pumpAndSettle();
    expect(api.requests, 1);
    expect(find.text('Example cafe'), findsOneWidget);
    expect(find.text('Example street'), findsOneWidget);
    expect(find.text('Price tier unknown'), findsOneWidget);
    expect(find.text('Rating not recorded'), findsOneWidget);
    expect(find.text('Quiet seating'), findsOneWidget);
    expect(find.text('Sourdough'), findsOneWidget);
    final detailsScrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.text('Price unknown'), 200,
        scrollable: detailsScrollable);
    expect(find.text('Coffee • Pour over'), findsOneWidget);
    expect(find.text('Example menu • 2026-10-20'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Website link'), 200,
        scrollable: detailsScrollable);
    expect(find.text('https://example.com/cafe'), findsOneWidget);
    expect(api.requests, 1);
  });
}
