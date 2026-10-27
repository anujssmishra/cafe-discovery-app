import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/food_order.dart';
import '../providers/recs_provider.dart';
import '../providers/taste_provider.dart';
import '../services/api_service.dart';
import '../services/food_order_parser.dart';
import '../services/order_file_picker.dart';
import '../services/sms_listener_service.dart';
import '../widgets/dpdp_consent_dialog.dart';

class FoodOrderImportScreen extends StatefulWidget {
  final Future<OrderImportFile?> Function()? pickFile;

  const FoodOrderImportScreen({super.key, this.pickFile});

  @override
  State<FoodOrderImportScreen> createState() => _FoodOrderImportScreenState();
}

class _OrderReview {
  FoodOrder order;
  bool unknownsReviewed = false;
  bool selected = false;
  bool separateConfirmed = false;
  String? linkedTransactionId;
  Map<String, dynamic>? preview;
  String? importedStatus;

  _OrderReview(this.order);

  bool get needsUnknownReview =>
      !unknownsReviewed && (order.orderTime == null || order.dishNames.isEmpty);
  bool get eligible => order.isImportable && !needsUnknownReview;
  bool get canSelect =>
      eligible &&
      preview != null &&
      (preview!['status'] == 'new' ||
          preview!['status'] == 'duplicate' ||
          (preview!['status'] == 'review' &&
              (separateConfirmed || linkedTransactionId != null)));

  void resetPreview() {
    preview = null;
    selected = false;
    separateConfirmed = false;
    linkedTransactionId = null;
    importedStatus = null;
  }
}

