import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recsys_mobile/models/food_order.dart';
import 'package:food_recsys_mobile/services/food_order_parser.dart';

Map<String, dynamic> syntheticOrder(
        {String platform = 'Swiggy', String id = 'SYNTH_001'}) =>
    {
      'platform': platform,
      'order_id': id,
      'restaurant_name': 'Synthetic River Cafe',
      'amount': 480,
      'currency': 'INR',
      'status': 'delivered',
      'order_time': '2026-10-24T00:15:00+05:30',
      'dish_names': ['Masala dosa', 'Filter coffee'],
      'upi_ref': 'SYNTH_REF_1',
    };

void main() {
  test(
      'canonical JSON maps stable platform order identity and all safe evidence',
      () {
    final result = FoodOrderParser.parse(jsonEncode({
      'orders': [syntheticOrder()]
    }));
    expect(result.importableCount, 1);
    final order = result.orders.single;
    expect(order.sourceId, 'order:swiggy:SYNTH_001');
    expect(order.orderTime, '2026-10-24T00:15:00+05:30');
    expect(order.timePrecision, 'exact');
    expect(order.dishNames, ['Masala dosa', 'Filter coffee']);
    expect(order.upiRef, 'SYNTH_REF_1');
    expect(order.toOrderPayload()['source_id'], order.sourceId);
    expect(order.toPaymentPayload()['order_platform'], 'Swiggy');
    expect(order.toPaymentPayload()['currency'], 'INR');
    expect(
        order.toPaymentPayload(
            linkedTransactionId: 'synthetic-tx')['linked_transaction_id'],
        'synthetic-tx');
  });

  test(
      'JSON aliases handle explicit final totals, nested restaurant and item names',
      () {
    final result = FoodOrderParser.parseJson(jsonEncode([
      {
        'app': 'zomato',
        'order_number': 'Z-001',
        'restaurant': {'name': 'Synthetic Kitchen'},
        'grand_total': 'Rs. 1,250.50',
        'order_status': 'PAID',
        'ordered_at': '24/10/2026 7:15 PM',
        'items': [
          {'name': 'Paneer bowl', 'quantity': 2},
          {'name': 'Lime drink', 'quantity': 1}
        ]
      },
    ]));
    final order = result.orders.single;
    expect(order.isImportable, true);
    expect(order.platform, 'Zomato');
    expect(order.sourceId, 'order:zomato:Z-001');
    expect(order.amount, 1250.5);
    expect(order.orderTime, '2026-10-24T19:15:00+05:30');
    expect(order.dishNames, ['Paneer bowl', 'Lime drink']);
  });

  test('unknown required fields remain editable and are never invented', () {
    final result =
        FoodOrderParser.parseJson('[{"order_id":"SYNTH_1","subtotal":120}]');
    final order = result.orders.single;
    expect(order.platform, isNull);
    expect(order.restaurantName, isNull);
    expect(order.amount, isNull);
    expect(order.status, isNull);
    expect(order.currency, isNull);
    expect(order.orderTime, isNull);
    expect(order.timePrecision, 'unknown');
    expect(result.invalidCount, 1);
    expect(order.isImportable, false);
  });

  test(
      'completed orders require explicit INR and cancelled/refunded/unknown stay excluded',
      () {
    final result = FoodOrderParser.parseJson(jsonEncode([
      {...syntheticOrder(), 'currency': 'USD'},
      {...syntheticOrder(id: 'SYNTH_2'), 'status': 'cancelled'},
      {...syntheticOrder(id: 'SYNTH_3'), 'status': 'refunded'},
      {...syntheticOrder(id: 'SYNTH_4'), 'status': 'unknown'},
      {...syntheticOrder(id: 'SYNTH_5'), 'status': 'completed'},
    ]));
    expect(result.importableCount, 1);
    expect(result.excludedCount, 3);
    expect(result.invalidCount, 1);
    expect(result.totalRows, 5);
  });

  test('CSV handles BOM, quoted commas/newlines/escaped quotes and pipe dishes',
      () {
    const csv =
        '\uFEFFplatform,order_id,restaurant_name,amount,currency,status,order_time,dish_names\r\n'
        'Swiggy,SYNTH_CSV,"Synthetic Cafe, ""River""\nBranch","1,250.50",INR,delivered,24-10-2026,"Dosa|Filter coffee"\r\n';
    final result = FoodOrderParser.parse(csv);
    expect(result.importableCount, 1);
    final order = result.orders.single;
    expect(order.rowNumber, 2);
    expect(order.restaurantName, 'Synthetic Cafe, "River"\nBranch');
    expect(order.amount, 1250.5);
    expect(order.dishNames, ['Dosa', 'Filter coffee']);
    expect(order.orderTime, '2026-10-24');
    expect(order.timePrecision, 'date');
  });

  test('CSV column mismatch preserves known fields but blocks the row', () {
    final result = FoodOrderParser.parseCsv(
        'platform,order_id,restaurant_name,amount,currency,status\nSwiggy,SYNTH_ID,Synthetic Cafe,400,INR,paid,EXTRA');
    expect(result.orders.single.orderId, 'SYNTH_ID');
    expect(result.orders.single.isImportable, false);
    expect(result.issues.any((issue) => issue.code == 'column_count'), true);
    expect(result.invalidCount, 1);
  });

  test('CSV rejects malformed quotes, duplicate headers and header-only input',
      () {
    expect(
        FoodOrderParser.parseCsv('order_id,restaurant_name\nSYNTH,"Unclosed')
            .issues
            .first
            .code,
        'invalid_csv');
    expect(FoodOrderParser.parseCsv('order_id,Order ID\na,b').issues.first.code,
        'invalid_headers');
    expect(FoodOrderParser.parseCsv('order_id,amount').issues.first.code,
        'empty_orders');
  });

  test(
      'plaintext receipt reads explicit final total and bounded item section only',
      () {
    const receipt = '''Swiggy order receipt — synthetic example
Order ID: SYNTH_RECEIPT_1
Restaurant: Synthetic Garden Kitchen
Order Date: 24 Oct 2026 at 7:15 PM IST
Order Status: Delivered
Items:
2 x Masala dosa INR 240.00
1 x Filter coffee INR 80.00
Subtotal: INR 320.00
Delivery address: 2 x Private Lane
Customer: Synthetic Customer
Phone: 9876543210
OTP: 123456
Delivery fee: INR 30.00
Grand Total: INR 350.00
UPI Ref: SYNTH_REF_10''';
    final result = FoodOrderParser.parseReceipt(receipt);
    final order = result.orders.single;
    expect(order.isImportable, true);
    expect(order.amount, 350);
    expect(order.orderTime, '2026-10-24T19:15:00+05:30');
    expect(order.dishNames, ['Masala dosa', 'Filter coffee']);
    final payload = jsonEncode(order.toOrderPayload());
    expect(payload, isNot(contains('Private Lane')));
    expect(payload, isNot(contains('Synthetic Customer')));
    expect(payload, isNot(contains('9876543210')));
    expect(payload, isNot(contains('123456')));
    expect(payload, isNot(contains('receipt')));
  });

  test(
      'receipt subtotal does not stand in for paid amount; statuses are never assumed',
      () {
    final result = FoodOrderParser.parseReceipt(
        'Zomato\nOrder #SYNTH_1\nRestaurant: Synthetic Cafe\nSubtotal: INR 450\nItems:\n1 x Coffee');
    final order = result.orders.single;
    expect(order.orderId, 'SYNTH_1');
    expect(order.amount, isNull);
    expect(order.status, isNull);
    expect(order.isImportable, false);
  });

  test(
      'conflicting receipt final totals need review; explicit foreign currency is retained',
      () {
    final result = FoodOrderParser.parseReceipt(
        'Swiggy\nOrder ID: SYNTH_1\nRestaurant: Synthetic Cafe\nStatus: paid\nCurrency: USD\nGrand Total: Rs 400\nAmount paid: Rs 450');
    expect(result.orders.single.amount, isNull);
    expect(result.orders.single.currency, 'USD');
    expect(result.issues.any((issue) => issue.code == 'ambiguous_total'), true);
    expect(result.orders.single.isImportable, false);
  });

  test(
      'date-only and missing timestamps stay date/unknown without a fabricated clock',
      () {
    final dates = FoodOrderParser.parseJson(jsonEncode([
      {...syntheticOrder(), 'order_time': '24/10/2026'},
      {...syntheticOrder(id: 'SYNTH_2'), 'order_time': null},
    ]));
    expect(dates.orders.first.orderTime, '2026-10-24');
    expect(dates.orders.first.toPaymentPayload()['time_precision'], 'date');
    expect(dates.orders.first.toPaymentPayload()['transaction_time'],
        '2026-10-24');
    expect(dates.orders.last.timePrecision, 'unknown');
    expect(dates.orders.last.toPaymentPayload().containsKey('transaction_time'),
        false);
  });

  test('source timezone offset and UTC timestamps preserve instants', () {
    final utc = FoodOrder.normalizeTime('2026-10-24T01:02:03Z');
    expect(utc.value, '2026-10-24T01:02:03Z');
    final offset = FoodOrder.normalizeTime('2026-10-24T01:02:03-0400');
    expect(offset.value, '2026-10-24T01:02:03-04:00');
    expect(FoodOrder.normalizeTime('24-Oct-26 12:15 AM').value,
        '2026-10-24T00:15:00+05:30');
  });

  test('invalid dates, hours and offsets remain invalid for correction', () {
    for (final time in [
      '2026-02-30',
      '31/04/2026',
      '2026-10-24T25:00:00Z',
      '2026-10-24T10:00:00+19:00',
      'tomorrow'
    ]) {
      final order = FoodOrderParser.fromOrderPayload(
          {...syntheticOrder(), 'order_time': time});
      expect(order.issues.any((issue) => issue.field == 'order_time'), true,
          reason: time);
      expect(order.isImportable, false);
    }
    expect(FoodOrder.normalizeTime('29/02/2024').value, '2024-02-29');
  });

  test(
      'unsupported cuisine, malformed references and excess dishes are visible instead of truncated',
      () {
    final order = FoodOrderParser.fromOrderPayload({
      ...syntheticOrder(),
      'cuisine': 'invented_cuisine',
      'upi_ref': 'not a reference',
      'dish_names': List.generate(21, (index) => 'Synthetic dish $index'),
    });
    expect(order.dishNames.length, 21);
    expect(order.issues.map((issue) => issue.field),
        containsAll(['cuisine', 'upi_ref', 'dish_names']));
    expect(order.isImportable, false);
  });

  test('editable copyWith clears optional fields and recomputes date precision',
      () {
    final initial = FoodOrderParser.fromOrderPayload(syntheticOrder());
    final changed = initial.copyWith(
        platform: 'zomato',
        orderId: 'Z_SYNTH',
        upiRef: null,
        orderTime: '24/10/2026',
        cuisine: 'south_indian');
    expect(changed.sourceId, 'order:zomato:Z_SYNTH');
    expect(changed.upiRef, isNull);
    expect(changed.timePrecision, 'date');
    expect(changed.isImportable, true);
    expect(changed.copyWith(orderTime: null).timePrecision, 'unknown');
    expect(initial.upiRef, 'SYNTH_REF_1');
  });

  test('invalid amounts and IDs stay out of the import selection', () {
    for (final amount in ['₹-100', 'NaN', 0, 100001, 'USD 100', '1,2,3']) {
      expect(
          FoodOrderParser.fromOrderPayload(
              {...syntheticOrder(), 'amount': amount}).isImportable,
          false);
    }
    expect(
        FoodOrderParser.fromOrderPayload(
            {...syntheticOrder(), 'order_id': 'unsafe/id'}).sourceId,
        isNull);
    expect(
        FoodOrderParser.fromOrderPayload(
            {...syntheticOrder(), 'amount': '₹1,00,000'}).amount,
        100000);
  });

  test('bad JSON shapes and non-object rows report useful issues', () {
    expect(
        FoodOrderParser.parseJson('{broken').issues.first.code, 'invalid_json');
    expect(FoodOrderParser.parseJson('{"orders":{}}').issues.first.code,
        'invalid_json_shape');
    expect(FoodOrderParser.parseJson('[]').issues.first.code, 'empty_orders');
    final rows = FoodOrderParser.parseJson('[42]');
    expect(rows.totalRows, 1);
    expect(rows.invalidCount, 1);
  });

  test('limits reject the complete input rather than silently truncating rows',
      () {
    final rows =
        List.generate(1001, (index) => syntheticOrder(id: 'SYNTH_$index'));
    final tooMany = FoodOrderParser.parseJson(jsonEncode(rows));
    expect(tooMany.orders, isEmpty);
    expect(tooMany.issues.first.code, 'too_many_rows');
    final tooLarge =
        FoodOrderParser.parse('a' * (FoodOrderParser.maxBytes + 1));
    expect(tooLarge.orders, isEmpty);
    expect(tooLarge.issues.first.code, 'file_too_large');
  });
  test(
      'multiple same-amount receipt IDs never combine into one importable order',
      () {
    final result = FoodOrderParser.parseReceipt(
        'Swiggy\nOrder ID: SYNTH_A\nRestaurant: Synthetic River Cafe\nStatus: delivered\nItems:\n1 x Dosa\nGrand Total: INR 400\nOrder #SYNTH_B\nRestaurant: Synthetic River Cafe\nStatus: delivered\nItems:\n1 x Coffee\nGrand Total: INR 400');
    expect(result.orders, isEmpty);
    expect(result.importableCount, 0);
    expect(result.issues.single.code, 'multiple_orders');
  });

  test(
      'conflicting restaurant fields on one receipt require a source correction',
      () {
    final result = FoodOrderParser.parseReceipt(
        'Swiggy\nOrder ID: SYNTH_A\nRestaurant: Synthetic River Cafe\nRestaurant: Synthetic Garden Kitchen\nStatus: paid\nGrand Total: INR 400');
    expect(result.orders, isEmpty);
    expect(result.issues.single.code, 'multiple_orders');
    final repeated = FoodOrderParser.parseReceipt(
        'Swiggy\nOrder ID: SYNTH_A\nRestaurant: Synthetic River Cafe\nRestaurant: SYNTHETIC  RIVER CAFE\nStatus: paid\nGrand Total: INR 400');
    expect(repeated.importableCount, 1);
  });

  test(
      'unsupported timezone needs row review while all documented aliases work',
      () {
    final invalid = FoodOrderParser.fromOrderPayload(
        {...syntheticOrder(), 'timezone': 'Moon/Base'});
    expect(invalid.isImportable, false);
    expect(invalid.issues.any((issue) => issue.field == 'timezone'), true);
    for (final timezone in FoodOrder.supportedTimezones) {
      final valid = FoodOrderParser.fromOrderPayload({
        ...syntheticOrder(),
        'timezone': timezone,
        'order_time': '24/10/2026 19:15'
      });
      expect(valid.isImportable, true, reason: timezone);
      expect(valid.toOrderPayload()['timezone'], timezone);
    }
  });
}
