@Tags(<String>['golden'])
library;

import 'package:anchored_popover/anchored_popover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const Key anchorKey = Key('anchor');

/// A screen with the popover already open over a plain background, sized to
/// the popover rather than to a phone, so the image is all surface.
Widget scene({
  required Widget popover,
  Brightness brightness = Brightness.light,
  AnchoredPopoverTheme? theme,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[?theme],
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(key: anchorKey, width: 120, height: 40, child: popover),
      ),
    ),
  );
}

Future<void> open(WidgetTester tester) async {
  await tester.longPress(find.byKey(anchorKey));
  await tester.pumpAndSettle();
}

void main() {
  Widget label(BuildContext context, VoidCallback dismiss) =>
      const Text('Favourite');

  testWidgets('the default surface', (WidgetTester tester) async {
    await tester.pumpWidget(
      scene(
        popover: AnchoredPopover(
          autoDismiss: false,
          popoverBuilder: label,
          child: const ColoredBox(color: Color(0xFF7986CB)),
        ),
      ),
    );
    await open(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/surface_light.png'),
    );
  });

  testWidgets('the default surface in the dark', (WidgetTester tester) async {
    await tester.pumpWidget(
      scene(
        brightness: Brightness.dark,
        popover: AnchoredPopover(
          autoDismiss: false,
          popoverBuilder: label,
          child: const ColoredBox(color: Color(0xFF7986CB)),
        ),
      ),
    );
    await open(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/surface_dark.png'),
    );
  });

  testWidgets('a themed surface', (WidgetTester tester) async {
    await tester.pumpWidget(
      scene(
        theme: const AnchoredPopoverTheme(
          backgroundColor: Color(0xFF1B5E20),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFFFFEB3B), width: 3),
          padding: EdgeInsets.all(20),
          textStyle: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
          shadows: <BoxShadow>[
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        popover: AnchoredPopover(
          autoDismiss: false,
          popoverBuilder: label,
          child: const ColoredBox(color: Color(0xFF7986CB)),
        ),
      ),
    );
    await open(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/surface_themed.png'),
    );
  });

  testWidgets('no surface at all', (WidgetTester tester) async {
    await tester.pumpWidget(
      scene(
        popover: AnchoredPopover(
          autoDismiss: false,
          decorate: false,
          popoverBuilder: label,
          child: const ColoredBox(color: Color(0xFF7986CB)),
        ),
      ),
    );
    await open(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/undecorated.png'),
    );
  });

  testWidgets('behind a scrim', (WidgetTester tester) async {
    await tester.pumpWidget(
      scene(
        popover: AnchoredPopover(
          autoDismiss: false,
          barrierColor: const Color(0x99000000),
          popoverBuilder: label,
          child: const ColoredBox(color: Color(0xFF7986CB)),
        ),
      ),
    );
    await open(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/scrim.png'),
    );
  });

  testWidgets('flipped below an anchor at the top of the screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              key: anchorKey,
              width: 120,
              height: 40,
              child: AnchoredPopover(
                autoDismiss: false,
                popoverBuilder: label,
                child: const ColoredBox(color: Color(0xFF7986CB)),
              ),
            ),
          ),
        ),
      ),
    );
    await open(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/flipped.png'),
    );
  });

  testWidgets('half way through its entrance', (WidgetTester tester) async {
    await tester.pumpWidget(
      scene(
        popover: AnchoredPopover(
          autoDismiss: false,
          transitionDuration: const Duration(milliseconds: 200),
          popoverBuilder: label,
          child: const ColoredBox(color: Color(0xFF7986CB)),
        ),
      ),
    );
    await tester.longPress(find.byKey(anchorKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/entering.png'),
    );
  });
}
