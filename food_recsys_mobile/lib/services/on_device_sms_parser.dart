class ParsedPayment {
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
  final double amount;
  final String rawMerchant;
  final String normalizedMerchant;
  final String? bank;
  final String? upiRef;
  // Available only for a local preview. Never included in an upload or queue.
  final String redactedText;
  final DateTime? timestamp;
  final String? transactionTime;
  final String timezone;
  final String? cuisine;
  final List<String> dishNames;

  ParsedPayment({
    required this.amount,
    required this.rawMerchant,
    required this.normalizedMerchant,
    this.bank,
    this.upiRef,
    required this.redactedText,
    this.timestamp,
    this.transactionTime,
    this.timezone = 'Asia/Kolkata',
    this.cuisine,
    this.dishNames = const [],
  });

  /// Only extracted payment evidence crosses the device boundary.
  Map<String, dynamic> toPaymentPayload({String? sourceId}) {
    final time = transactionTime ?? timestamp?.toUtc().toIso8601String();
    return {
      'source_id': sourceId ??
          stablePaymentSourceId(
            '$upiRef|$normalizedMerchant|${amount.toStringAsFixed(2)}|$time',
          ),
      'merchant_name': normalizedMerchant,
      'amount': amount,
      'timezone': timezone,
      if (time != null) 'transaction_time': time,
      if (upiRef != null) 'upi_ref': upiRef,
      if (bank != null) 'payment_app': bank,
      if (supportedCuisines.contains(cuisine)) 'cuisine': cuisine,
      if (dishNames.isNotEmpty)
        'dish_names': dishNames
            .where((dish) => dish.trim().isNotEmpty)
            .take(20)
            .map((dish) => dish.length > 120 ? dish.substring(0, 120) : dish)
            .toList(),
    };
  }
}

// Stable non-identifying key; the backend separately enforces payment identity.
String stablePaymentSourceId(String value) {
  var hash = 0x811c9dc5;
  var secondHash = 5381;
  for (final unit in value.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    secondHash = ((secondHash * 33) ^ unit) & 0xffffffff;
  }
  return 'sms-${hash.toRadixString(16).padLeft(8, '0')}${secondHash.toRadixString(16).padLeft(8, '0')}';
}

class OnDeviceSmsParser {
  static const double maxFoodAmount = 15000.0;
  static const double minFoodAmount = 10.0;
  static const Set<String> foodPlatforms = {
    'swiggy',
    'zomato',
    'zepto',
    'blinkit',
    'eatsure',
    'domino',
    'dominos',
    'kfc',
    'pizza hut',
    'mcdonald',
    'mcdonalds',
    'burger king',
    'subway',
    'starbucks',
    'chai point',
    'chaayos',
    'haldiram',
    'bikanervala',
    'theobroma',
    'hazelnut',
    'blue tokai',
    'third wave',
    'thirdwave',
    'chelvies',
    'cafe coffee day',
    'roastery',
    'dastarkhwan',
    'royal cafe',
    'sagar ratna',
    'belgian waffle',
    'coffeeangel',
    'naico',
    'terracotta',
    'magicpin',
    'costa coffee',
    'barista',
    'gossip n bite',
    'mio marito',
    'vendiman',
    'dunkin',
    'moti mahal',
    'canteen',
  };
  static const Set<String> foodKeywords = {
    'cafe',
    'café',
    'coffee',
    'roaster',
    'roastery',
    'restaurant',
    'dhaba',
    'bakery',
    'bakes',
    'patisserie',
    'sweets',
    'sweetshop',
    'sweet shop',
    'chaat',
    'bistro',
    'kitchen',
    'dining',
    'pizzeria',
    'pizza',
    'burger',
    'tea',
    'chai',
    'brewery',
    'gelato',
    'waffle',
    'dosa',
    'biryani',
    'kebab',
    'tandoor',
    'foodworks',
    'shawarma',
    'barbeque',
    'bbq',
    'eatery',
    'food',
    'rolls',
    'thali',
    'curry',
    'diner',
    'mahal',
    'rasoi',
    'bhojanalaya',
    'mithai',
    'canteen',
    'snack',
    'snacks',
    'bite',
    'bites',
    'vendiman',
    'belgian',
    'cream',
    'icecream',
    'chole',
    'kulche',
    'pav',
    'paratha',
  };
  static const Set<String> smsBodyExclusions = {
    'failed',
    'declined',
    'insufficient balance',
    'unsuccessful',
    'reversed',
    'credit card',
    'sbi card',
    'fastag',
    'toll plaza',
    'mutual fund',
    'mandate for',
    'auto debit mandate',
    'statement generated',
  };
  static const Set<String> merchantExclusions = {
    'cred',
    'cred club',
    'billdesk',
    'cheq',
    'onecard',
    'sbi card',
    'hdfc card',
    'axis card',
    'amazon',
    'amaz',
    'flipkart',
    'myntra',
    'meesho',
    'nykaa',
    'uber',
    'ola',
    'rapido',
    'irctc',
    'makemytrip',
    'goibibo',
    'indigo',
    'airtel',
    'jio',
    'vodafone',
    'vi',
    'bsnl',
    'fastag',
    'toll',
    'hpcl',
    'bpcl',
    'iocl',
    'petrol',
    'fuel',
    'dispute',
    'food merchant',
    'upi food merchant',
    'process the auto debit',
    'pack benefits',
    'gift card',
    'giftcard',
    'lic',
    'policybazaar',
    'zerodha',
    'groww',
    'investment',
    'grofers',
  };
  static const _dishNames = {
    'dosa',
    'idli',
    'vada',
    'uttapam',
    'biryani',
    'kebab',
    'pizza',
    'burger',
    'pasta',
    'noodles',
    'momos',
    'sandwich',
    'waffle',
    'pancake',
    'salad',
    'paratha',
    'thali',
    'chole',
    'kulche',
    'chai',
    'coffee',
    'tea',
    'gelato',
    'ice cream',
    'cake',
    'croissant',
    'shawarma',
    'rolls',
    'chaat',
  };

