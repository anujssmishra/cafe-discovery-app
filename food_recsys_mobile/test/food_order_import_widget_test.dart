import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_recsys_mobile/providers/recs_provider.dart';
import 'package:food_recsys_mobile/providers/taste_provider.dart';
import 'package:food_recsys_mobile/screens/food_order_import_screen.dart';
import 'package:food_recsys_mobile/services/api_service.dart';
import 'package:food_recsys_mobile/services/order_file_picker.dart';
import 'package:food_recsys_mobile/services/sms_listener_service.dart';

class OrderPreviewApi extends ApiService {
  final List<List<Map<String, dynamic>>> previews = [];
  String previewStatus = 'new';
  List<String>? previewStatuses;
  bool failPreview = false;
  Completer<Map<String, dynamic>>? delayedPreview;
  List<Map<String, dynamic>> candidates = [];

  @override
  Future<Map<String, dynamic>> previewFoodOrders(
      String userId, List<Map<String, dynamic>> orders) async {
    previews
        .add(orders.map((order) => Map<String, dynamic>.from(order)).toList());
    if (delayedPreview != null) return delayedPreview!.future;
    if (failPreview) throw Exception('offline');
    return {
      'orders': List.generate(
          orders.length,
          (index) => {
                'source_id': orders[index]['source_id'],
                'status': previewStatuses?[index] ?? previewStatus,
                'candidates': candidates,
              })
    };
  }
}

class OrderImportService extends SmsListenerService {
  final List<List<Map<String, dynamic>>> submissions = [];
  bool acknowledgeDuplicates = false;
  List<String>? acknowledgementStatuses;

  OrderImportService(super.apiService);

  @override
  Future<Map<String, dynamic>> importFoodOrders(
      List<Map<String, dynamic>> orders) async {
    submissions
        .add(orders.map((order) => Map<String, dynamic>.from(order)).toList());
    final statuses = acknowledgementStatuses ??
        List.filled(
            orders.length, acknowledgeDuplicates ? 'duplicate' : 'inserted');
    return {
      'ingested_count': statuses.where((status) => status == 'inserted').length,
      'duplicate_count':
          statuses.where((status) => status == 'duplicate').length,
      'rejected_count': statuses.where((status) => status == 'rejected').length,
      'unresolved_count': 0,
      'pending_count': 0,
      'outcomes': List.generate(
          orders.length,
          (index) => {
                'source_id': orders[index]['source_id'],
                'status': statuses[index]
              }),
    };
  }
}

class OrderTasteProvider extends TasteProvider {
  int refreshes = 0;
  OrderTasteProvider(super.apiService, super.smsListenerService);
  @override
  bool get hasDpdpConsent => true;
  @override
  Future<void> fetchProfile() async {
    refreshes++;
  }
}

class OrderRecsProvider extends RecsProvider {
  int refreshes = 0;
  OrderRecsProvider(super.apiService);
  @override
  Future<void> fetchRecommendations(String userId) async {
    refreshes++;
  }
}

Map<String, dynamic> exampleOrder(
        {String id = 'TEST-001', String status = 'delivered'}) =>
    {
      'platform': 'Swiggy',
      'order_id': id,
      'restaurant_name': 'Example Kitchen',
      'amount': 450.0,
      'currency': 'INR',
      'status': status,
      'order_time': '2026-10-26T19:30:00+05:30',
      'dish_names': ['Paneer bowl'],
      'email': 'private-marker@example.test',
      'address': 'Private marker address',
      'receipt_text': 'Do not send this raw text',
    };

Future<void> showImport(
    WidgetTester tester,
    OrderPreviewApi api,
    OrderImportService service,
    OrderTasteProvider taste,
    OrderRecsProvider recs,
    {Future<OrderImportFile?> Function()? pickFile}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider<ApiService>.value(value: api),
    ChangeNotifierProvider<SmsListenerService>.value(value: service),
    ChangeNotifierProvider<TasteProvider>.value(value: taste),
    ChangeNotifierProvider<RecsProvider>.value(value: recs),
  ], child: MaterialApp(home: FoodOrderImportScreen(pickFile: pickFile))));
}

Finder mainScrollable() => find.byElementPredicate((element) =>
    element.widget is Scrollable &&
    element.findAncestorWidgetOfExactType<Scrollable>() == null);

