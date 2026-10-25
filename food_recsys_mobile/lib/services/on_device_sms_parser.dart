class ParsedPayment {
  final double amount;
  final String rawMerchant;
  final String normalizedMerchant;
  final String? bank;
  final String? upiRef;
  final String redactedText;
  final DateTime? timestamp;

  ParsedPayment({
    required this.amount,
    required this.rawMerchant,
    required this.normalizedMerchant,
    this.bank,
    this.upiRef,
    required this.redactedText,
    this.timestamp,
  });
}

class OnDeviceSmsParser {
  static const double maxFoodAmount = 15000.0;
  static const double minFoodAmount = 10.0;

  static const Set<String> foodPlatforms = {
    'swiggy', 'zomato', 'zepto', 'blinkit', 'eatsure', 'domino', 'kfc',
    'pizza hut', 'mcdonald', 'burger king', 'subway', 'starbucks', 'chai point',
    'chaayos', 'haldiram', 'bikanervala', 'theobroma', 'hazelnut', 'blue tokai',
    'third wave', 'thirdwave', 'chelvies', 'cafe coffee day', 'roastery', 'dastarkhwan',
    'royal cafe', 'sagar ratna', 'belgian waffle', 'coffeeangel', 'naico', 'terracotta',
    'magicpin', 'costa coffee', 'barista', 'gossip n bite', 'mio marito', 'vendiman',
    'dunkin', 'moti mahal', 'canteen'
  };

  static const Set<String> foodKeywords = {
    'cafe', 'café', 'coffee', 'roaster', 'roastery', 'restaurant', 'dhaba', 'bakery',
    'bakes', 'patisserie', 'sweets', 'sweetshop', 'sweet shop', 'chaat', 'bistro', 'kitchen',
    'dining', 'pizzeria', 'pizza', 'burger', 'tea', 'chai', 'brewery', 'gelato',
    'waffle', 'dosa', 'biryani', 'kebab', 'tandoor', 'foodworks',
    'shawarma', 'barbeque', 'bbq', 'eatery', 'food', 'rolls', 'thali', 'curry', 'diner',
    'mahal', 'rasoi', 'bhojanalaya', 'mithai', 'canteen', 'snack', 'snacks', 'bite', 'bites',
    'vendiman', 'belgian', 'cream', 'icecream', 'chole', 'kulche', 'pav', 'paratha'
  };

  static const Set<String> smsBodyExclusions = {
    'failed', 'declined', 'insufficient balance', 'unsuccessful', 'reversed',
    'credit card', 'sbi card', 'fastag', 'toll plaza', 'mutual fund', 'mandate for',
    'auto debit mandate', 'statement generated'
  };

  static const Set<String> merchantExclusions = {
    'cred', 'cred club', 'billdesk', 'cheq', 'onecard', 'sbi card', 'hdfc card', 'axis card',
    'amazon', 'amaz', 'flipkart', 'myntra', 'meesho', 'nykaa', 'uber', 'ola', 'rapido',
    'irctc', 'makemytrip', 'goibibo', 'indigo', 'airtel', 'jio', 'vodafone', 'vi', 'bsnl',
    'fastag', 'toll', 'hpcl', 'bpcl', 'iocl', 'petrol', 'fuel', 'dispute', 'insufficient balance',
    'food merchant', 'upi food merchant', 'process the auto debit', 'pack benefits', 'gift card',
    'giftcard', 'lic', 'policybazaar', 'zerodha', 'groww', 'investment', 'grofers'
  };

  /// Redact PII (account digits, balances, phone numbers) before sending or storing
  static String redactPii(String rawText) {
    var sanitized = rawText;
    sanitized = sanitized.replaceAll(RegExp(r'\*+\d{3,4}'), '[REDACTED]');
    sanitized = sanitized.replaceAll(RegExp(r'(?:A/[cC]|Acct)(?:\s*(?:no\.?|ending|with))*[\s*Xx]*\d{3,4}', caseSensitive: false), 'A/C [REDACTED]');
    sanitized = sanitized.replaceAll(RegExp(r'ending\s+with\s+\d{3,4}', caseSensitive: false), 'ending with [REDACTED]');
    sanitized = sanitized.replaceAll(RegExp(r'\b(?:bal|avl\s*bal|balance|clear\s*bal)[^\w\d]*([0-9,]+(?:\.\d{1,2})?)', caseSensitive: false), 'Bal: [REDACTED]');
    sanitized = sanitized.replaceAll(RegExp(r'\b[6-9]\d{9}\b'), '[PHONE REDACTED]');
    return sanitized;
  }

