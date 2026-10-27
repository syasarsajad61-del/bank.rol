// [T05][T09][AS10] Offline preferences and short synthesized game sounds.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

class SettingsProvider extends ChangeNotifier {
  String id = const Uuid().v4(), name = 'شما';
  bool sound = true, reducedMotion = false;
  SharedPreferences? prefs;
  AudioPlayer? audio;
  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs!.getString('playerId') ?? id;
    name = prefs!.getString('name') ?? name;
    sound = prefs!.getBool('sound') ?? true;
    reducedMotion = prefs!.getBool('motion') ?? false;
    await prefs!.setString('playerId', id);
    notifyListeners();
  }

  Future<void> save({String? newName, bool? audioEnabled, bool? motion}) async {
    name = newName ?? name;
    sound = audioEnabled ?? sound;
    reducedMotion = motion ?? reducedMotion;
    await prefs?.setString('name', name);
    await prefs?.setBool('sound', sound);
    await prefs?.setBool('motion', reducedMotion);
    notifyListeners();
  }

  Future<void> play(String event) async {
    if (!sound) return;
    try {
      audio ??= AudioPlayer();
      await audio!.play(AssetSource('sounds/$event.wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    audio?.dispose();
    super.dispose();
  }
}
