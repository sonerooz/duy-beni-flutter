import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Ses ve titreşim. Sesler saf sinüs tonlarıdır (tool/make_sounds.py ile üretilir).
class Sfx {
  /// Testlerde kapatılır.
  static bool enabled = true;

  static const _names = ['tik', 'son', 'bitti', 'kalp1', 'kalp2', 'kalp3', 'kalp4', 'kalp5'];
  static final Map<String, AudioPool> _pools = {};

  static Future<void> init() async {
    if (!enabled) return;
    for (final n in _names) {
      try {
        _pools[n] = await AudioPool.createFromAsset(path: 'audio/$n.wav', maxPlayers: 2);
      } catch (_) {}
    }
  }

  static void play(String name) {
    if (!enabled) return;
    _pools[name]?.start().ignore();
  }

  /// Son saniyeler için: kalan saniyeye göre giderek tizleşen çift bip.
  static void heartbeat(int remaining) => play('kalp${remaining.clamp(1, 5)}');

  static void vibrate(int ms) {
    if (!enabled) return;
    Vibration.vibrate(duration: ms).ignore();
  }
}