  /// Parse an SMS alert into a structured payment object strictly for food/dining expenses
  static ParsedPayment? parse(String smsText, {String? sender, DateTime? timestamp}) {
    final lower = smsText.toLowerCase();
    final senderLower = sender?.toLowerCase() ?? '';

    // Reject credits, salary, or non-debit alerts
    if (lower.contains('credited') ||
        lower.contains('credit with') ||
        lower.contains('salary') ||
        lower.contains('refund') ||
        lower.contains('received')) {
      return null;
    }

    // Reject failure/banking notification patterns
    for (final ex in smsBodyExclusions) {
      if (RegExp(r'\b' + RegExp.escape(ex) + r'\b').hasMatch(lower)) {
        return null;
      }
    }

    final isFoodApp = foodPlatforms.any((p) => lower.contains(p) || senderLower.contains(p));

    final isDebit = lower.contains('debited') ||
        lower.contains('sent') ||
        lower.contains('paid') ||
        lower.contains('txn') ||
        lower.contains('spent') ||
        (isFoodApp && (lower.contains('order') || lower.contains('meal') || lower.contains('worth') || lower.contains('placed') || lower.contains('confirmed') || lower.contains('delivered')));

    if (!isDebit) return null;

    // 1. Extract Amount
    double? detectedAmount;
    final amountMatch = RegExp(r'(?:Rs\.?|INR|\u20B9)\s*([0-9,]+(?:\.\d{1,2})?)', caseSensitive: false).firstMatch(smsText);
    if (amountMatch != null && amountMatch.group(1) != null) {
      detectedAmount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    }

    if (detectedAmount == null) {
      final debMatch = RegExp(r'debited\s*(?:by|for|with)?\s*(?:Rs\.?|INR|\u20B9)?\s*([0-9,]+(?:\.\d{1,2})?)', caseSensitive: false).firstMatch(smsText);
      if (debMatch != null && debMatch.group(1) != null) {
        detectedAmount = double.tryParse(debMatch.group(1)!.replaceAll(',', ''));
      }
    }

    // Strict Amount Bounds Check: Must be between Rs 10 and Rs 15,000 (rejects 1.4L / 1.5L bank transfers)
    if (detectedAmount == null || detectedAmount < minFoodAmount || detectedAmount > maxFoodAmount) {
      return null;
    }

    // 2. Extract Merchant
    String? extractedMerchant;

    // 2A. Check food app specific restaurant syntax e.g. "order from <Restaurant>", "meal from <Restaurant>"
    final foodRestMatch = RegExp(r'(?:order\s+(?:from|at)|meal\s+(?:from|at)|confirmed\s+at)\s+([A-Za-z0-9\s&_.-]{2,40}?)(?:\s+(?:of|worth|for|is|placed|confirmed|\(Rs|\(INR|Rs\.?|INR|\u20B9|\!|\.|\,)|$)', caseSensitive: false).firstMatch(smsText);
    if (foodRestMatch != null) {
      final cand = foodRestMatch.group(1)!.trim();
      final candLower = cand.toLowerCase();
      if (!candLower.startsWith('rs') && !candLower.startsWith('inr') && cand.length > 2) {
        extractedMerchant = cand;
      }
    }

    // 2B. Check VPA: UPI:MERCHANT@handle
    if (extractedMerchant == null) {
      final vpaMatch = RegExp(r'\bUPI:([A-Za-z0-9\s_.-]+@[A-Za-z0-9.-]+)\b', caseSensitive: false).firstMatch(smsText);
      if (vpaMatch != null) {
        final fullVpa = vpaMatch.group(1)!.trim();
        extractedMerchant = fullVpa.split('@')[0].trim();
      }
    }

    // 2C. Check "to <MERCHANT>" or "by <MERCHANT>" or "at <MERCHANT>" stopping at "via"
    if (extractedMerchant == null) {
      final iter = RegExp(r'\b(?:to|by|paid to|sent to|\bat)\s+([A-Za-z0-9\s&_.-]{2,40}?)\s*(?:\(UPI|\bvia\b|\bon\b|\bref\b|\.|\,|$)', caseSensitive: false).allMatches(smsText);
      for (final m in iter) {
        final cand = m.group(1)!.trim();
        final candLower = cand.toLowerCase();
        if (!candLower.startsWith('rs') &&
            !candLower.startsWith('inr') &&
            !candLower.startsWith('a/c') &&
            !candLower.startsWith('vpa') &&
            cand.length > 2) {
          extractedMerchant = cand;
          break;
        }
      }
    }

    // Fallback for food delivery apps when no specific restaurant name found in body
    if (extractedMerchant == null) {
      if (lower.contains('swiggy') || senderLower.contains('swiggy')) {
        extractedMerchant = 'Swiggy';
      } else if (lower.contains('zomato') || senderLower.contains('zomato')) {
        extractedMerchant = 'Zomato';
      } else if (lower.contains('zepto') || senderLower.contains('zepto')) {
        extractedMerchant = 'Zepto';
      } else if (lower.contains('blinkit') || senderLower.contains('blinkit')) {
        extractedMerchant = 'Blinkit';
      } else if (lower.contains('eatsure')) {
        extractedMerchant = 'EatSure';
      } else if (lower.contains('domino')) {
        extractedMerchant = "Domino's";
      }
    }

    if (extractedMerchant == null) {
      return null;
    }

    final merchantLower = extractedMerchant.toLowerCase().trim();

    // Reject non-food merchants (CRED, Amazon, Fastag, etc.)
    for (final ex in merchantExclusions) {
      if (RegExp(r'\b' + RegExp.escape(ex) + r'\b').hasMatch(merchantLower) || merchantLower == ex) {
        return null;
      }
    }

    // Positive food verification
    final combined = '$lower $merchantLower';
    final hasPlatform = foodPlatforms.any((p) => combined.contains(p));
    final hasKeyword = foodKeywords.any((k) => combined.contains(k));

    if (!hasPlatform && !hasKeyword) {
      return null;
    }

    // 3. Detect Bank or Platform
    String? bank;
    if (lower.contains('icici') || senderLower.contains('icici')) {
      bank = 'ICICI Bank';
    } else if (lower.contains('hdfc') || senderLower.contains('hdfc')) {
      bank = 'HDFC Bank';
    } else if (lower.contains('sbi') || senderLower.contains('sbi')) {
      bank = 'SBI';
    } else if (lower.contains('axis') || senderLower.contains('axis')) {
      bank = 'Axis Bank';
    } else if (lower.contains('kotak') || senderLower.contains('kotak')) {
      bank = 'Kotak Bank';
    } else if (lower.contains('indus') || senderLower.contains('indus')) {
      bank = 'IndusInd Bank';
    } else if (lower.contains('canara') || senderLower.contains('canara')) {
      bank = 'Canara Bank';
    } else if (lower.contains('pnb') || senderLower.contains('pnb')) {
      bank = 'PNB';
    } else if (lower.contains('swiggy') || senderLower.contains('swiggy')) {
      bank = 'Swiggy';
    } else if (lower.contains('zomato') || senderLower.contains('zomato')) {
      bank = 'Zomato';
    } else if (lower.contains('zepto') || senderLower.contains('zepto')) {
      bank = 'Zepto';
    } else if (lower.contains('gpay') || lower.contains('google pay')) {
      bank = 'Google Pay';
    } else if (lower.contains('phonepe')) {
      bank = 'PhonePe';
    } else if (lower.contains('paytm')) {
      bank = 'Paytm';
    }

    // 4. Extract UPI reference if present
    final refMatch = RegExp(r'(?:ref(?:\s*no\.?)?|rrn)\s*[:#]?\s*(\d{6,14})', caseSensitive: false).firstMatch(smsText);
    final upiRef = refMatch?.group(1);

    final cleanMerchant = extractedMerchant
        .replaceAll(RegExp(r'@\w+'), '')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return ParsedPayment(
      amount: detectedAmount,
      rawMerchant: extractedMerchant,
      normalizedMerchant: cleanMerchant.isEmpty ? extractedMerchant : cleanMerchant,
      bank: bank,
      upiRef: upiRef,
      redactedText: redactPii(smsText),
      timestamp: timestamp,
    );
  }
}