  static bool _contains(String text, String term) => RegExp(
        r'(?<![a-z0-9])' +
            RegExp.escape(term).replaceAll(' ', r'[\s_.-]+') +
            r'(?![a-z0-9])',
        caseSensitive: false,
      ).hasMatch(text);

  static String redactPii(String rawText) => rawText
      .replaceAll(RegExp(r'\*+\d{3,4}'), '[REDACTED]')
      .replaceAll(
          RegExp(r'(?:A/[cC]|Acct)(?:\s*(?:no\.?|ending|with))*[\s*Xx]*\d{3,4}',
              caseSensitive: false),
          'A/C [REDACTED]')
      .replaceAll(RegExp(r'ending\s+with\s+\d{3,4}', caseSensitive: false),
          'ending with [REDACTED]')
      .replaceAll(
          RegExp(
              r'\b(?:bal|avl\s*bal|balance|clear\s*bal)[^\w\d]*([0-9,]+(?:\.\d{1,2})?)',
              caseSensitive: false),
          'Bal: [REDACTED]')
      .replaceAll(RegExp(r'\b[6-9]\d{9}\b'), '[PHONE REDACTED]');

  static ParsedPayment? parse(String smsText,
      {String? sender, DateTime? timestamp}) {
    final lower = smsText.toLowerCase();
    final senderLower = sender?.toLowerCase() ?? '';
    if ({
      'credited',
      'credit with',
      'salary',
      'refund',
      'received',
      ...smsBodyExclusions
    }.any((term) => _contains(lower, term))) {
      return null;
    }
    final platform = foodPlatforms
        .where((p) => _contains(lower, p) || _contains(senderLower, p))
        .firstOrNull;
    final isDebit =
        RegExp(r'\b(?:debited|sent|paid|txn|spent)\b', caseSensitive: false)
                .hasMatch(smsText) ||
            RegExp(r'\bpayment\b.*\b(?:successful|completed)\b',
                    caseSensitive: false)
                .hasMatch(smsText) ||
            (platform != null &&
                RegExp(r'\b(?:order|meal|worth|placed|confirmed|delivered)\b',
                        caseSensitive: false)
                    .hasMatch(smsText));
    if (!isDebit) return null;
    final amountMatch = RegExp(r'(?:Rs\.?|INR|₹)\s*([0-9,]+(?:\.\d{1,2})?)',
                caseSensitive: false)
            .firstMatch(smsText) ??
        RegExp(r'debited\s*(?:by|for|with)?\s*([0-9,]+(?:\.\d{1,2})?)',
                caseSensitive: false)
            .firstMatch(smsText);
    final amount =
        double.tryParse(amountMatch?.group(1)?.replaceAll(',', '') ?? '');
    if (amount == null || amount < minFoodAmount || amount > maxFoodAmount) {
      return null;
    }

    String? merchant;
    for (final pattern in [
      r'(?:order\s+(?:from|at)|meal\s+(?:from|at)|confirmed\s+at)\s+(.+?)(?=\s+(?:of|worth|for|is|placed|confirmed|Rs\.?|INR)\b|[!,]|$)',
      r'\bUPI\s*[:/]\s*([^@;:]+)@[a-z0-9.-]+',
      r'\b(?:to|by|at)\s+(.+?)(?=\s+(?:via|on|ref|successful|completed|using|UPI|for)\b|\s*\(UPI|[;,]|\.(?:\s|$)|$)',
    ]) {
      for (final match
          in RegExp(pattern, caseSensitive: false).allMatches(smsText)) {
        var candidate = match.group(1)!.trim();
        if (RegExp(r'^(?:Rs\.?|INR|A/C|VPA|\d)', caseSensitive: false)
            .hasMatch(candidate)) {
          continue;
        }
        candidate = candidate.replaceAll(
            RegExp(r'@[a-z0-9.-]+', caseSensitive: false), '');
        if (candidate.length >= 2 && candidate.length <= 100) {
          merchant = candidate;
          break;
        }
      }
      if (merchant != null) break;
    }
    merchant ??= platform;
    if (merchant == null ||
        merchantExclusions.any((e) => _contains(merchant!, e))) {
      return null;
    }
    // Food evidence must identify the merchant/platform, not a substring such as "tea" in Steam.
    if (platform == null &&
        !foodKeywords.any((k) => _contains(merchant!, k)) &&
        !foodPlatforms.any((p) => _contains(merchant!, p))) {
      return null;
    }
    final cleanMerchant = merchant
        .replaceAll(RegExp(r'[^a-zA-Z0-9éÉ\s&\x27.-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleanMerchant.length < 2) return null;
    String? bank;
    for (final entry in {
      'icici': 'ICICI Bank',
      'hdfc': 'HDFC Bank',
      'sbi': 'SBI',
      'axis': 'Axis Bank',
      'kotak': 'Kotak Bank',
      'indus': 'IndusInd Bank',
      'canara': 'Canara Bank',
      'pnb': 'PNB',
      'swiggy': 'Swiggy',
      'zomato': 'Zomato',
      'zepto': 'Zepto',
      'blinkit': 'Blinkit',
      'google pay': 'Google Pay',
      'gpay': 'Google Pay',
      'phonepe': 'PhonePe',
      'paytm': 'Paytm',
    }.entries) {
      if (lower.contains(entry.key) || senderLower.contains(entry.key)) {
        bank = entry.value;
        break;
      }
    }
    final ref = RegExp(r'(?:ref(?:\s*no\.?)?|rrn)\s*[:#]?\s*(\d{6,14})',
            caseSensitive: false)
        .firstMatch(smsText)
        ?.group(1);
    final extractedTime = _extractTransactionTime(smsText);
    final cuisineMatch = RegExp(r'cuisine\s*[:=]\s*([a-z]+(?:[_ -][a-z]+)*)',
            caseSensitive: false)
        .firstMatch(smsText);
    return ParsedPayment(
      amount: amount,
      rawMerchant: merchant,
      normalizedMerchant: cleanMerchant,
      bank: bank,
      upiRef: ref,
      redactedText: redactPii(smsText),
      timestamp:
          extractedTime == null ? timestamp : DateTime.tryParse(extractedTime),
      transactionTime: extractedTime,
      cuisine: cuisineMatch
          ?.group(1)
          ?.toLowerCase()
          .replaceAll(RegExp(r'[ -]'), '_'),
      dishNames: _dishNames.where((dish) => _contains(lower, dish)).toList(),
    );
  }

  static String? _extractTransactionTime(String text) {
    final iso = RegExp(
            r'\b\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2})?(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?',
            caseSensitive: false)
        .firstMatch(text)
        ?.group(0);
    if (iso != null) {
      final normalized = iso.replaceFirst(' ', 'T');
      final zoned = RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$', caseSensitive: false)
              .hasMatch(normalized)
          ? normalized
          : '$normalized+05:30';
      return DateTime.tryParse(zoned) == null ? null : zoned;
    }
    final match = RegExp(
            r'\b(\d{1,2})[-/ ]?([A-Za-z]{3}|\d{1,2})[-/ ]?(\d{4}|\d{2})(?:\s+at|[, T])?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?\s*(Z|UTC|IST|[+-]\d{2}:?\d{2})?',
            caseSensitive: false)
        .firstMatch(text);
    // Date-only alerts do not establish a meal hour.
    if (match == null) {
      return null;
    }
    final monthText = match.group(2)!.toLowerCase();
    final month = int.tryParse(monthText) ??
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
            ].indexOf(monthText) +
            1;
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    var hour = int.parse(match.group(4)!);
    final meridiem = match.group(7)?.toUpperCase();
    if (meridiem != null) hour = hour % 12 + (meridiem == 'PM' ? 12 : 0);
    final day = int.parse(match.group(1)!);
    final minute = int.parse(match.group(5)!);
    final second = int.tryParse(match.group(6) ?? '') ?? 0;
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > DateTime.utc(year, month + 1, 0).day ||
        hour > 23 ||
        minute > 59 ||
        second > 59) {
      return null;
    }
    final sourceZone = match.group(8)?.toUpperCase();
    final zone = sourceZone == 'UTC' || sourceZone == 'Z'
        ? 'Z'
        : sourceZone == null || sourceZone == 'IST'
            ? '+05:30'
            : sourceZone;
    String pad(int n) => n.toString().padLeft(2, '0');
    return '$year-${pad(month)}-${pad(day)}T${pad(hour)}:${pad(minute)}:${pad(second)}$zone';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
