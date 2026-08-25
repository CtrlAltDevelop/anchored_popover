// Renders the example app off screen and writes the images used by the
// README and by pub.dev.
//
//   cd example && flutter test tool/screenshot_test.dart --update-goldens
//
// It is a golden test so that `flutter test` can drive it headlessly, but it
// lives outside `test/` and is never part of the suite: it depends on the host
// having the Flutter SDK's bundled fonts, which is not something CI should be
// asked to reproduce.
import 'dart:io';
import 'dart:typed_data';

import 'package:anchored_popover_example/main.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The logical size the app is laid out at — a phone, roughly.
const Size _canvas = Size(400, 780);

/// The captured image is one pixel per logical pixel, so the scene is scaled
/// up to get a screenshot that still looks sharp on a dense display.
const double _scale = 2;

/// The status bar the app draws its bar under.
const EdgeInsets _viewPadding = EdgeInsets.only(top: 44);

final Key _root = UniqueKey();

void main() {
  setUpAll(_loadFonts);

  testWidgets('light', (WidgetTester tester) async {
    await _capture(tester, ThemeMode.light, 'screenshot.png');
  });

  testWidgets('dark', (WidgetTester tester) async {
    await _capture(tester, ThemeMode.dark, 'screenshot_dark.png');
  });
}

Future<void> _capture(
  WidgetTester tester,
  ThemeMode themeMode,
  String name,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _canvas * _scale;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    RepaintBoundary(
      key: _root,
      child: SizedBox.fromSize(
        size: _canvas * _scale,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox.fromSize(
            size: _canvas,
            child: MediaQuery(
              data: const MediaQueryData(
                size: _canvas,
                padding: _viewPadding,
                viewPadding: _viewPadding,
              ),
              child: ExampleApp(initialThemeMode: themeMode),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.longPress(find.text('DOT'));
  // Long enough for the entrance transition and for the row's press highlight
  // to fade, short enough that the popover has not started dismissing itself.
  await tester.pump(const Duration(milliseconds: 1200));

  await expectLater(find.byKey(_root), matchesGoldenFile('../../doc/$name'));

  // Let the auto-dismiss timer fire, so the test ends with nothing pending.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Registers the fonts the SDK ships with, so text renders as text rather than
/// as the boxes `flutter_test` draws by default.
Future<void> _loadFonts() async {
  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    fail('FLUTTER_ROOT is unset; run this through `flutter test`.');
  }
  final Directory fonts = Directory(
    '$root/bin/cache/artifacts/material_fonts',
  );
  await _load('Roboto', <String>[
    '${fonts.path}/Roboto-Regular.ttf',
    '${fonts.path}/Roboto-Medium.ttf',
    '${fonts.path}/Roboto-Bold.ttf',
  ]);
  await _load('MaterialIcons', <String>[
    '${fonts.path}/MaterialIcons-Regular.otf',
  ]);
}

Future<void> _load(String family, List<String> paths) async {
  final FontLoader loader = FontLoader(family);
  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) {
      fail('Missing font ${file.path}.');
    }
    loader.addFont(
      file.readAsBytes().then(
        (Uint8List bytes) => ByteData.sublistView(bytes),
      ),
    );
  }
  await loader.load();
}