Future<void> tapLabel(WidgetTester tester, String label,
    {bool upward = false}) async {
  final target = find.text(label);
  await reveal(tester, target, upward: upward);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target,
    {bool upward = false}) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(target), alignment: 0.3);
      await tester.pump();
      if (target.hitTestable().evaluate().isNotEmpty) return;
    }
    final state = tester.state<ScrollableState>(mainScrollable());
    final next = (state.position.pixels + (upward ? -180 : 180))
        .clamp(0.0, state.position.maxScrollExtent);
    state.position.jumpTo(next);
    await tester.pump();
  }
  expect(target.hitTestable(), findsOneWidget,
      reason: 'The target must be visible in the outer order list.');
}

Future<void> parseOrders(
    WidgetTester tester, List<Map<String, dynamic>> orders) async {
  await tester.enterText(find.byType(TextField).first, jsonEncode(orders));
  await tapLabel(tester, 'Parse and review locally');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      '390px file import excludes cancelled rows and sends reviewed fields only',
      (tester) async {
    final api = OrderPreviewApi();
    final service = OrderImportService(api);
    final taste = OrderTasteProvider(api, service);
    final recs = OrderRecsProvider(api);
    await showImport(tester, api, service, taste, recs,
        pickFile: () async => OrderImportFile(
              name: 'my-orders.json',
              text: jsonEncode([
                exampleOrder(),
                exampleOrder(id: 'CANCELLED', status: 'cancelled')
              ]),
            ));
    await tapLabel(tester, 'Choose order file');
    expect(find.text('Selected file: my-orders.json'), findsOneWidget);
    expect(service.submissions, isEmpty);
    await tapLabel(tester, 'Check duplicates');
    expect(api.previews.single, hasLength(1));
    expect(api.previews.single.single['order_id'], 'TEST-001');
    final sent = jsonEncode(api.previews);
    expect(sent, isNot(contains('private-marker')));
    expect(sent, isNot(contains('Private marker address')));
    expect(sent, isNot(contains('receipt_text')));
    await tester.tap(find.text('Import selected (1)'));
    await tester.pumpAndSettle();
    expect(service.submissions.single, hasLength(1));
    expect(taste.refreshes, 1);
    expect(recs.refreshes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'uncertain match stays unselected until an explicit same-amount link',
      (tester) async {
    final api = OrderPreviewApi()
      ..previewStatus = 'review'
      ..candidates = [
        {
          'transaction_id': 'bank-payment',
          'merchant_name': 'Bank dining debit',
          'amount': 450.0,
          'transaction_time': '2026-10-26T14:00:00Z'
        },
        {
          'transaction_id': 'wrong-amount',
          'merchant_name': 'Wrong amount',
          'amount': 999.0
        },
      ];
    final service = OrderImportService(api);
    final taste = OrderTasteProvider(api, service);
    final recs = OrderRecsProvider(api);
    await showImport(tester, api, service, taste, recs);
    await parseOrders(tester, [exampleOrder()]);
    await tapLabel(tester, 'Check duplicates');
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Import selected (0)'))
            .onPressed,
        isNull);
    final link =
        find.textContaining('Link existing payment: Bank dining debit');
    await reveal(tester, link);
    expect(find.textContaining('Link existing payment: Wrong amount'),
        findsNothing);
    await tester.tap(link);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import selected (1)'));
    await tester.pumpAndSettle();
    expect(service.submissions.single.single['linked_transaction_id'],
        'bank-payment');
    expect(service.submissions.single.single.containsKey('import_as_separate'),
        isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'import separate is an explicit choice without a transaction link',
      (tester) async {
    final api = OrderPreviewApi()..previewStatus = 'review';
    final service = OrderImportService(api);
    await showImport(tester, api, service, OrderTasteProvider(api, service),
        OrderRecsProvider(api));
    await parseOrders(tester, [exampleOrder()]);
    await tapLabel(tester, 'Check duplicates');
    expect(service.submissions, isEmpty);
    await tapLabel(tester, 'Import as separate order');
    await tester.tap(find.text('Import selected (1)'));
    await tester.pumpAndSettle();
    expect(
        service.submissions.single.single.containsKey('linked_transaction_id'),
        isFalse);
  });

  testWidgets(
      'editing reviewed fields invalidates duplicate preview before submission',
      (tester) async {
    final api = OrderPreviewApi();
    final service = OrderImportService(api);
    await showImport(tester, api, service, OrderTasteProvider(api, service),
        OrderRecsProvider(api));
    await parseOrders(tester, [exampleOrder()]);
    await tapLabel(tester, 'Check duplicates');
    final edit = find.byTooltip('Edit row 1');
    await reveal(tester, edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Amount paid'), '460');
    final save = find.text('Save reviewed fields');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Import selected (0)'))
            .onPressed,
        isNull);
    expect(service.submissions, isEmpty);
    await tapLabel(tester, 'Check duplicates', upward: true);
    expect(api.previews.last.single['amount'], 460.0);
  });

  testWidgets(
      'duplicate acknowledgement refreshes profile without adding another order',
      (tester) async {
    final api = OrderPreviewApi()..previewStatus = 'duplicate';
    final service = OrderImportService(api)..acknowledgeDuplicates = true;
    final taste = OrderTasteProvider(api, service);
    final recs = OrderRecsProvider(api);
    await showImport(tester, api, service, taste, recs);
    await parseOrders(tester, [exampleOrder()]);
    await tapLabel(tester, 'Check duplicates');
    await tester.tap(find.text('Import selected (1)'));
    await tester.pumpAndSettle();
    expect(taste.refreshes, 1);
    expect(recs.refreshes, 1);
    await reveal(
        tester, find.textContaining('Queue result: 0 inserted • 1 duplicates'),
        upward: true);
    expect(find.textContaining('Queue result: 0 inserted • 1 duplicates'),
        findsOneWidget);
  });

  testWidgets('unavailable preview never enables import', (tester) async {
    final api = OrderPreviewApi()..failPreview = true;
    final service = OrderImportService(api);
    await showImport(tester, api, service, OrderTasteProvider(api, service),
        OrderRecsProvider(api));
    await parseOrders(tester, [exampleOrder()]);
    await tapLabel(tester, 'Check duplicates');
    expect(
        find.text(
            'Duplicate check unavailable. Nothing was imported. Reconnect and check again.'),
        findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Import selected (0)'))
            .onPressed,
        isNull);
    expect(service.submissions, isEmpty);
  });

  testWidgets('response from a previous server cannot select orders',
      (tester) async {
    final api = OrderPreviewApi()
      ..delayedPreview = Completer<Map<String, dynamic>>();
    final service = OrderImportService(api);
    await showImport(tester, api, service, OrderTasteProvider(api, service),
        OrderRecsProvider(api));
    await parseOrders(tester, [exampleOrder()]);
    await reveal(tester, find.text('Check duplicates'));
    await tester.tap(find.text('Check duplicates'));
    await tester.pump();
    await api.setBaseUrl('http://new-server.example.test:8000');
    api.delayedPreview!.complete({
      'orders': [
        {'source_id': 'order:swiggy:TEST-001', 'status': 'new'}
      ]
    });
    await tester.pumpAndSettle();
    expect(
        find.text('Server changed. Review consent and check duplicates again.'),
        findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Import selected (0)'))
            .onPressed,
        isNull);
    expect(service.submissions, isEmpty);
  });

  testWidgets('missing date and dishes need explicit review before preview',
      (tester) async {
    final api = OrderPreviewApi();
    final service = OrderImportService(api);
    await showImport(tester, api, service, OrderTasteProvider(api, service),
        OrderRecsProvider(api));
    final order = exampleOrder()
      ..remove('order_time')
      ..remove('dish_names');
    await parseOrders(tester, [order]);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Check duplicates'))
            .onPressed,
        isNull);
    await tapLabel(
        tester, 'I reviewed the missing date/dishes; keep them unknown.');
    await tapLabel(tester, 'Check duplicates', upward: true);
    expect(api.previews.single.single['time_precision'], 'unknown');
    expect(api.previews.single.single['dish_names'], isEmpty);
    expect(api.previews.single.single.containsKey('order_time'), isFalse);
  });

  testWidgets(
      'repeated order IDs consume each preview and outcome once in row order',
      (tester) async {
    final api = OrderPreviewApi()..previewStatuses = ['new', 'duplicate'];
    final service = OrderImportService(api)
      ..acknowledgementStatuses = ['inserted', 'rejected'];
    await showImport(tester, api, service, OrderTasteProvider(api, service),
        OrderRecsProvider(api));
    await parseOrders(tester, [exampleOrder(), exampleOrder()]);
    await tapLabel(tester, 'Check duplicates');
    await reveal(tester, find.text('Status: new'));
    expect(find.text('Status: new'), findsOneWidget);
    await reveal(tester, find.text('Status: duplicate'));
    expect(find.text('Status: duplicate'), findsOneWidget);
    await tester.tap(find.text('Import selected (2)'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Status: inserted'), upward: true);
    expect(find.text('Status: inserted'), findsOneWidget);
    await reveal(tester, find.text('Status: rejected'));
    expect(find.text('Status: rejected'), findsOneWidget);
    expect(service.submissions.single, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
