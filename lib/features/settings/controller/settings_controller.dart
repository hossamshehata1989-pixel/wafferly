import 'package:flutter/material.dart';

import '../models/settings_state.dart';
import '../services/settings_storage_service.dart';
import 'package:provider/provider.dart';

class SettingsController extends ChangeNotifier {
  SettingsState _state = const SettingsState();

  final SettingsStorageService _storage = SettingsStorageService();

  SettingsState get state => _state;

  Future<void> loadSettings() async {
    final soundEffects = await _storage.getSoundEffects();

    final hapticFeedback = await _storage.getHapticFeedback();

    _state = _state.copyWith(
      soundEffects: soundEffects,
      hapticFeedback: hapticFeedback,
    );

    notifyListeners();
  }

  Future<void> toggleSoundEffects(bool value) async {
    _state = _state.copyWith(soundEffects: value);

    notifyListeners();

    await _storage.saveSoundEffects(value);
  }

  Future<void> toggleHapticFeedback(bool value) async {
    _state = _state.copyWith(hapticFeedback: value);

    notifyListeners();

    await _storage.saveHapticFeedback(value);
  }

  void toggleFingerprint(bool value) {
    _state = _state.copyWith(fingerprintEnabled: value);

    notifyListeners();
  }
}
