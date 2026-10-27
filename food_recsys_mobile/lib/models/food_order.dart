const _notProvided = Object();

class FoodOrderIssue {
  final int rowNumber;
  final String field;
  final String code;
  final String message;
  final bool isError;

  const FoodOrderIssue(
      {required this.rowNumber,
      required this.field,
      required this.code,
      required this.message,
      this.isError = true});
}

class FoodOrderTimestamp {
  final String? value;
  final String precision;
  final bool isValid;
  const FoodOrderTimestamp(this.value, this.precision, {this.isValid = true});
}

/// Editable extracted order fields only. Receipts, addresses, email text and
/// other account information never become part of the draft or upload payload.
class FoodOrder {
  static const supportedCuisines = {
    'south_indian',
    'biryani',
    'mughlai',
    'cafe_western',
    'bakery',
    'street_food',
    'pizza',
    'burger',
    'chinese_indo',
    'north_indian_curry',
    'tea_coffee',
    'dessert',
    'healthy',
    'italian',
    'unspecified',
  };
  static const importableStatuses = {'completed', 'delivered', 'paid'};
  static const supportedTimezones = {
    'Asia/Kolkata',
    'Asia/Calcutta',
    'UTC',
    'GMT',
    'Etc/UTC'
  };
  final int rowNumber;
  final String? platform;
  final String? orderId;
  final String? restaurantName;
  final double? amount;
  final String? status;
  final String? currency;
  final String? orderTime;
  final String timePrecision;
  final String timezone;
  final String? cuisine;
  final List<String> dishNames;
  final String? upiRef;
  final List<FoodOrderIssue> parsingIssues;

  const FoodOrder(
      {this.rowNumber = 1,
      this.platform,
      this.orderId,
      this.restaurantName,
      this.amount,
      this.status,
      this.currency,
      this.orderTime,
      this.timePrecision = 'unknown',
      this.timezone = 'Asia/Kolkata',
      this.cuisine,
      this.dishNames = const [],
      this.upiRef,
      this.parsingIssues = const []});

  String? get sourceId {
    if (!{'Swiggy', 'Zomato'}.contains(platform) ||
        orderId == null ||
        !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(orderId!)) {
      return null;
    }
    return 'order:${platform!.toLowerCase()}:$orderId';
  }

  bool get isExcluded => !importableStatuses.contains(status);
  bool get isImportable => !isExcluded && !issues.any((issue) => issue.isError);

  List<FoodOrderIssue> get issues {
    final result = <FoodOrderIssue>[...parsingIssues];
    void add(String field, String code, String message, {bool isError = true}) {
      result.add(FoodOrderIssue(
          rowNumber: rowNumber,
          field: field,
          code: code,
          message: message,
          isError: isError));
    }

    if (!{'Swiggy', 'Zomato'}.contains(platform)) {
      add('platform', 'unsupported_platform', 'Choose Swiggy or Zomato.');
    }
    if (orderId == null ||
        !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(orderId!)) {
      add('order_id', 'invalid_order_id',
          'Enter an order ID using 1–64 letters, digits, underscores or hyphens.');
    }
    if (restaurantName == null ||
        restaurantName!.trim().isEmpty ||
        restaurantName!.length > 200) {
      add('restaurant_name', 'invalid_restaurant',
          'Enter a restaurant name of at most 200 characters.');
    }
    if (amount == null ||
        !amount!.isFinite ||
        amount! <= 0 ||
        amount! > 100000) {
      add('amount', 'invalid_amount',
          'Enter the final amount paid, above ₹0 and at most ₹100,000.');
    }
    if (currency != 'INR') {
      add('currency', 'unsupported_currency',
          'Only an explicitly identified INR amount can be imported.');
    }
    if (isExcluded) {
      add('status', 'excluded_status',
          'Only completed, delivered or paid orders are selected for import.',
          isError: false);
    }
    if (!{'exact', 'date', 'unknown'}.contains(timePrecision)) {
      add('time_precision', 'invalid_time_precision',
          'Time precision must be exact, date or unknown.');
    }
    if (orderTime == null) {
      if (timePrecision != 'unknown') {
        add('order_time', 'missing_time', 'No date or time was supplied.');
      }
    } else {
      final parsed = normalizeTime(orderTime, timezone: timezone);
      if (!parsed.isValid ||
          parsed.precision == 'unknown' ||
          (timePrecision == 'exact' && parsed.precision != 'exact') ||
          timePrecision == 'unknown') {
        add('order_time', 'invalid_time',
            'Enter a valid date or a timestamp with a timezone offset.');
      }
    }
    if (!supportedTimezones.contains(timezone)) {
      add('timezone', 'invalid_timezone',
          'Use Asia/Kolkata, Asia/Calcutta, UTC, GMT or Etc/UTC for India or UTC order times.');
    }
    if (cuisine != null && !supportedCuisines.contains(cuisine)) {
      add('cuisine', 'unsupported_cuisine',
          'Choose a supported cuisine or leave this field empty.');
    }
    if (dishNames.length > 20 ||
        dishNames.any((dish) => dish.trim().isEmpty || dish.length > 120)) {
      add('dish_names', 'invalid_dishes',
          'Use at most 20 dish names, each containing 1–120 characters.');
    }
    if (upiRef != null && !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(upiRef!)) {
      add('upi_ref', 'invalid_upi_ref',
          'UPI references must contain 1–64 letters, digits, underscores or hyphens.');
    }
    return result;
  }