class _FoodOrderImportScreenState extends State<FoodOrderImportScreen> {
  final _input = TextEditingController();
  final List<_OrderReview> _rows = [];
  ApiService? _api;
  TasteProvider? _taste;
  bool _lastConsent = false;
  String _platform = 'Swiggy';
  String? _fileName;
  String? _message;
  List<String> _parseMessages = [];
  bool _busy = false;
  bool _previewReady = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = context.read<ApiService>();
    if (!identical(_api, api)) {
      _api?.removeListener(_serverChanged);
      _api = api..addListener(_serverChanged);
    }
    final taste = context.read<TasteProvider>();
    if (!identical(_taste, taste)) {
      _taste?.removeListener(_consentChanged);
      _taste = taste..addListener(_consentChanged);
      _lastConsent = taste.hasDpdpConsent;
    }
  }

  @override
  void dispose() {
    _api?.removeListener(_serverChanged);
    _taste?.removeListener(_consentChanged);
    _input.dispose();
    super.dispose();
  }

  void _invalidatePreview() {
    _generation++;
    _previewReady = false;
    for (final row in _rows) {
      row.resetPreview();
    }
  }

  void _serverChanged() {
    if (!mounted) return;
    setState(() {
      _invalidatePreview();
      _busy = false;
      _message = 'Server changed. Review consent and check duplicates again.';
    });
  }

  void _consentChanged() {
    final consent = _taste!.hasDpdpConsent;
    if (_lastConsent && !consent && mounted) {
      setState(() {
        _invalidatePreview();
        _busy = false;
        _message = 'Consent was withdrawn. Nothing further will be submitted.';
      });
    }
    _lastConsent = consent;
  }

  void _sourceChanged() {
    setState(() {
      _invalidatePreview();
      _rows.clear();
      _parseMessages = [];
      _message = null;
      _fileName = null;
    });
  }

  Future<void> _pickFile() async {
    try {
      final file = await (widget.pickFile ?? const OrderFilePicker().pick)();
      if (!mounted || file == null) return;
      _input.text = file.text;
      _parseInput(fileName: file.name);
    } catch (_) {
      if (mounted)
        setState(() => _message =
            'The file could not be read. Choose a UTF-8 CSV, JSON or text file up to 5 MB.');
    }
  }

  void _parseInput({String? fileName}) {
    final text = _input.text;
    if (utf8.encode(text).length > OrderFilePicker.maxBytes) {
      setState(
          () => _message = 'Use a file or pasted text of 5 MB or smaller.');
      return;
    }
    try {
      final result = FoodOrderParser.parse(text, platformHint: _platform);
      setState(() {
        _invalidatePreview();
        _rows
          ..clear()
          ..addAll(result.orders.map(_OrderReview.new));
        _fileName = fileName;
        _parseMessages = result.issues
            .map((issue) => 'Row ${issue.rowNumber}: ${issue.message}')
            .toSet()
            .toList();
        _message =
            '${_rows.length} rows parsed locally. Review fields before checking duplicates.';
      });
    } catch (_) {
      setState(() {
        _invalidatePreview();
        _rows.clear();
        _message =
            'Could not read this format. Use the app template or paste receipt text, then review the extracted fields.';
      });
    }
  }

  Future<bool> _ensureConsent() async {
    if (_taste!.hasDpdpConsent) return true;
    final endpoint = _api!.baseUrl;
    final granted = await DpdpConsentDialog.show(context);
    if (!mounted || granted != true || endpoint != _api!.baseUrl) return false;
    return _taste!.grantConsent();
  }

  bool _current(int generation, String endpoint) =>
      mounted && generation == _generation && endpoint == _api!.baseUrl;

  Future<void> _checkDuplicates() async {
    final endpoint = _api!.baseUrl;
    if (!await _ensureConsent() || !mounted || endpoint != _api!.baseUrl)
      return;
    final eligible = _rows.where((row) => row.eligible).toList();
    if (eligible.isEmpty) return;
    setState(() {
      _invalidatePreview();
      _busy = true;
      _message = null;
    });
    final generation = _generation;
    try {
      final result = await _api!.previewFoodOrders(_taste!.activeUserId,
          eligible.map((row) => row.order.toOrderPayload()).toList());
      if (!_current(generation, endpoint)) return;
      final previews =
          (result['orders'] as List<dynamic>? ?? []).whereType<Map>().toList();
      final bySource = <String?, List<Map>>{};
      for (final preview in previews) {
        bySource
            .putIfAbsent(preview['source_id']?.toString(), () => [])
            .add(preview);
      }
      setState(() {
        for (final row in eligible) {
          final matching = bySource[row.order.sourceId];
          if (matching == null || matching.isEmpty) continue;
          row.preview = Map<String, dynamic>.from(matching.removeAt(0));
          row.selected = row.canSelect;
        }
        _previewReady = eligible.every((row) => row.preview != null);
        _message = _previewReady
            ? 'Duplicate check complete. Orders needing a decision stay unselected.'
            : 'Some rows were not checked. Retry the duplicate check before importing.';
      });
    } catch (_) {
      if (_current(generation, endpoint))
        setState(() => _message =
            'Duplicate check unavailable. Nothing was imported. Reconnect and check again.');
    } finally {
      if (_current(generation, endpoint)) setState(() => _busy = false);
    }
  }

  Future<void> _importSelected() async {
    if (!_previewReady || _busy || !_taste!.hasDpdpConsent) return;
    final selected =
        _rows.where((row) => row.selected && row.canSelect).toList();
    if (selected.isEmpty) return;
    final endpoint = _api!.baseUrl;
    final generation = _generation;
    final service = context.read<SmsListenerService>();
    final recs = context.read<RecsProvider>();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await service.importFoodOrders(selected
          .map((row) => row.order
              .toOrderPayload(linkedTransactionId: row.linkedTransactionId))
          .toList());
      if (!_current(generation, endpoint)) return;
      int count(String key) => (result[key] as num?)?.toInt() ?? 0;
      final inserted = count('ingested_count');
      final duplicates = count('duplicate_count');
      if (inserted + duplicates > 0) {
        await _taste!.fetchProfile();
        if (!_current(generation, endpoint)) return;
        await recs.fetchRecommendations(_taste!.activeUserId);
      }
      if (!_current(generation, endpoint)) return;
      setState(() {
        _previewReady = false;
        _input.clear();
        final outcomes =
            (result['outcomes'] as List<dynamic>? ?? []).whereType<Map>();
        final bySource = <String?, List<Map>>{};
        for (final outcome in outcomes) {
          bySource
              .putIfAbsent(outcome['source_id']?.toString(), () => [])
              .add(outcome);
        }
        for (final row in selected) {
          row.selected = false;
          final matching = bySource[row.order.sourceId];
          row.importedStatus = matching == null || matching.isEmpty
              ? null
              : matching.removeAt(0)['status']?.toString();
        }
        _message =
            'Queue result: $inserted inserted • $duplicates duplicates • '
            '${count('rejected_count')} rejected • ${count('unresolved_count')} unresolved • '
            '${count('pending_count')} pending. '
            '${result['error'] == null ? 'Check duplicates again before another submission.' : 'Some orders remain pending. Use Retry in Auto-Ingest.'}';
      });
    } catch (_) {
      if (_current(generation, endpoint))
        setState(() {
          _previewReady = false;
          _message =
              'Import could not be confirmed. Check pending imports in Auto-Ingest and check duplicates before retrying.';
        });
    } finally {
      if (_current(generation, endpoint)) setState(() => _busy = false);
    }
  }

  Future<void> _edit(_OrderReview row) async {
    final result = await showModalBottomSheet<FoodOrder>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrderEditor(order: row.order),
    );
    if (!mounted || result == null) return;
    setState(() {
      row.order = result;
      row.unknownsReviewed = false;
      _invalidatePreview();
    });
  }

  String get _csvTemplate =>
      'order_id,restaurant_name,amount,order_time,dish_names,status,currency\n'
      'EXAMPLE-001,Example Kitchen,450.00,2026-10-26T19:30:00+05:30,Paneer bowl|Garlic naan,delivered,INR';
  String get _jsonTemplate => const JsonEncoder.withIndent('  ').convert([
        {
          'platform': _platform,
          'order_id': 'EXAMPLE-001',
          'restaurant_name': 'Example Kitchen',
          'amount': 450.0,
          'order_time': '2026-10-26T19:30:00+05:30',
          'dish_names': ['Paneer bowl', 'Garlic naan'],
          'status': 'delivered',
          'currency': 'INR',
        }
      ]);

  Future<void> _showTemplate() async {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('App-defined import template'),
              content: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text(
                        'These example formats belong to this app. They are not claimed to be Swiggy or Zomato export formats. Replace every fictional example with your own order details.'),
                    const SizedBox(height: 12),
                    const Text('CSV'),
                    SelectableText(_csvTemplate),
                    TextButton(
                        onPressed: () => Clipboard.setData(
                            ClipboardData(text: _csvTemplate)),
                        child: const Text('Copy CSV example')),
                    const SizedBox(height: 12),
                    const Text('JSON'),
                    SelectableText(_jsonTemplate),
                    TextButton(
                        onPressed: () => Clipboard.setData(
                            ClipboardData(text: _jsonTemplate)),
                        child: const Text('Copy JSON example')),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close template'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _rows.where((row) => row.selected && row.canSelect).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Import food orders')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length + 1,
        itemBuilder: (context, index) =>
            index == 0 ? _header() : _rowCard(_rows[index - 1]),
      ),
      bottomNavigationBar: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed:
              _previewReady && selected > 0 && !_busy ? _importSelected : null,
          icon: const Icon(Icons.file_download_outlined),
          label: Text(_busy ? 'Working…' : 'Import selected ($selected)'),
        ),
      )),
    );
  }

  Widget _header() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
            'Choose an app, then select a CSV, JSON or text file, or paste receipt text. Review the extracted fields before importing. Account synchronization is not available.'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _platform,
          decoration: const InputDecoration(labelText: 'Order app'),
          items: ['Swiggy', 'Zomato']
              .map((app) => DropdownMenuItem(value: app, child: Text(app)))
              .toList(),
          onChanged: _busy
              ? null
              : (value) {
                  if (value != null) {
                    _platform = value;
                    _sourceChanged();
                  }
                },
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Choose order file')),
          TextButton(
              onPressed: _showTemplate,
              child: const Text('Template / example')),
        ]),
        if (_fileName != null) Text('Selected file: $_fileName'),
        const SizedBox(height: 12),
        TextField(
            controller: _input,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
                labelText: 'Paste CSV, JSON or receipt text',
                alignLabelWithHint: true,
                border: OutlineInputBorder()),
            onChanged: (_) => _sourceChanged()),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: _busy ? null : _parseInput,
            child: const Text('Parse and review locally')),
        const Text(
            'Only reviewed order fields are sent. Raw receipt text, addresses and account details are not uploaded or saved in the import queue.',
            style: TextStyle(fontSize: 12)),
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
              '${_rows.length} rows • ${_rows.where((row) => row.eligible).length} ready for duplicate check • ${_rows.where((row) => row.order.isExcluded).length} excluded'),
          OutlinedButton(
              onPressed: !_busy && _rows.any((row) => row.eligible)
                  ? _checkDuplicates
                  : null,
              child: const Text('Check duplicates')),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_message!, key: const Key('order-import-message'))),
        if (_parseMessages.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Parsing notes (${_parseMessages.length})'),
            children: _parseMessages
                .take(20)
                .map((message) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(message)))
                .toList(),
          ),
      ]);

  Widget _rowCard(_OrderReview row) {
    final order = row.order;
    final previewStatus = row.preview?['status']?.toString();
    final status = row.importedStatus ??
        (order.isExcluded
            ? 'Excluded'
            : !order.isImportable || row.needsUnknownReview
                ? 'Needs field review'
                : previewStatus ?? 'Not checked');
    final candidates = (row.preview?['candidates'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .where((candidate) {
      final amount = candidate['amount'];
      return amount is num &&
          order.amount != null &&
          (amount.toDouble() - order.amount!).abs() < 0.000001;
    });
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                  value: row.selected,
                  onChanged: !_busy && _previewReady && row.canSelect
                      ? (value) => setState(() => row.selected = value ?? false)
                      : null),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        'Row ${order.rowNumber}: ${order.restaurantName ?? 'Restaurant missing'}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '${order.platform ?? 'App missing'} • Order ${order.orderId ?? 'ID missing'}'),
                    Text(order.amount == null
                        ? 'Amount missing'
                        : '${order.currency ?? 'Currency missing'} ${order.amount!.toStringAsFixed(2)}'),
                  ])),
              IconButton(
                  tooltip: 'Edit row ${order.rowNumber}',
                  onPressed: _busy ? null : () => _edit(row),
                  icon: const Icon(Icons.edit_outlined)),
            ]),
            Text('Status: $status'),
            Text('Order status: ${order.status ?? 'missing'}'),
            Text(order.orderTime == null
                ? 'Date/time unknown'
                : '${order.orderTime} (${order.timePrecision})'),
            Text(
                'Dishes: ${order.dishNames.isEmpty ? 'unknown' : order.dishNames.join(' • ')}'),
            ...order.issues.map((issue) =>
                Text(issue.message, style: const TextStyle(fontSize: 12))),
            if (order.isImportable &&
                (order.orderTime == null || order.dishNames.isEmpty))
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: row.unknownsReviewed,
                  title: const Text(
                      'I reviewed the missing date/dishes; keep them unknown.',
                      style: TextStyle(fontSize: 13)),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                            row.unknownsReviewed = value ?? false;
                            _invalidatePreview();
                          })),
            if (row.preview?['reason'] != null)
              Text(row.preview!['reason'].toString()),
            if (previewStatus == 'duplicate')
              const Text(
                  'Already recorded. Selected duplicates can enrich existing order details without adding another payment.'),
            if (previewStatus == 'review') ...[
              const Text(
                  'A possible match needs your decision. Matching an amount alone does not prove it is the same payment.'),
              OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            row.separateConfirmed = true;
                            row.linkedTransactionId = null;
                            row.selected = true;
                          }),
                  child: Text(row.separateConfirmed
                      ? 'Selected: import as separate order'
                      : 'Import as separate order')),
              ...candidates.map((candidate) {
                final id = candidate['transaction_id']?.toString();
                return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OutlinedButton(
                      onPressed: _busy || id == null
                          ? null
                          : () => setState(() {
                                row.linkedTransactionId = id;
                                row.separateConfirmed = false;
                                row.selected = true;
                              }),
                      child: Text(
                          '${row.linkedTransactionId == id ? 'Selected: ' : ''}Link existing payment: ${candidate['merchant_name'] ?? 'Merchant unknown'} • ₹${candidate['amount']} • ${_candidateTime(candidate)}${candidate['payment_app'] == null ? '' : ' • ${candidate['payment_app']}'}'),
                    ));
              }),
            ],
          ]),
        )));
  }

  String _candidateTime(Map candidate) {
    final time =
        DateTime.tryParse(candidate['transaction_time']?.toString() ?? '');
    if (time == null || candidate['time_precision'] == 'unknown')
      return 'Time unknown';
    return candidate['time_precision'] == 'date'
        ? '${DateFormat('d MMM y').format(time.toLocal())} (date only)'
        : '${DateFormat('d MMM y, HH:mm').format(time.toLocal())} (local)';
  }
}

