// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  late final AudioPlayer _player;

  AudioService._internal() {
    _player = AudioPlayer();
  }

  Future<void> playSelect() async {
    await _playAsset('sounds/tap.mp3');
  }

  Future<void> playSuccess() async {
    await _playAsset('sounds/suc.mp3');
  }

  Future<void> playWrong() async {
    await _playAsset('sounds/clear.mp3');
  }

  Future<void> playWin() async {
    await _playAsset('sounds/levelwin.mp3');
  }

  Future<void> _playAsset(String path) async {
    try {
      await _player.stop(); // Stops current sound if any
      await _player.play(AssetSource(path));
    } catch (e) {
      // Silently ignore errors or add logging
    }
  }
}
