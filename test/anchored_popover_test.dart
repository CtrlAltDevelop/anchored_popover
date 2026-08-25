import 'package:anchored_popover/anchored_popover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const Key anchorKey = Key('anchor');
const Key popoverKey = Key('popover');

/// A screen holding a 100x40 anchor at [alignment].
Widget host(Widget popover, {Alignment alignment = Alignment.center}) =>
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: alignment,
          child: SizedBox(
            key: anchorKey,
            width: 100,
            height: 40,
            child: popover,
          ),
        ),
      ),
    );

Widget content([String label = 'Favourite']) =>
    SizedBox(key: popoverKey, width: 80, height: 24, child: Text(label));

void main() {
  group('opening and closing', () {
    testWidgets('a long press opens the popover', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      expect(find.byKey(popoverKey), findsNothing);
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('it dismisses itself after showDuration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            showDuration: const Duration(seconds: 2),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.byKey(popoverKey), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('autoDismiss false keeps it up', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 1));
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('reopening restarts the dismiss timer', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            controller: controller,
            showDuration: const Duration(seconds: 2),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1500));
      controller.show();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byKey(popoverKey), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('the builder can dismiss it', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            popoverBuilder: (_, VoidCallback dismiss) =>
                GestureDetector(onTap: dismiss, child: content()),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(popoverKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('a tap outside dismisses it, and is absorbed', (
      WidgetTester tester,
    ) async {
      int anchorTaps = 0;
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => anchorTaps++,
              child: const Placeholder(),
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
      expect(anchorTaps, 0);
    });

    testWidgets('dismissOnTapOutside false leaves the anchor tappable', (
      WidgetTester tester,
    ) async {
      int anchorTaps = 0;
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            dismissOnTapOutside: false,
            popoverBuilder: (_, _) => content(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => anchorTaps++,
              child: const Placeholder(),
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(anchorKey), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
      expect(anchorTaps, 1);
    });

    testWidgets('onShow and onDismiss report every open and close', (
      WidgetTester tester,
    ) async {
      int shown = 0;
      int dismissed = 0;
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            controller: controller,
            showDuration: const Duration(seconds: 1),
            onShow: () => shown++,
            onDismiss: () => dismissed++,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();
      expect(<int>[shown, dismissed], <int>[1, 0]);

      // A reopen is not a second onShow.
      controller.show();
      await tester.pumpAndSettle();
      expect(<int>[shown, dismissed], <int>[1, 0]);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(<int>[shown, dismissed], <int>[1, 1]);
    });
  });

  group('triggers', () {
    testWidgets('tap toggles', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.tap,
            autoDismiss: false,
            dismissOnTapOutside: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.tap(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      await tester.tap(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('manual ignores gestures', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.manual,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.tap(find.byKey(anchorKey), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('longPress leaves the child\'s own onTap working', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            popoverBuilder: (_, _) => content(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const Placeholder(),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.byKey(popoverKey), findsNothing);
    });
  });

  group('controller', () {
    testWidgets('drives the popover, and reports its state', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            controller: controller,
            trigger: PopoverTrigger.manual,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      expect(controller.isOpen, isFalse);
      controller.show();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
      expect(controller.isOpen, isTrue);

      controller.hide();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('reports a popover closed by its own timer', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            controller: controller,
            showDuration: const Duration(seconds: 1),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
    });

    testWidgets('AnchoredPopoverController.open starts open', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller =
          AnchoredPopoverController.open();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            controller: controller,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('the state is reachable through a GlobalKey', (
      WidgetTester tester,
    ) async {
      final GlobalKey<AnchoredPopoverState> key =
          GlobalKey<AnchoredPopoverState>();

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            key: key,
            trigger: PopoverTrigger.manual,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      key.currentState!.show();
      await tester.pumpAndSettle();
      expect(key.currentState!.isOpen, isTrue);

      key.currentState!.toggle();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });
  });

  group('placement', () {
    testWidgets('sits centred just above the anchor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      final Rect anchor = tester.getRect(find.byKey(anchorKey));
      final Rect popover = tester.getRect(find.byKey(popoverKey));
      expect(popover.center.dx, anchor.center.dx);
      expect(popover.bottom, anchor.top - 8);
      expect(popover.size, const Size(80, 24));
    });

    testWidgets('flips below an anchor at the top of the screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
          alignment: Alignment.topCenter,
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      final Rect anchor = tester.getRect(find.byKey(anchorKey));
      final Rect popover = tester.getRect(find.byKey(popoverKey));
      expect(popover.top, anchor.bottom + 8);
    });

    testWidgets('clamps a wide popover inside the screen padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            screenPadding: const EdgeInsets.all(16),
            popoverBuilder: (_, _) =>
                const SizedBox(key: popoverKey, width: 400, height: 24),
            child: const Placeholder(),
          ),
          alignment: Alignment.centerLeft,
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(popoverKey)).left, 16);
    });

    testWidgets('keeps out of the safe area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 60)),
          child: MaterialApp(
            home: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                key: anchorKey,
                width: 100,
                height: 40,
                child: AnchoredPopover(
                  decorate: false,
                  autoDismiss: false,
                  flip: false,
                  popoverBuilder: (_, _) => content(),
                  child: const Placeholder(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      // 60 of safe area plus the default 8 of screen padding.
      expect(tester.getRect(find.byKey(popoverKey)).top, 68);
    });

    testWidgets('a directional anchor mirrors in RTL', (
      WidgetTester tester,
    ) async {
      Widget build(TextDirection direction) => MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Center(
            child: SizedBox(
              key: anchorKey,
              width: 100,
              height: 40,
              child: AnchoredPopover(
                decorate: false,
                autoDismiss: false,
                dismissOnTapOutside: false,
                targetAnchor: AlignmentDirectional.topStart,
                followerAnchor: AlignmentDirectional.bottomStart,
                offset: Offset.zero,
                popoverBuilder: (_, _) => content(),
                child: const Placeholder(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(build(TextDirection.ltr));
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(popoverKey)).left,
        tester.getRect(find.byKey(anchorKey)).left,
      );

      await tester.pumpWidget(build(TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(popoverKey)).right,
        tester.getRect(find.byKey(anchorKey)).right,
      );
    });
  });

  group('scrolling', () {
    Widget list(ScrollController controller, {required Widget popover}) =>
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 40,
              itemExtent: 60,
              itemBuilder: (BuildContext context, int index) => index == 5
                  ? SizedBox(key: anchorKey, height: 60, child: popover)
                  : const SizedBox(height: 60),
            ),
          ),
        );

    testWidgets('the popover follows its anchor', (WidgetTester tester) async {
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);

      await tester.pumpWidget(
        list(
          scroll,
          popover: AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            dismissOnTapOutside: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      final double before = tester.getRect(find.byKey(popoverKey)).top;

      scroll.jumpTo(50);
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(find.byKey(popoverKey)).top, before - 50);
      expect(
        tester.getRect(find.byKey(popoverKey)).bottom,
        tester.getRect(find.byKey(anchorKey)).top - 8,
      );
    });

    testWidgets('followAnchorOnScroll false pins it where it opened', (
      WidgetTester tester,
    ) async {
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);

      await tester.pumpWidget(
        list(
          scroll,
          popover: AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            dismissOnTapOutside: false,
            followAnchorOnScroll: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      final double before = tester.getRect(find.byKey(popoverKey)).top;

      scroll.jumpTo(50);
      await tester.pump();
      expect(tester.getRect(find.byKey(popoverKey)).top, before);
    });

    testWidgets('dismissOnScroll closes it', (WidgetTester tester) async {
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);

      await tester.pumpWidget(
        list(
          scroll,
          popover: AnchoredPopover(
            autoDismiss: false,
            dismissOnTapOutside: false,
            dismissOnScroll: true,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      scroll.jumpTo(50);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('the anchor scrolling out of the list takes the popover with '
        'it, without throwing', (WidgetTester tester) async {
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);

      await tester.pumpWidget(
        list(
          scroll,
          popover: AnchoredPopover(
            autoDismiss: false,
            dismissOnTapOutside: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      scroll.jumpTo(2000);
      await tester.pumpAndSettle();
      expect(find.byKey(anchorKey), findsNothing);
      expect(find.byKey(popoverKey), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('lifecycle', () {
    testWidgets('the anchor leaving the tree while open throws nothing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            dismissOnTapOutside: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the dismiss timer does not outlive the anchor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            showDuration: const Duration(seconds: 2),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      // The pending timer would fire here if dispose had not cancelled it.
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a replacement controller controls the popover state', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController first = AnchoredPopoverController();
      final AnchoredPopoverController second = AnchoredPopoverController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      Widget build(AnchoredPopoverController? controller) => host(
        AnchoredPopover(
          controller: controller,
          autoDismiss: false,
          popoverBuilder: (_, _) => content(),
          child: const Placeholder(),
        ),
      );

      await tester.pumpWidget(build(first));
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      // To an internal controller and back out to another external one.
      await tester.pumpWidget(build(null));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      await tester.pumpWidget(build(second));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);

      second.show();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });
  });

  group('appearance', () {
    testWidgets('decorate wraps the content in a PopoverSurface', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byType(PopoverSurface), findsOneWidget);
    });

    testWidgets('decorate false draws no surface', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byType(PopoverSurface), findsNothing);
    });

    testWidgets('the surface takes the registered theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              AnchoredPopoverTheme(
                backgroundColor: Color(0xFF102030),
                padding: EdgeInsets.all(20),
                shadows: <BoxShadow>[],
              ),
            ],
          ),
          home: Center(
            child: SizedBox(
              key: anchorKey,
              width: 100,
              height: 40,
              child: AnchoredPopover(
                autoDismiss: false,
                popoverBuilder: (_, _) => content(),
                child: const Placeholder(),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      final Material material = tester.widget<Material>(
        find.descendant(
          of: find.byType(PopoverSurface),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, const Color(0xFF102030));
      // 80x24 of content plus 20 of padding on all four sides.
      expect(tester.getSize(find.byType(PopoverSurface)), const Size(120, 64));
    });

    testWidgets('barrierColor paints a scrim', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            barrierColor: const Color(0x80000000),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is ColoredBox && widget.color == const Color(0x80000000),
        ),
        findsOneWidget,
      );
    });

    testWidgets('semanticLabel is announced', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            semanticLabel: 'Favourite options',
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics &&
              widget.properties.label == 'Favourite options',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('it fades and scales in', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            transitionDuration: const Duration(milliseconds: 200),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final FadeTransition fade = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.byKey(popoverKey),
              matching: find.byType(FadeTransition),
            ),
          )
          .first;
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));

      await tester.pumpAndSettle();
      expect(fade.opacity.value, 1);
    });
  });
}