class _OrderEditor extends StatefulWidget {
  final FoodOrder order;
  const _OrderEditor({required this.order});
  @override
  State<_OrderEditor> createState() => _OrderEditorState();
}

class _OrderEditorState extends State<_OrderEditor> {
  final Map<String, TextEditingController> _fields = {};
  String? _platform;
  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _platform =
        ['Swiggy', 'Zomato'].contains(order.platform) ? order.platform : null;
    final values = {
      'Order ID': order.orderId,
      'Restaurant': order.restaurantName,
      'Amount paid': order.amount?.toString(),
      'Order date/time': order.orderTime,
      'Dishes (separate with |)': order.dishNames.join('|'),
      'Order status': order.status,
      'Currency': order.currency,
      'Timezone': order.timezone,
      'Cuisine (optional)': order.cuisine,
      'UPI reference (optional)': order.upiRef
    };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value ?? '');
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Review row ${widget.order.rowNumber}',
                  style: Theme.of(context).textTheme.titleLarge),
              const Text(
                  'Use completed, delivered or paid only for completed orders. Cancelled/refunded orders stay excluded. A blank date or dishes remain unknown.'),
              DropdownButtonFormField<String>(
                  initialValue: _platform,
                  decoration: const InputDecoration(
                      labelText: 'Order app for this row'),
                  items: ['Swiggy', 'Zomato']
                      .map((app) =>
                          DropdownMenuItem(value: app, child: Text(app)))
                      .toList(),
                  onChanged: (value) => setState(() => _platform = value)),
              ..._fields.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: entry.key),
                      keyboardType: entry.key == 'Amount paid'
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text))),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        String text(String key) => _fields[key]!.text.trim();
                        Navigator.pop(
                            context,
                            widget.order.copyWith(
                              platform: _platform,
                              orderId: text('Order ID'),
                              restaurantName: text('Restaurant'),
                              amount: double.tryParse(text('Amount paid')),
                              orderTime: text('Order date/time'),
                              dishNames: text('Dishes (separate with |)')
                                  .split('|')
                                  .map((dish) => dish.trim())
                                  .where((dish) => dish.isNotEmpty)
                                  .toList(),
                              status: text('Order status'),
                              currency: text('Currency'),
                              timezone: text('Timezone'),
                              cuisine: text('Cuisine (optional)'),
                              upiRef: text('UPI reference (optional)'),
                            ));
                      },
                      child: const Text('Save reviewed fields'))),
            ])),
      ));
}
