import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorageService {
  static const String _soundEffectsKey = 'sound_effects';
  static const String _hapticFeedbackKey = 'haptic_feedback';

  Future<bool> getSoundEffects() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_soundEffectsKey) ?? true;
  }

  Future<void> saveSoundEffects(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_soundEffectsKey, value);
  }

  Future<bool> getHapticFeedback() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_hapticFeedbackKey) ?? true;
  }

  Future<void> saveHapticFeedback(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_hapticFeedbackKey, value);
  }
}
