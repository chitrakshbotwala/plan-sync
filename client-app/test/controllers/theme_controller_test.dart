import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppThemeController controller;

  setUp(() {
    controller = AppThemeController();
  });

  group('initial state', () {
    test('defaults to ThemeMode.system', () {
      expect(controller.themeMode, ThemeMode.system);
    });

    test('isDarkMode is false by default', () {
      expect(controller.isDarkMode, isFalse);
    });
  });

  group('toggleTheme', () {
    test('flips from non-dark to dark', () {
      controller.themeMode = ThemeMode.light;
      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
    });

    test('flips from dark to light', () {
      controller.themeMode = ThemeMode.dark;
      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);
    });

    test('toggling from system mode goes to dark', () {
      // anything not dark goes to dark per implementation
      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);
    });

    test('notifies listeners on toggle', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.toggleTheme();
      expect(notifications, 1);
    });
  });

  group('initThemeMode', () {
    test('sets light/dark from platform brightness', () {
      controller.initThemeMode();
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      expect(
        controller.themeMode,
        brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      );
    });
  });

  group('static themes', () {
    test('lightTheme uses light brightness', () {
      expect(AppThemeController.lightTheme.brightness, Brightness.light);
    });

    test('darkTheme uses dark brightness', () {
      expect(AppThemeController.darkTheme.brightness, Brightness.dark);
    });
  });
}
