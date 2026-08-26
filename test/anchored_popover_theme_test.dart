import 'package:anchored_popover/anchored_popover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A theme with every field set, and set to something no default would be.
const AnchoredPopoverTheme filled = AnchoredPopoverTheme(
  backgroundColor: Color(0xFF102030),
  borderRadius: BorderRadius.all(Radius.circular(2)),
  shape: StadiumBorder(),
  borderSide: BorderSide(color: Color(0xFF405060), width: 3),
  padding: EdgeInsets.all(21),
  shadows: <BoxShadow>[BoxShadow(blurRadius: 33)],
  textStyle: TextStyle(fontSize: 41),
  screenPadding: EdgeInsets.all(51),
  showDuration: Duration(seconds: 61),
  transitionDuration: Duration(milliseconds: 71),
  reverseTransitionDuration: Duration(milliseconds: 81),
  curve: Curves.bounceIn,
  reverseCurve: Curves.bounceOut,
  hoverEnterDuration: Duration(milliseconds: 91),
  hoverExitDuration: Duration(milliseconds: 101),
);

void main() {
  const ColorScheme scheme = ColorScheme.light();

  group('withDefaults', () {
    test('fills in every field a widget has to read', () {
      final AnchoredPopoverTheme theme = const AnchoredPopoverTheme()
          .withDefaults(scheme);

      expect(theme.backgroundColor, scheme.surfaceContainerHigh);
      expect(theme.borderRadius, isNotNull);
      expect(theme.borderSide, BorderSide.none);
      expect(theme.padding, isNotNull);
      expect(theme.shadows, isNotNull);
      expect(theme.textStyle, isNotNull);
      expect(theme.screenPadding, isNotNull);
      expect(theme.showDuration, const Duration(seconds: 3));
      expect(theme.transitionDuration, const Duration(milliseconds: 120));
      expect(theme.reverseTransitionDuration, const Duration(milliseconds: 90));
      expect(theme.curve, Curves.easeOutCubic);
      expect(theme.reverseCurve, Curves.easeIn);
      expect(theme.hoverEnterDuration, const Duration(milliseconds: 300));
      expect(theme.hoverExitDuration, const Duration(milliseconds: 100));
    });

    test('leaves shape unset, so borderRadius and borderSide still apply', () {
      expect(const AnchoredPopoverTheme().withDefaults(scheme).shape, isNull);
    });

    test('keeps every field that was already set', () {
      final AnchoredPopoverTheme theme = filled.withDefaults(scheme);

      expect(theme.backgroundColor, filled.backgroundColor);
      expect(theme.borderRadius, filled.borderRadius);
      expect(theme.shape, filled.shape);
      expect(theme.borderSide, filled.borderSide);
      expect(theme.padding, filled.padding);
      expect(theme.shadows, filled.shadows);
      expect(theme.textStyle, filled.textStyle);
      expect(theme.screenPadding, filled.screenPadding);
      expect(theme.showDuration, filled.showDuration);
      expect(theme.transitionDuration, filled.transitionDuration);
      expect(theme.reverseTransitionDuration, filled.reverseTransitionDuration);
      expect(theme.curve, filled.curve);
      expect(theme.reverseCurve, filled.reverseCurve);
      expect(theme.hoverEnterDuration, filled.hoverEnterDuration);
      expect(theme.hoverExitDuration, filled.hoverExitDuration);
    });

    test('an empty shadow list survives, rather than defaulting', () {
      const AnchoredPopoverTheme none = AnchoredPopoverTheme(
        shadows: <BoxShadow>[],
      );
      expect(none.withDefaults(scheme).shadows, isEmpty);
    });
  });

  group('copyWith', () {
    test('replaces every field it is given', () {
      final AnchoredPopoverTheme theme = const AnchoredPopoverTheme().copyWith(
        backgroundColor: filled.backgroundColor,
        borderRadius: filled.borderRadius,
        shape: filled.shape,
        borderSide: filled.borderSide,
        padding: filled.padding,
        shadows: filled.shadows,
        textStyle: filled.textStyle,
        screenPadding: filled.screenPadding,
        showDuration: filled.showDuration,
        transitionDuration: filled.transitionDuration,
        reverseTransitionDuration: filled.reverseTransitionDuration,
        curve: filled.curve,
        reverseCurve: filled.reverseCurve,
        hoverEnterDuration: filled.hoverEnterDuration,
        hoverExitDuration: filled.hoverExitDuration,
      );

      expect(theme.backgroundColor, filled.backgroundColor);
      expect(theme.borderRadius, filled.borderRadius);
      expect(theme.shape, filled.shape);
      expect(theme.borderSide, filled.borderSide);
      expect(theme.padding, filled.padding);
      expect(theme.shadows, filled.shadows);
      expect(theme.textStyle, filled.textStyle);
      expect(theme.screenPadding, filled.screenPadding);
      expect(theme.showDuration, filled.showDuration);
      expect(theme.transitionDuration, filled.transitionDuration);
      expect(theme.reverseTransitionDuration, filled.reverseTransitionDuration);
      expect(theme.curve, filled.curve);
      expect(theme.reverseCurve, filled.reverseCurve);
      expect(theme.hoverEnterDuration, filled.hoverEnterDuration);
      expect(theme.hoverExitDuration, filled.hoverExitDuration);
    });

    test('keeps every field it is not given', () {
      final AnchoredPopoverTheme theme = filled.copyWith();

      expect(theme.backgroundColor, filled.backgroundColor);
      expect(theme.borderRadius, filled.borderRadius);
      expect(theme.shape, filled.shape);
      expect(theme.borderSide, filled.borderSide);
      expect(theme.padding, filled.padding);
      expect(theme.shadows, filled.shadows);
      expect(theme.textStyle, filled.textStyle);
      expect(theme.screenPadding, filled.screenPadding);
      expect(theme.showDuration, filled.showDuration);
      expect(theme.transitionDuration, filled.transitionDuration);
      expect(theme.reverseTransitionDuration, filled.reverseTransitionDuration);
      expect(theme.curve, filled.curve);
      expect(theme.reverseCurve, filled.reverseCurve);
      expect(theme.hoverEnterDuration, filled.hoverEnterDuration);
      expect(theme.hoverExitDuration, filled.hoverExitDuration);
    });

    test('changes one field without disturbing the rest', () {
      final AnchoredPopoverTheme theme = filled.copyWith(
        hoverExitDuration: const Duration(milliseconds: 7),
      );

      expect(theme.hoverExitDuration, const Duration(milliseconds: 7));
      expect(theme.hoverEnterDuration, filled.hoverEnterDuration);
      expect(theme.backgroundColor, filled.backgroundColor);
    });
  });

  group('lerp', () {
    const AnchoredPopoverTheme other = AnchoredPopoverTheme(
      backgroundColor: Color(0xFF000000),
      borderRadius: BorderRadius.all(Radius.circular(12)),
      shape: CircleBorder(),
      borderSide: BorderSide(color: Color(0xFF000000), width: 13),
      padding: EdgeInsets.all(1),
      shadows: <BoxShadow>[BoxShadow(blurRadius: 3)],
      textStyle: TextStyle(fontSize: 1),
      screenPadding: EdgeInsets.all(1),
      showDuration: Duration(seconds: 1),
      transitionDuration: Duration(milliseconds: 1),
      reverseTransitionDuration: Duration(milliseconds: 1),
      curve: Curves.linear,
      reverseCurve: Curves.linear,
      hoverEnterDuration: Duration(milliseconds: 1),
      hoverExitDuration: Duration(milliseconds: 1),
    );

    test('a null endpoint stays put', () {
      expect(filled.lerp(null, 0.5), same(filled));
    });

    test('t of 0 is this theme', () {
      final AnchoredPopoverTheme theme = filled.lerp(other, 0);

      expect(theme.backgroundColor, filled.backgroundColor);
      expect(theme.padding, filled.padding);
      expect(theme.showDuration, filled.showDuration);
      expect(theme.hoverEnterDuration, filled.hoverEnterDuration);
      expect(theme.hoverExitDuration, filled.hoverExitDuration);
    });

    test('t of 1 is the other theme', () {
      final AnchoredPopoverTheme theme = filled.lerp(other, 1);

      expect(theme.backgroundColor, other.backgroundColor);
      expect(theme.padding, other.padding);
      expect(theme.showDuration, other.showDuration);
      expect(theme.hoverEnterDuration, other.hoverEnterDuration);
      expect(theme.hoverExitDuration, other.hoverExitDuration);
    });

    test('continuous fields interpolate', () {
      final AnchoredPopoverTheme theme = filled.lerp(other, 0.5);

      expect(theme.padding, const EdgeInsets.all(11));
      expect(
        theme.borderRadius,
        BorderRadius.lerp(filled.borderRadius, other.borderRadius, 0.5),
      );
      expect(theme.screenPadding, const EdgeInsets.all(26));
      expect(theme.borderSide!.width, 8);
      expect(theme.shadows!.single.blurRadius, 18);
      expect(theme.textStyle!.fontSize, 21);
      expect(theme.shape, isNotNull);
    });

    test('durations and curves snap at the half-way point', () {
      final AnchoredPopoverTheme before = filled.lerp(other, 0.49);
      final AnchoredPopoverTheme after = filled.lerp(other, 0.5);

      expect(before.showDuration, filled.showDuration);
      expect(before.transitionDuration, filled.transitionDuration);
      expect(
        before.reverseTransitionDuration,
        filled.reverseTransitionDuration,
      );
      expect(before.curve, filled.curve);
      expect(before.reverseCurve, filled.reverseCurve);
      expect(before.hoverEnterDuration, filled.hoverEnterDuration);
      expect(before.hoverExitDuration, filled.hoverExitDuration);

      expect(after.showDuration, other.showDuration);
      expect(after.transitionDuration, other.transitionDuration);
      expect(after.reverseTransitionDuration, other.reverseTransitionDuration);
      expect(after.curve, other.curve);
      expect(after.reverseCurve, other.reverseCurve);
      expect(after.hoverEnterDuration, other.hoverEnterDuration);
      expect(after.hoverExitDuration, other.hoverExitDuration);
    });

    test('a null border side snaps rather than throwing', () {
      const AnchoredPopoverTheme unset = AnchoredPopoverTheme();

      expect(unset.lerp(filled, 0.4).borderSide, isNull);
      expect(unset.lerp(filled, 0.6).borderSide, filled.borderSide);
    });
  });

  group('equality', () {
    test('two identical themes are equal, and hash alike', () {
      const AnchoredPopoverTheme a = AnchoredPopoverTheme(
        backgroundColor: Color(0xFF112233),
        shadows: <BoxShadow>[BoxShadow(blurRadius: 4)],
        showDuration: Duration(seconds: 5),
      );
      const AnchoredPopoverTheme b = AnchoredPopoverTheme(
        backgroundColor: Color(0xFF112233),
        shadows: <BoxShadow>[BoxShadow(blurRadius: 4)],
        showDuration: Duration(seconds: 5),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('shadow lists compare by content, not identity', () {
      const AnchoredPopoverTheme a = AnchoredPopoverTheme(
        shadows: <BoxShadow>[BoxShadow(blurRadius: 4)],
      );
      const AnchoredPopoverTheme b = AnchoredPopoverTheme(
        shadows: <BoxShadow>[BoxShadow(blurRadius: 9)],
      );

      expect(a, isNot(b));
      expect(
        a,
        const AnchoredPopoverTheme(
          shadows: <BoxShadow>[BoxShadow(blurRadius: 4)],
        ),
      );
    });

    test('every field takes part', () {
      const AnchoredPopoverTheme base = AnchoredPopoverTheme();

      expect(filled, isNot(base));
      expect(
        base.copyWith(hoverExitDuration: const Duration(seconds: 1)),
        isNot(base),
      );
      expect(
        base.copyWith(hoverEnterDuration: const Duration(seconds: 1)),
        isNot(base),
      );
      expect(base.copyWith(curve: Curves.bounceIn), isNot(base));
      expect(base.copyWith(shape: const CircleBorder()), isNot(base));
      expect(filled.copyWith(), filled);
    });

    test('an unequal theme is what makes a rebuild happen', () {
      // ThemeExtension identity is how ThemeData decides a rebuild is needed;
      // without ==, two identical registrations would never compare equal.
      expect(
        const AnchoredPopoverTheme(showDuration: Duration(seconds: 1)) ==
            const AnchoredPopoverTheme(showDuration: Duration(seconds: 2)),
        isFalse,
      );
    });
  });

  group('resolve', () {
    testWidgets('takes the registered theme, and defaults the rest', (
      WidgetTester tester,
    ) async {
      late AnchoredPopoverTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              AnchoredPopoverTheme(
                showDuration: Duration(seconds: 9),
                hoverEnterDuration: Duration(milliseconds: 42),
              ),
            ],
          ),
          home: Builder(
            builder: (BuildContext context) {
              resolved = AnchoredPopoverTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.showDuration, const Duration(seconds: 9));
      expect(resolved.hoverEnterDuration, const Duration(milliseconds: 42));
      // Untouched by the registration, so still the default.
      expect(resolved.hoverExitDuration, const Duration(milliseconds: 100));
      expect(resolved.backgroundColor, isNotNull);
    });

    testWidgets('works with nothing registered at all', (
      WidgetTester tester,
    ) async {
      late AnchoredPopoverTheme resolved;
      late AnchoredPopoverTheme? registered;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              registered = AnchoredPopoverTheme.maybeOf(context);
              resolved = AnchoredPopoverTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(registered, isNull);
      expect(resolved.hoverEnterDuration, const Duration(milliseconds: 300));
      expect(resolved.showDuration, const Duration(seconds: 3));
    });
  });
}
