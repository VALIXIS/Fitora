import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';

final personalizationLocalDataSourceProvider =
    Provider<PersonalizationLocalDataSource>((ref) {
  return PersonalizationLocalDataSource();
});

class PersonalizationLocalDataSource {
  Future<bool> isCompleted() async {
    final prefs = await AppPreferences.instance();
    return prefs.getBool(StorageKeys.personalizationCompleted) ?? false;
  }

  Future<void> setCompleted(bool value) async {
    final prefs = await AppPreferences.instance();
    await prefs.setBool(StorageKeys.personalizationCompleted, value);
  }

  Future<PersonalizationProfile?> fetchProfile() async {
    final prefs = await AppPreferences.instance();
    final raw = prefs.getString(StorageKeys.personalizationProfile);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return PersonalizationProfile.fromJson(decoded);
  }

  Future<void> saveProfile(PersonalizationProfile profile) async {
    final prefs = await AppPreferences.instance();
    final encoded = jsonEncode(profile.toJson());
    await prefs.setString(StorageKeys.personalizationProfile, encoded);
  }

  Future<void> clearProfile() async {
    final prefs = await AppPreferences.instance();
    await prefs.remove(StorageKeys.personalizationProfile);
  }
}
