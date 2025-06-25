// VGV-compliant golden test utilities
// Following Very Good Ventures patterns for golden file testing

import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Utilities for golden file testing following VGV patterns
class GoldenTestHelper {
  /// Standard device configurations for golden tests
  static const devices = [
    Device.phone,
    Device.iphone11,
    Device.tabletPortrait,
    Device.tabletLandscape,
  ];

  /// Standard theme configurations
  static final themes = [
    ThemeData.light(),
    ThemeData.dark(),
  ];

  /// Tests a widget across multiple devices and themes
  static void testWidgetGoldens(
    String description,
    Widget widget, {
    List<Device>? devices,
    List<ThemeData>? themes,
    String? goldenPath,
  }) {
    final testDevices = devices ?? GoldenTestHelper.devices;
    final testThemes = themes ?? GoldenTestHelper.themes;

    for (final device in testDevices) {
      for (final theme in testThemes) {
        final themeName =
            theme.brightness == Brightness.light ? 'light' : 'dark';
        final testName = '$description ${device.name} $themeName';
        final goldenFile = goldenPath != null
            ? '$goldenPath/${device.name}_$themeName.png'
            : 'goldens/${description.replaceAll(' ', '_')}_${device.name}_$themeName.png';

        testGoldens(testName, (tester) async {
          await tester.pumpDeviceBuilder(
            DeviceBuilder()
              ..overrideDevicesForAllScenarios(devices: [device])
              ..addScenario(
                widget: MaterialApp(
                  theme: theme,
                  home: widget,
                  debugShowCheckedModeBanner: false,
                ),
              ),
          );
        });
      }
    }
  }

  /// Tests a widget in a specific scenario
  static void testScenarioGoldens(
    String description,
    Widget Function() widgetBuilder, {
    List<Device>? devices,
    String? goldenPath,
  }) {
    final testDevices = devices ?? [Device.phone];

    testGoldens(description, (tester) async {
      await tester.pumpDeviceBuilder(
        DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: testDevices)
          ..addScenario(
            widget: MaterialApp(
              home: widgetBuilder(),
              debugShowCheckedModeBanner: false,
            ),
          ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
      );
    });
  }

  /// Tests multiple scenarios of a widget
  static void testMultipleScenarios(
    String description,
    Map<String, Widget> scenarios, {
    List<Device>? devices,
    String? goldenPath,
  }) {
    final testDevices = devices ?? [Device.phone];

    testGoldens(description, (tester) async {
      final deviceBuilder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: testDevices);

      scenarios.forEach((scenarioName, widget) {
        deviceBuilder.addScenario(
          name: scenarioName,
          widget: MaterialApp(
            home: widget,
            debugShowCheckedModeBanner: false,
          ),
        );
      });

      await tester.pumpDeviceBuilder(deviceBuilder);
    });
  }

  /// Tests a widget with different text scales for accessibility
  static void testAccessibilityGoldens(
    String description,
    Widget widget, {
    List<double>? textScales,
    Device? device,
  }) {
    final scales = textScales ?? [0.5, 1.0, 1.5, 2.0];
    final testDevice = device ?? Device.phone;

    for (final scale in scales) {
      testGoldens('$description text scale $scale', (tester) async {
        await tester.pumpDeviceBuilder(
          DeviceBuilder()
            ..overrideDevicesForAllScenarios(devices: [testDevice])
            ..addScenario(
              widget: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: widget,
                ),
                debugShowCheckedModeBanner: false,
              ),
            ),
        );
      });
    }
  }

  /// Tests loading states
  static void testLoadingStates(
    String description,
    Map<String, Widget> loadingStates, {
    Device? device,
  }) {
    final testDevice = device ?? Device.phone;

    testGoldens('$description loading states', (tester) async {
      final deviceBuilder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [testDevice]);

      loadingStates.forEach((stateName, widget) {
        deviceBuilder.addScenario(
          name: stateName,
          widget: MaterialApp(
            home: widget,
            debugShowCheckedModeBanner: false,
          ),
        );
      });

      await tester.pumpDeviceBuilder(deviceBuilder);
    });
  }

  /// Tests error states
  static void testErrorStates(
    String description,
    Map<String, Widget> errorStates, {
    Device? device,
  }) {
    final testDevice = device ?? Device.phone;

    testGoldens('$description error states', (tester) async {
      final deviceBuilder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [testDevice]);

      errorStates.forEach((stateName, widget) {
        deviceBuilder.addScenario(
          name: stateName,
          widget: MaterialApp(
            home: widget,
            debugShowCheckedModeBanner: false,
          ),
        );
      });

      await tester.pumpDeviceBuilder(deviceBuilder);
    });
  }

  /// Creates a standard material app wrapper
  static Widget Function(Widget child) materialAppWrapper({
    ThemeData? theme,
    Locale? locale,
    Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  }) {
    return (child) => MaterialApp(
          theme: theme ?? ThemeData.light(),
          locale: locale,
          localizationsDelegates: localizationsDelegates,
          home: Scaffold(body: child), // Often good to have a Scaffold
          debugShowCheckedModeBanner: false,
        );
  }

  /// Tests with custom themes
  static void testCustomThemes(
    String description,
    Widget widget,
    Map<String, ThemeData> customThemes, {
    Device? device,
  }) {
    final testDevice = device ?? Device.phone;

    customThemes.forEach((themeName, themeData) {
      testGoldens('$description $themeName theme', (tester) async {
        await tester.pumpDeviceBuilder(
          DeviceBuilder()
            ..overrideDevicesForAllScenarios(devices: [testDevice])
            ..addScenario(
              widget: MaterialApp(
                theme: themeData,
                home: widget,
                debugShowCheckedModeBanner: false,
              ),
            ),
        );
      });
    });
  }
}
