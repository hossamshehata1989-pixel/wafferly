class SettingsState {
  final bool soundEffects;
  final bool hapticFeedback;
  final bool fingerprintEnabled;

  const SettingsState({
    this.soundEffects = true,
    this.hapticFeedback = true,
    this.fingerprintEnabled = false,
  });

  SettingsState copyWith({
    bool? soundEffects,
    bool? hapticFeedback,
    bool? fingerprintEnabled,
  }) {
    return SettingsState(
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
    );
  }
}
