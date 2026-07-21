import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _preferenceKey = 'theme_mode';
  bool _changedWhileLoading = false;

  @override
  ThemeMode build() {
    unawaited(_load());
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _changedWhileLoading = true;
    state = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, mode.name);
    } catch (_) {
      // Keep the selected mode in memory if local storage is unavailable.
    }
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedValue = preferences.getString(_preferenceKey);
      if (_changedWhileLoading || savedValue == null) {
        return;
      }

      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedValue,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // Use ThemeMode.system when the platform storage channel is unavailable.
    }
  }
}
