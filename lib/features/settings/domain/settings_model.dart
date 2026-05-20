class SettingsModel {
  final bool notificationsEnabled;
  final bool hydrationReminders;
  final bool soundEnabled;
  final bool autoplayRest;
  final String units; // 'metric' or 'imperial'

  SettingsModel({
    required this.notificationsEnabled,
    required this.hydrationReminders,
    required this.soundEnabled,
    required this.autoplayRest,
    required this.units,
  });

  factory SettingsModel.defaults() => SettingsModel(
        notificationsEnabled: true,
        hydrationReminders: false,
        soundEnabled: true,
        autoplayRest: true,
        units: 'metric',
      );

  SettingsModel copyWith({
    bool? notificationsEnabled,
    bool? hydrationReminders,
    bool? soundEnabled,
    bool? autoplayRest,
    String? units,
  }) {
    return SettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hydrationReminders: hydrationReminders ?? this.hydrationReminders,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoplayRest: autoplayRest ?? this.autoplayRest,
      units: units ?? this.units,
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'hydrationReminders': hydrationReminders,
        'soundEnabled': soundEnabled,
        'autoplayRest': autoplayRest,
        'units': units,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        hydrationReminders: json['hydrationReminders'] as bool? ?? false,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        autoplayRest: json['autoplayRest'] as bool? ?? true,
        units: json['units'] as String? ?? 'metric',
      );
}
