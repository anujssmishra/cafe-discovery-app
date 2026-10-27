import 'dart:convert';
import '../models/food_order.dart';

enum FoodOrderFormat { auto, csv, json, receipt }

class FoodOrderParseResult {
  final List<FoodOrder> orders;
  final List<FoodOrderIssue> parsingIssues;
  const FoodOrderParseResult(
      {this.orders = const [], this.parsingIssues = const []});
  List<FoodOrderIssue> get issues =>
      [...parsingIssues, ...orders.expand((order) => order.issues)];
  int get totalRows => orders.length;
  int get importableCount => orders.where((order) => order.isImportable).length;
  int get invalidCount => orders
      .where((order) => order.issues.any((issue) => issue.isError))
      .length;
  int get excludedCount => orders
      .where((order) =>
          order.isExcluded && !order.issues.any((issue) => issue.isError))
      .length;
}

/// Reads the app's documented order format and conservative explicit receipt
/// fields. No account API, HTML scraping, raw-text storage or network access.
class FoodOrderParser {
  static const maxBytes = 5 * 1024 * 1024;
  static const maxRows = 1000;

  static FoodOrderParseResult parse(String content,
      {FoodOrderFormat format = FoodOrderFormat.auto, String? platformHint}) {
    if (utf8.encode(content).length > maxBytes) {
      return _problem('file_too_large', 'Use a file no larger than 5 MiB.');
    }
    final input = content.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
    if (input.isEmpty) {
      return _problem(
          'empty_input', 'Choose an order file or paste a receipt.');
    }
    if (format == FoodOrderFormat.auto) {
      if (input.startsWith('[') || input.startsWith('{')) {
        format = FoodOrderFormat.json;
      } else {
        final firstLine = input.split(RegExp(r'\r?\n')).first;
        format = firstLine.contains(',') &&
                RegExp(r'order[ _-]?(?:id|number|no)|restaurant',
                        caseSensitive: false)
                    .hasMatch(firstLine)
            ? FoodOrderFormat.csv
            : FoodOrderFormat.receipt;
      }
    }
    switch (format) {
      case FoodOrderFormat.json:
        return _json(input, platformHint);
      case FoodOrderFormat.csv:
        return _csv(input, platformHint);
      case FoodOrderFormat.receipt:
        return _receipt(input, platformHint);
      case FoodOrderFormat.auto:
        return _problem(
            'unsupported_format', 'Choose CSV, JSON or a plaintext receipt.');
    }
  }

  static FoodOrderParseResult parseCsv(String content,
          {String? platformHint}) =>
      parse(content, format: FoodOrderFormat.csv, platformHint: platformHint);
  static FoodOrderParseResult parseJson(String content,
          {String? platformHint}) =>
      parse(content, format: FoodOrderFormat.json, platformHint: platformHint);
  static FoodOrderParseResult parseReceipt(String content,
          {String? platformHint}) =>
      parse(content,
          format: FoodOrderFormat.receipt, platformHint: platformHint);

  static FoodOrderParseResult _problem(String code, String message,
          {int row = 0}) =>
      FoodOrderParseResult(parsingIssues: [
        FoodOrderIssue(
            rowNumber: row, field: 'file', code: code, message: message)
      ]);

  static FoodOrderParseResult _json(String input, String? hint) {
    dynamic decoded;
    try {
      decoded = jsonDecode(input);
    } catch (_) {
      return _problem('invalid_json',
          'This is not valid JSON. Use an array or an object containing an orders array.');
    }
    final rows = decoded is Map ? decoded['orders'] : decoded;
    if (rows is! List) {
      return _problem('invalid_json_shape',
          'Use a JSON array or {"orders": [...]} in the app format.');
    }
    if (rows.length > maxRows) {
      return _problem(
          'too_many_rows', 'Use at most 1,000 order rows per import.');
    }
    if (rows.isEmpty) {
      return _problem('empty_orders', 'The file contains no order rows.');
    }
    final orders = <FoodOrder>[];
    final problems = <FoodOrderIssue>[];
    for (var index = 0; index < rows.length; index++) {
      if (rows[index] is! Map) {
        orders.add(FoodOrder(
            rowNumber: index + 1, platform: FoodOrder.normalizePlatform(hint)));
        problems.add(FoodOrderIssue(
            rowNumber: index + 1,
            field: 'row',
            code: 'invalid_row',
            message: 'Each order must be a JSON object.'));
      } else {
        orders.add(_fromMap(
            Map<String, dynamic>.from(rows[index] as Map), index + 1, hint));
      }
    }
    return FoodOrderParseResult(
        orders: List.unmodifiable(orders), parsingIssues: problems);
  }

