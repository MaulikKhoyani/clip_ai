import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class LocalDataSource {
  static const _settingsBox = 'settings';
  static const _cacheBox = 'cache';

  static const _keyOnboarding = 'onboarding_completed';
  static const _keyCachedUser = 'cached_user';

  Future<Box> _openBox(String name) => Hive.openBox(name);

  // ── Onboarding ──

  Future<bool> isOnboardingCompleted() async {
    final box = await _openBox(_settingsBox);
    return box.get(_keyOnboarding, defaultValue: false) as bool;
  }

  Future<void> setOnboardingCompleted() async {
    final box = await _openBox(_settingsBox);
    await box.put(_keyOnboarding, true);
  }

  // ── Cached User ──

  Future<Map<String, dynamic>?> getCachedUser() async {
    final box = await _openBox(_cacheBox);
    final raw = box.get(_keyCachedUser) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setCachedUser(Map<String, dynamic> json) async {
    final box = await _openBox(_cacheBox);
    await box.put(_keyCachedUser, jsonEncode(json));
  }

  // ── Cache Management ──

  Future<void> clearCache() async {
    final settings = await _openBox(_settingsBox);
    final cache = await _openBox(_cacheBox);
    await settings.clear();
    await cache.clear();
  }
}
