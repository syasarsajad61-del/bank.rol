// [A02][A03][A04][M07] AES-GCM plus PBKDF2, replay and clock checks.
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

class SecureProtocol {
  final SecretKey key;
  final String session;
  final Set<String> seen = {};
  final List<String> order = [];
  final AesGcm cipher = AesGcm.with256bits();
  SecureProtocol(this.key, this.session);
  static Future<SecureProtocol> derive(
    String pin,
    String session,
    String id,
  ) async {
    final key =
        await Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 60000,
          bits: 256,
        ).deriveKey(
          secretKey: SecretKey(utf8.encode(pin)),
          nonce: utf8.encode('$session:$id'),
        );
    return SecureProtocol(key, session);
  }

  Future<String> encode(Map<String, dynamic> payload) async {
    final nonce = cipher.newNonce();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v4();
    final aad = utf8.encode('$session:$now:$id');
    final box = await cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    return jsonEncode({
      'session': session,
      'ts': now,
      'id': id,
      'nonce': base64Encode(nonce),
      'data': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<Map<String, dynamic>> decode(String raw) async {
    if (raw.length > 2000000) throw const FormatException('Message too large');
    final e = jsonDecode(raw) as Map<String, dynamic>;
    final id = e['id'] as String, ts = e['ts'] as int;
    final nonceKey = 'nonce:${e['nonce']}';
    if (e['session'] != session ||
        (DateTime.now().millisecondsSinceEpoch - ts).abs() > 60000 ||
        seen.contains(id) ||
        seen.contains(nonceKey)) {
      throw const FormatException('Expired or replayed message');
    }
    final bytes = await cipher.decrypt(
      SecretBox(
        base64Decode(e['data']),
        nonce: base64Decode(e['nonce']),
        mac: Mac(base64Decode(e['mac'])),
      ),
      secretKey: key,
      aad: utf8.encode('$session:$ts:$id'),
    );
    seen.add(id);
    seen.add(nonceKey);
    order.add(id);
    order.add(nonceKey);
    if (order.length > 4096) seen.remove(order.removeAt(0));
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)));
  }

  static String pin() {
    final r = Random.secure();
    return List.generate(8, (_) => r.nextInt(10)).join();
  }
}