  static FoodOrder fromOrderPayload(Map<String, dynamic> source,
          {int rowNumber = 1, String? platformHint}) =>
      _fromMap(source, rowNumber, platformHint);

  static FoodOrder _fromMap(
      Map<String, dynamic> source, int row, String? hint) {
    final data = {
      for (final entry in source.entries) _header(entry.key): entry.value
    };
    dynamic read(List<String> aliases) {
      for (final alias in aliases) {
        if (data.containsKey(alias) &&
            data[alias] != null &&
            data[alias].toString().trim().isNotEmpty) {
          return data[alias];
        }
      }
      return null;
    }

    String? string(dynamic value) =>
        value is String || value is num ? value.toString().trim() : null;
    final platform = FoodOrder.normalizePlatform(
        string(read(['platform', 'order_platform', 'app', 'source'])) ?? hint);
    var restaurant = read(
        ['restaurant_name', 'restaurant', 'merchant_name', 'restaurantname']);
    if (restaurant is Map) restaurant = restaurant['name'];
    final amountRaw = read([
      'amount',
      'amount_paid',
      'total_paid',
      'grand_total',
      'order_total',
      'total_amount',
      'final_total',
      'paid_amount',
      'total'
    ]);
    final amount = _amount(amountRaw);
    final explicitCurrency =
        string(read(['currency', 'currency_code']))?.toUpperCase();
    final currency = explicitCurrency ??
        (_hasInr(amountRaw?.toString() ?? '') ? 'INR' : null);
    final timezone = string(read(['timezone', 'time_zone'])) ?? 'Asia/Kolkata';
    final time = FoodOrder.normalizeTime(
        string(read([
          'order_time',
          'ordered_at',
          'order_date',
          'date',
          'placed_at',
          'timestamp'
        ])),
        timezone: timezone);
    final precision =
        string(read(['time_precision']))?.toLowerCase() ?? time.precision;
    final rawDishes = read(['dish_names', 'items', 'dishes', 'order_items']);
    final dishes = <String>[];
    if (rawDishes is List) {
      for (final item in rawDishes) {
        if (item is String) {
          dishes.add(item.trim());
        } else if (item is Map) {
          final name = item['name'] ?? item['item_name'] ?? item['dish_name'];
          dishes.add(string(name) ?? '');
        } else {
          dishes.add(
              ''); // Invalid evidence is reviewable, never silently dropped.
        }
      }
    } else if (rawDishes is String) {
      dishes.addAll(rawDishes.split('|').map((dish) => dish.trim()));
    } else if (rawDishes != null) {
      dishes.add('');
    }
    return FoodOrder(
        rowNumber: row,
        platform: platform,
        orderId: string(
            read(['order_id', 'orderid', 'order_number', 'order_no', 'id'])),
        restaurantName: string(restaurant),
        amount: amount,
        status: string(read(['order_status', 'status', 'payment_status']))
            ?.toLowerCase(),
        currency: currency,
        orderTime: time.value,
        timePrecision: precision,
        timezone: timezone,
        cuisine: string(read(['cuisine', 'cuisine_type']))
            ?.toLowerCase()
            .replaceAll(' ', '_'),
        dishNames: List.unmodifiable(dishes),
        upiRef: string(
            read(['upi_ref', 'upi_reference', 'payment_reference', 'rrn'])));
  }

