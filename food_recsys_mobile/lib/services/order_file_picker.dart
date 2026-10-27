import 'dart:convert';
import 'package:flutter/services.dart';

class OrderImportFile {
  final String name;
  final String text;
  const OrderImportFile({required this.name, required this.text});
}

/// Uses Android's document picker: only the file selected by the user is read.
class OrderFilePicker {
  static const maxBytes = 5 * 1024 * 1024;
  final MethodChannel channel;
  const OrderFilePicker(
      {this.channel = const MethodChannel('food_recsys/order_files')});

  Future<OrderImportFile?> pick() async {
    final result =
        await channel.invokeMapMethod<String, dynamic>('pickOrderFile');
    if (result == null) return null;
    final name = result['name'];
    final text = result['text'];
    if (name is! String || text is! String || text.contains('\u0000')) {
      throw const FormatException('The file could not be read as text.');
    }
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('Files must be 5 MB or smaller.');
    }
    return OrderImportFile(name: name, text: text);
  }
}
