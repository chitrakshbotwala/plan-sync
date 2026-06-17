import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppThemeController controller;

  setUp(() {
    controller = AppThemeController();
  });

  group('toggleTheme', () {
    test('flips from light to dark', () {
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

    test('treats non-dark modes (incl. system) as light when toggling', () {
      // implementation: any mode other than dark routes to dark on toggle
      controller.themeMode = ThemeMode.system;
      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);
    });

    test('notifies listeners exactly once per toggle', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.toggleTheme();
      controller.toggleTheme();
      expect(notifications, 2);
    });
  });

  group('initThemeMode', () {
    test('mirrors current platform brightness', () {
      controller.initThemeMode();
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      expect(
        controller.themeMode,
        brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      );
    });

    test('never produces ThemeMode.system', () {
      // initThemeMode is meant to resolve "system" into a concrete mode
      controller.themeMode = ThemeMode.system;
      controller.initThemeMode();
      expect(controller.themeMode, isNot(ThemeMode.system));
    });
  });
}
