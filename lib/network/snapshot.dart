// [M10][M12][A07] Versioned, integrity checked snapshot envelope.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/models/game_state.dart';

class Snapshot {
  static Map<String, dynamic> encode(
    GameState state, {
    String? viewer,
    bool migration = false,
  }) {
    final data = state.toJson(viewer: viewer, migration: migration);
    final text = jsonEncode(data);
    return {
      'version': 1,
      'revision': state.revision,
      'state': data,
      'sha256': sha256.convert(utf8.encode(text)).toString(),
    };
  }

  static GameState decode(Map<String, dynamic> snapshot) {
    if (snapshot['version'] != 1) {
      throw const FormatException('Snapshot version');
    }
    final data = Map<String, dynamic>.from(snapshot['state']);
    if (sha256.convert(utf8.encode(jsonEncode(data))).toString() !=
        snapshot['sha256']) {
      throw const FormatException('Snapshot checksum');
    }
    return GameState.fromJson(data);
  }
}