  FoodOrder copyWith(
      {int? rowNumber,
      Object? platform = _notProvided,
      Object? orderId = _notProvided,
      Object? restaurantName = _notProvided,
      Object? amount = _notProvided,
      Object? status = _notProvided,
      Object? currency = _notProvided,
      Object? orderTime = _notProvided,
      String? timePrecision,
      String? timezone,
      Object? cuisine = _notProvided,
      List<String>? dishNames,
      Object? upiRef = _notProvided,
      List<FoodOrderIssue>? parsingIssues}) {
    final nextTimezone = timezone ?? this.timezone;
    final nextTime = identical(orderTime, _notProvided)
        ? FoodOrderTimestamp(this.orderTime, this.timePrecision)
        : normalizeTime(orderTime as String?, timezone: nextTimezone);
    return FoodOrder(
        rowNumber: rowNumber ?? this.rowNumber,
        platform: identical(platform, _notProvided)
            ? this.platform
            : normalizePlatform(platform as String?),
        orderId: identical(orderId, _notProvided)
            ? this.orderId
            : _optional(orderId as String?),
        restaurantName: identical(restaurantName, _notProvided)
            ? this.restaurantName
            : _optional(restaurantName as String?),
        amount: identical(amount, _notProvided)
            ? this.amount
            : (amount as num?)?.toDouble(),
        status: identical(status, _notProvided)
            ? this.status
            : _optional(status as String?)?.toLowerCase(),
        currency: identical(currency, _notProvided)
            ? this.currency
            : _optional(currency as String?)?.toUpperCase(),
        orderTime: nextTime.value,
        timePrecision: timePrecision ?? nextTime.precision,
        timezone: nextTimezone,
        cuisine: identical(cuisine, _notProvided)
            ? this.cuisine
            : _optional(cuisine as String?)?.toLowerCase().replaceAll(' ', '_'),
        dishNames:
            dishNames == null ? this.dishNames : List.unmodifiable(dishNames),
        upiRef: identical(upiRef, _notProvided)
            ? this.upiRef
            : _optional(upiRef as String?),
        parsingIssues: parsingIssues ?? this.parsingIssues);
  }

  Map<String, dynamic> toOrderPayload({String? linkedTransactionId}) => {
        if (sourceId != null) 'source_id': sourceId,
        'platform': platform,
        'order_id': orderId,
        'restaurant_name': restaurantName,
        'amount': amount,
        'status': status,
        'currency': currency,
        'time_precision': timePrecision,
        'timezone': timezone,
        if (orderTime != null) 'order_time': orderTime,
        if (cuisine != null) 'cuisine': cuisine,
        'dish_names': dishNames,
        if (upiRef != null) 'upi_ref': upiRef,
        if (linkedTransactionId != null)
          'linked_transaction_id': linkedTransactionId,
      };

  Map<String, dynamic> toPaymentPayload({String? linkedTransactionId}) => {
        if (sourceId != null) 'source_id': sourceId,
        'order_platform': platform,
        'order_id': orderId,
        'order_status': status,
        'merchant_name': restaurantName,
        'amount': amount,
        'currency': currency,
        'payment_app': platform,
        'time_precision': timePrecision,
        'timezone': timezone,
        if (orderTime != null) 'transaction_time': orderTime,
        if (cuisine != null) 'cuisine': cuisine,
        'dish_names': dishNames,
        if (upiRef != null) 'upi_ref': upiRef,
        if (linkedTransactionId != null)
          'linked_transaction_id': linkedTransactionId,
      };