  static String _header(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  static bool _hasInr(String value) =>
      RegExp(r'₹|\b(?:INR|Rs\.?)\s*', caseSensitive: false).hasMatch(value);
  static double? _amount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is! String) return null;
    final text = value.trim().replaceAll(
        RegExp(r'^(?:INR|Rs\.?)\s*|^₹\s*', caseSensitive: false), '');
    // Reject mixed currency, arbitrary descriptions and malformed grouping.
    if (!RegExp(
            r'^(?:\d+(?:\.\d{1,2})?|\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d{1,2}(?:,\d{2})*,\d{3}(?:\.\d{1,2})?)$')
        .hasMatch(text)) {
      return null;
    }
    return double.tryParse(text.replaceAll(',', ''));
  }

  static FoodOrderParseResult _csv(String input, String? hint) {
    final records = <_CsvRecord>[];
    final fields = <String>[];
    var field = StringBuffer();
    var quoted = false, afterQuote = false;
    var line = 1, recordLine = 1;
    void finishField() {
      fields.add(field.toString());
      field = StringBuffer();
      afterQuote = false;
    }

    void finishRecord() {
      finishField();
      if (fields.any((cell) => cell.trim().isNotEmpty)) {
        records.add(_CsvRecord(List.of(fields), recordLine));
      }
      fields.clear();
    }

    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (quoted) {
        if (char == '"') {
          if (index + 1 < input.length && input[index + 1] == '"') {
            field.write('"');
            index++;
          } else {
            quoted = false;
            afterQuote = true;
          }
        } else {
          field.write(char);
          if (char == '\n') line++;
        }
        continue;
      }
      if (char == '"') {
        if (field.isNotEmpty || afterQuote) {
          return _problem('invalid_csv',
              'Quote a complete CSV field and escape quotes by doubling them.',
              row: line);
        }
        quoted = true;
      } else if (char == ',') {
        finishField();
      } else if (char == '\n' || char == '\r') {
        finishRecord();
        if (char == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }
        line++;
        recordLine = line;
      } else if (afterQuote) {
        if (char.trim().isNotEmpty) {
          return _problem(
              'invalid_csv', 'Unexpected text after a quoted CSV field.',
              row: line);
        }
      } else {
        field.write(char);
      }
      if (records.length > maxRows + 1) {
        return _problem(
            'too_many_rows', 'Use at most 1,000 order rows per import.');
      }
    }
    if (quoted) {
      return _problem('invalid_csv', 'A quoted CSV field is not closed.',
          row: recordLine);
    }
    if (field.isNotEmpty || fields.isNotEmpty || afterQuote) finishRecord();
    if (records.length < 2) {
      return _problem('empty_orders',
          'The CSV needs a header row and at least one order row.');
    }
    if (records.length - 1 > maxRows) {
      return _problem(
          'too_many_rows', 'Use at most 1,000 order rows per import.');
    }
    final headers = records.first.fields.map(_header).toList();
    if (headers.any((header) => header.isEmpty) ||
        headers.toSet().length != headers.length) {
      return _problem(
          'invalid_headers', 'CSV headers must be nonempty and unique.');
    }
    final orders = <FoodOrder>[];
    final problems = <FoodOrderIssue>[];
    for (final record in records.skip(1)) {
      if (record.fields.length != headers.length) {
        problems.add(FoodOrderIssue(
            rowNumber: record.line,
            field: 'row',
            code: 'column_count',
            message:
                'This row has a different number of fields than the header.'));
      }
      final map = <String, dynamic>{};
      for (var index = 0; index < headers.length; index++) {
        if (index < record.fields.length) {
          map[headers[index]] = record.fields[index];
        }
      }
      // Preserve malformed rows for correction; importing is blocked by the row issue.
      final parsed = _fromMap(map, record.line, hint);
      orders.add(record.fields.length == headers.length
          ? parsed
          : parsed.copyWith(parsingIssues: [
              FoodOrderIssue(
                  rowNumber: record.line,
                  field: 'row',
                  code: 'column_count',
                  message:
                      'Correct this row in the source file: its field count differs from the header.'),
            ]));
    }
    return FoodOrderParseResult(
        orders: List.unmodifiable(orders), parsingIssues: problems);
  }

  static FoodOrderParseResult _receipt(String input, String? hint) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final data = <String, dynamic>{};
    final platforms = RegExp(r'\b(Swiggy|Zomato)\b', caseSensitive: false)
        .allMatches(input)
        .map((match) => FoodOrder.normalizePlatform(match.group(1)))
        .toSet();
    data['platform'] = platforms.length == 1 ? platforms.single : hint;
    final receiptIds = <String>{};
    final restaurants = <String>{};
    final totals = <double>{};
    final dishes = <String>[];
    var inItems = false;
    for (final line in lines) {
      final label = RegExp(r'^([A-Za-z _-]+)\s*[:=]\s*(.+)$').firstMatch(line);
      final key = label == null ? '' : _header(label.group(1)!);
      final value = label?.group(2)?.trim();
      if ({'restaurant', 'restaurant_name', 'ordered_from', 'order_from'}
          .contains(key)) {
        data['restaurant_name'] = value;
        if (value != null) {
          restaurants
              .add(value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim());
        }
      }
      if ({'order_id', 'order_number', 'order_no'}.contains(key)) {
        data['order_id'] = value?.replaceFirst(RegExp(r'^#\s*'), '');
        if (data['order_id'] != null) {
          receiptIds.add(data['order_id'].toString());
        }
      }
      final unlabeledId = RegExp(
              r'^Order\s*(?:(?:ID|number|no\.?)\s*)?#\s*([A-Za-z0-9_-]+)$',
              caseSensitive: false)
          .firstMatch(line);
      if (unlabeledId != null) {
        data['order_id'] = unlabeledId.group(1);
        receiptIds.add(unlabeledId.group(1)!);
      }
      if ({'order_date', 'order_time', 'ordered_at', 'date'}.contains(key)) {
        data['order_time'] = value;
      }
      if ({'status', 'order_status', 'payment_status'}.contains(key)) {
        data['status'] = value;
      }
      if ({'currency', 'currency_code'}.contains(key)) data['currency'] = value;
      if ({'upi_ref', 'upi_reference', 'payment_reference', 'rrn'}
          .contains(key)) {
        data['upi_ref'] = value;
      }
      if (key == 'cuisine') data['cuisine'] = value;
      if (key == 'timezone' || key == 'time_zone') data['timezone'] = value;
      final total = RegExp(
              r'^(?:grand\s+total|total\s+(?:paid|amount\s+paid)|amount\s+paid|final\s+total|paid\s+total)\s*[:=]?\s*(.+)$',
              caseSensitive: false)
          .firstMatch(line);
      if (total != null) {
        final raw = total.group(1)!;
        final parsed = _amount(raw);
        if (parsed != null) totals.add(parsed);
        if (_hasInr(raw) && data['currency'] == null) data['currency'] = 'INR';
        inItems = false;
      }
      if (RegExp(r'^(?:items|order\s+items|dishes|items\s+ordered)\s*:?$',
              caseSensitive: false)
          .hasMatch(line)) {
        inItems = true;
        continue;
      }
      if (RegExp(r'^(?:subtotal|item\s+total|tax|GST|delivery|packaging|discount|tip|total|bill|payment|address|deliver\s+to|customer|contact|phone|email|OTP)\b',
                  caseSensitive: false)
              .hasMatch(line) ||
          label != null) {
        inItems = false;
      }
      if (inItems) {
        // Only a quantity-marked item inside an explicit items section qualifies.
        final item = RegExp(
                r'^(?:[-•]\s*)?(?:\d{1,2}\s*[x×]\s+(.+?)|(.+?)\s*[x×]\s*\d{1,2})(?:\s+(?:₹|Rs\.?|INR)\s*[\d,.]+)?$',
                caseSensitive: false)
            .firstMatch(line);
        final name = item?.group(1) ?? item?.group(2);
        if (name != null &&
            !RegExp(r'\b(?:OTP|phone|address|delivery|customer|email)\b|@|\b\d{10}\b',
                    caseSensitive: false)
                .hasMatch(name)) {
          dishes.add(name.trim());
        }
      }
    }
    if (receiptIds.length > 1 || restaurants.length > 1) {
      return _problem('multiple_orders',
          'Paste one receipt at a time. Multiple order IDs or conflicting restaurant names were found.',
          row: 1);
    }
    data['dish_names'] = dishes;
    final problems = <FoodOrderIssue>[];
    if (totals.length == 1) data['amount'] = totals.single;
    if (totals.length > 1) {
      problems.add(const FoodOrderIssue(
          rowNumber: 1,
          field: 'amount',
          code: 'ambiguous_total',
          message:
              'Conflicting final totals were found. Enter the actual amount paid.'));
    }
    final order = _fromMap(data, 1, hint);
    return FoodOrderParseResult(orders: [order], parsingIssues: problems);
  }
}

class _CsvRecord {
  final List<String> fields;
  final int line;
  const _CsvRecord(this.fields, this.line);
}
