// lib/services/sound_service.dart

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService instance = SoundService._();

  SoundService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playCalculatorTap() async {
    await _player.play(AssetSource('sounds/calculator_click.wav'), volume: 0.2);
  }
}
