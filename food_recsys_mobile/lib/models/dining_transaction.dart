class DiningTransaction {
  final String id;
  final String merchantName;
  final double? amount;
  final String? paymentApp;
  final DateTime? transactionTime;
  final String timePrecision;
  final String? cuisine;
  final String? mealType;
  final String classificationStatus;
  final String? restaurantId;
  final String? restaurantName;

  const DiningTransaction({
    required this.id,
    required this.merchantName,
    this.amount,
    this.paymentApp,
    this.transactionTime,
    this.timePrecision = 'exact',
    this.cuisine,
    this.mealType,
    required this.classificationStatus,
    this.restaurantId,
    this.restaurantName,
  });

  factory DiningTransaction.fromJson(Map<String, dynamic> json) {
    return DiningTransaction(
      id: json['id']?.toString() ?? '',
      merchantName: json['merchant_name']?.toString() ?? 'Unknown merchant',
      amount: (json['amount'] as num?)?.toDouble(),
      paymentApp: json['payment_app'] as String?,
      transactionTime:
          DateTime.tryParse(json['transaction_time']?.toString() ?? ''),
      timePrecision: json['time_precision']?.toString() ?? 'exact',
      cuisine: json['cuisine'] as String?,
      mealType: json['meal_type'] as String?,
      classificationStatus:
          json['classification_status']?.toString() ?? 'unknown',
      restaurantId: json['restaurant_id'] as String?,
      restaurantName: json['restaurant_name'] as String?,
    );
  }
}

class DiningLedgerPage {
  final List<DiningTransaction> transactions;
  final int totalCount;
  final double totalSpent;
  final bool hasMore;
  final String? nextCursor;

  const DiningLedgerPage({
    required this.transactions,
    required this.totalCount,
    required this.totalSpent,
    required this.hasMore,
    this.nextCursor,
  });

  factory DiningLedgerPage.fromJson(Map<String, dynamic> json) {
    return DiningLedgerPage(
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((row) => DiningTransaction.fromJson(row as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      hasMore: json['has_more'] == true,
      nextCursor: json['next_cursor'] as String?,
    );
  }
}
