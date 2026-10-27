import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recsys_mobile/screens/dining_ledger_sheet.dart';
import 'package:food_recsys_mobile/services/api_service.dart';

class PagedLedgerApi extends ApiService {
  final List<String?> cursors = [];
  bool failNextPage = false;

  @override
  Future<Map<String, dynamic>> getTransactions(String userId,
      {int limit = 100, String? cursor}) async {
    cursors.add(cursor);
    if (cursor != null && failNextPage) {
      failNextPage = false;
      throw Exception('offline');
    }
    final firstPage = cursor == null;
    return {
      'total_count': 3,
      'total_spent': 99.50,
      'has_more': firstPage,
      'next_cursor': firstPage ? 'next-page' : null,
      'transactions': firstPage
          ? [
              {
                'id': 'one',
                'merchant_name': 'First cafe',
                'amount': 30.25,
                'transaction_time': '2026-10-26T08:00:00Z',
                'orders': [
                  {
                    'platform': 'Swiggy',
                    'order_id': 'SYNTHETIC_42',
                    'restaurant_name': 'First cafe',
                    'dish_names': ['Synthetic sandwich'],
                  }
                ],
                'classification_status': 'matched'
              },
              {
                'id': 'two',
                'merchant_name': 'Second cafe',
                'amount': 39.25,
                'classification_status': 'unresolved'
              },
            ]
          : [
              {
                'id': 'three',
                'merchant_name': 'Older cafe',
                'amount': 30.0,
                'classification_status': 'matched',
                'meal_type': 'lunch',
                'cuisine': 'bakery'
              },
            ],
    };
  }
}

void main() {
  testWidgets('ledger keeps full totals while loading subsequent pages',
      (tester) async {
    final api = PagedLedgerApi();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DiningLedgerSheet(apiService: api, userId: 'user'))));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3 transactions loaded'), findsOneWidget);
    expect(find.text('₹99.50 total across all transactions'), findsOneWidget);
    expect(find.text('Classification: unresolved'), findsOneWidget);
    expect(find.text('Swiggy order #SYNTHETIC_42'), findsOneWidget);
    expect(find.text('Dishes: Synthetic sandwich'), findsOneWidget);
    expect(find.textContaining('Meal time unknown'), findsNWidgets(2));
    await tester.tap(find.text('Load more transactions'));
    await tester.pumpAndSettle();
    expect(api.cursors, [null, 'next-page']);
    expect(find.text('3 of 3 transactions loaded'), findsOneWidget);
    expect(find.text('Older cafe'), findsOneWidget);
    expect(find.text('All transactions loaded.'), findsOneWidget);
  });

  testWidgets(
      'failed later page preserves loaded transactions and retry cursor',
      (tester) async {
    final api = PagedLedgerApi()..failNextPage = true;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DiningLedgerSheet(apiService: api, userId: 'user'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more transactions'));
    await tester.pumpAndSettle();
    expect(find.text('First cafe'), findsOneWidget);
    expect(find.text('2 of 3 transactions loaded'), findsOneWidget);
    await tester.tap(find.text('Retry ledger'));
    await tester.pumpAndSettle();
    expect(api.cursors, [null, 'next-page', 'next-page']);
    expect(find.text('3 of 3 transactions loaded'), findsOneWidget);
  });
}
