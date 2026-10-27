import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recsys_mobile/services/order_file_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('food_recsys/order_files');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('document selection returns only the chosen name and UTF-8 text',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickOrderFile');
      return {
        'name': 'synthetic-orders.csv',
        'text': 'restaurant_name,amount\nSynthetic Cafe,250'
      };
    });
    final file = await const OrderFilePicker().pick();
    expect(file!.name, 'synthetic-orders.csv');
    expect(file.text, contains('Synthetic Cafe'));
  });

  test('cancelling the document picker leaves the draft untouched', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await const OrderFilePicker().pick(), isNull);
  });

  test('invalid or oversized file contents are rejected before parsing',
      () async {
    for (final value in [
      {'name': 'binary.txt', 'text': 'abc\u0000def'},
      {'name': 'large.txt', 'text': 'a' * (OrderFilePicker.maxBytes + 1)},
      {'name': 'missing.txt'},
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => value);
      await expectLater(const OrderFilePicker().pick(), throwsFormatException);
    }
  });
}
