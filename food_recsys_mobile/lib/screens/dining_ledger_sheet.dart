import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/dining_transaction.dart';
import '../services/api_service.dart';
import 'restaurant_detail_screen.dart';

class DiningLedgerSheet extends StatefulWidget {
  final ApiService apiService;
  final String userId;
  final ScrollController? scrollController;

  const DiningLedgerSheet({
    super.key,
    required this.apiService,
    required this.userId,
    this.scrollController,
  });

  @override
  State<DiningLedgerSheet> createState() => _DiningLedgerSheetState();
}

class _DiningLedgerSheetState extends State<DiningLedgerSheet> {
  final List<DiningTransaction> _transactions = [];
  DiningLedgerPage? _page;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || (_page != null && !_page!.hasMore)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await widget.apiService.getTransactions(
        widget.userId,
        limit: 100,
        cursor: _page?.nextCursor,
      );
      final page = DiningLedgerPage.fromJson(data);
      if (!mounted) return;
      setState(() {
        final seen = _transactions.map((transaction) => transaction.id).toSet();
        _transactions.addAll(
            page.transactions.where((transaction) => seen.add(transaction.id)));
        _page = page;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _error = 'The dining ledger could not be loaded. Please retry.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dining ledger',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if (_page != null) ...[
                      Text(
                          '${_transactions.length} of ${_page!.totalCount} transactions loaded'),
                      Text(
                          '₹${_page!.totalSpent.toStringAsFixed(2)} total across all transactions',
                          style: const TextStyle(color: AppTheme.primary)),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close ledger',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _transactions.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              if (index == _transactions.length) return _buildFooter();
              return _buildTransaction(_transactions[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Column(children: [
        Text(_error!, style: const TextStyle(color: AppTheme.danger)),
        TextButton(onPressed: _loadNextPage, child: const Text('Retry ledger')),
      ]);
    }
    if (_page?.hasMore == true) {
      return OutlinedButton(
          onPressed: _loadNextPage,
          child: const Text('Load more transactions'));
    }
    return Text(
        _transactions.isEmpty
            ? 'No transactions recorded yet.'
            : 'All transactions loaded.',
        textAlign: TextAlign.center);
  }

  Widget _buildTransaction(DiningTransaction transaction) {
    final time = transaction.transactionTime;
    final date = time == null || transaction.timePrecision == 'unknown'
        ? 'Transaction time unknown'
        : transaction.timePrecision == 'date'
            ? '${DateFormat('d MMM y').format(time.toLocal())} • time unknown'
            : '${DateFormat('d MMM y, HH:mm').format(time.toLocal())} (local)';
    final knownCuisine = transaction.cuisine != null &&
        !['unknown', 'unspecified', 'general_food']
            .contains(transaction.cuisine);
    final knownMeal =
        transaction.mealType != null && transaction.mealType != 'unknown';
    final cuisine = knownCuisine
        ? AppConstants.cuisineNames[transaction.cuisine] ??
            transaction.cuisine!.replaceAll('_', ' ')
        : 'Cuisine unknown';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                  transaction.restaurantName ?? transaction.merchantName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(
                transaction.amount == null
                    ? 'Amount unknown'
                    : '₹${transaction.amount!.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        if (transaction.restaurantName != null &&
            transaction.restaurantName != transaction.merchantName)
          Text('Payment to ${transaction.merchantName}',
              style: const TextStyle(color: AppTheme.textSecondary)),
        Text('$date • ${transaction.paymentApp ?? 'Payment app unknown'}',
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(
            '$cuisine • ${knownMeal ? transaction.mealType!.replaceAll('_', ' ') : 'Meal time unknown'}',
            style: const TextStyle(fontSize: 12)),
        Text(
            'Classification: ${transaction.classificationStatus.replaceAll('_', ' ')}',
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        for (final order in transaction.orders) ...[
          Text('${order.platform} order #${order.orderId}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (order.restaurantName != null &&
              order.restaurantName != transaction.restaurantName &&
              order.restaurantName != transaction.merchantName)
            Text('Ordered from ${order.restaurantName}',
                style: const TextStyle(fontSize: 12)),
          if (order.dishNames.isNotEmpty)
            Text('Dishes: ${order.dishNames.join(', ')}',
                style: const TextStyle(fontSize: 12)),
        ],
        if (transaction.restaurantId != null)
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => RestaurantDetailScreen(
                apiService: widget.apiService,
                restaurantId: transaction.restaurantId!,
              ),
            )),
            child: const Text('View restaurant'),
          ),
      ],
    );
  }
}
