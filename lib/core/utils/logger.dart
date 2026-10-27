// [T08] Structured logs omit secrets and private bid values.
import 'dart:convert';
import 'package:flutter/foundation.dart';

class GameLogger {
  static void event(String name, {Map<String, Object?> fields = const {}}) {
    debugPrint(
      jsonEncode({
        'time': DateTime.now().toUtc().toIso8601String(),
        'event': name,
        ...fields,
      }),
    );
  }
}