  static String? normalizePlatform(String? value) {
    final text = _optional(value);
    if (text?.toLowerCase() == 'swiggy') return 'Swiggy';
    if (text?.toLowerCase() == 'zomato') return 'Zomato';
    return text;
  }

  static String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  static FoodOrderTimestamp normalizeTime(String? input,
      {String timezone = 'Asia/Kolkata'}) {
    final text = _optional(input);
    if (text == null) return const FoodOrderTimestamp(null, 'unknown');
    final iso = RegExp(
            r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{1,2}):(\d{2})(?::(\d{2})(\.\d{1,6})?)?\s*(Z|UTC|IST|[+-]\d{2}:?\d{2})?)?$',
            caseSensitive: false)
        .firstMatch(text);
    final india = RegExp(
            r'^(\d{1,2})[-/ ]([A-Za-z]{3,9}|\d{1,2})[-/ ,]+(\d{4}|\d{2})(?:\s*(?:at|,)??\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?\s*(Z|UTC|IST|[+-]\d{2}:?\d{2})?)?$',
            caseSensitive: false)
        .firstMatch(text);
    if (iso == null && india == null) {
      return FoodOrderTimestamp(text, 'unknown', isValid: false);
    }
    int year, month, day;
    int? hour;
    int minute = 0, second = 0;
    String? zone;
    String fraction = '';
    if (iso != null) {
      year = int.parse(iso.group(1)!);
      month = int.parse(iso.group(2)!);
      day = int.parse(iso.group(3)!);
      hour = int.tryParse(iso.group(4) ?? '');
      minute = int.tryParse(iso.group(5) ?? '') ?? 0;
      second = int.tryParse(iso.group(6) ?? '') ?? 0;
      fraction = iso.group(7) ?? '';
      zone = iso.group(8)?.toUpperCase();
    } else {
      final match = india!;
      day = int.parse(match.group(1)!);
      final monthText = match.group(2)!.toLowerCase();
      month = int.tryParse(monthText) ??
          const [
                'jan',
                'feb',
                'mar',
                'apr',
                'may',
                'jun',
                'jul',
                'aug',
                'sep',
                'oct',
                'nov',
                'dec'
              ].indexOf(monthText.substring(0, 3)) +
              1;
      year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      hour = int.tryParse(match.group(4) ?? '');
      minute = int.tryParse(match.group(5) ?? '') ?? 0;
      second = int.tryParse(match.group(6) ?? '') ?? 0;
      final amPm = match.group(7)?.toUpperCase();
      if (hour != null && amPm != null) {
        if (hour < 1 || hour > 12) {
          return FoodOrderTimestamp(text, 'unknown', isValid: false);
        }
        hour = hour % 12 + (amPm == 'PM' ? 12 : 0);
      }
      zone = match.group(8)?.toUpperCase();
    }
    if (year < 1900 ||
        year > 2200 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > DateTime.utc(year, month + 1, 0).day ||
        (hour != null && hour > 23) ||
        minute > 59 ||
        second > 59) {
      return FoodOrderTimestamp(text, 'unknown', isValid: false);
    }
    String pad(int value) => value.toString().padLeft(2, '0');
    final date = '$year-${pad(month)}-${pad(day)}';
    if (hour == null) return FoodOrderTimestamp(date, 'date');
    if (zone == null) {
      if ({'Asia/Kolkata', 'Asia/Calcutta'}.contains(timezone)) {
        zone = '+05:30';
      } else if ({'UTC', 'GMT', 'Etc/UTC'}.contains(timezone)) {
        zone = 'Z';
      } else {
        return FoodOrderTimestamp(text, 'unknown', isValid: false);
      }
    }
    if (zone == 'IST') zone = '+05:30';
    if (zone == 'UTC') zone = 'Z';
    if (zone != 'Z') {
      final digits = zone.replaceAll(':', '');
      final zoneHours = int.tryParse(digits.substring(1, 3));
      final zoneMinutes = int.tryParse(digits.substring(3, 5));
      if (zoneHours == null ||
          zoneHours > 14 ||
          zoneMinutes == null ||
          zoneMinutes > 59 ||
          (zoneHours == 14 && zoneMinutes != 0)) {
        return FoodOrderTimestamp(text, 'unknown', isValid: false);
      }
      zone = '${digits.substring(0, 3)}:${digits.substring(3)}';
    }
    return FoodOrderTimestamp(
        '${date}T${pad(hour)}:${pad(minute)}:${pad(second)}$fraction$zone',
        'exact');
  }
}
