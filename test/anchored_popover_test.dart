import 'package:anchored_popover/anchored_popover.dart';
import 'package:anchored_popover/src/widgets/popover_arrow.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
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

  group('transformed anchor', () {
    testWidgets('a scaled anchor is placed against what is on screen', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller =
          AnchoredPopoverController.open();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Transform.scale(
                scale: 2,
                child: AnchoredPopover(
                  trigger: PopoverTrigger.manual,
                  decorate: false,
                  autoDismiss: false,
                  controller: controller,
                  popoverBuilder: (_, _) => content(),
                  child: const SizedBox(key: anchorKey, width: 100, height: 40),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Rect anchor = tester.getRect(find.byKey(anchorKey));
      final Rect popover = tester.getRect(find.byKey(popoverKey));
      expect(anchor.width, 200);
      expect(popover.center.dx, closeTo(anchor.center.dx, 0.01));
      expect(popover.bottom, closeTo(anchor.top - 8, 0.01));
    });
  });

  group('software keyboard', () {
    testWidgets('a popover is kept clear of the keyboard', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AnchoredPopover(
                controller: controller,
                trigger: PopoverTrigger.manual,
                decorate: false,
                autoDismiss: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 8),
                popoverBuilder: (_, _) => content(),
                child: const SizedBox(key: anchorKey, width: 100, height: 40),
              ),
            ),
          ),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();

      // Keyboard top is at 300; the default screen padding of 8 sits above it.
      expect(tester.getRect(find.byKey(popoverKey)).bottom, 300 - 8);
    });
  });

  group('arrow', () {
    Widget arrowHost({
      Alignment alignment = Alignment.center,
      bool showArrow = true,
      bool decorate = true,
      AlignmentGeometry targetAnchor = Alignment.topCenter,
      AlignmentGeometry followerAnchor = Alignment.bottomCenter,
      Offset offset = const Offset(0, -8),
    }) => host(
      AnchoredPopover(
        controller: AnchoredPopoverController.open(),
        trigger: PopoverTrigger.manual,
        autoDismiss: false,
        showArrow: showArrow,
        decorate: decorate,
        targetAnchor: targetAnchor,
        followerAnchor: followerAnchor,
        offset: offset,
        popoverBuilder: (_, _) => content(),
        child: const Placeholder(),
      ),
      alignment: alignment,
    );

    Finder arrows() => find.byType(PopoverArrow);

    /// The arrows that were given a size — at most one is.
    List<RenderBox> drawn(WidgetTester tester) => tester
        .renderObjectList<RenderBox>(find.byType(CustomPaint))
        .where(
          (RenderBox box) =>
              box.hasSize && !box.size.isEmpty && box.size.width == 14,
        )
        .toList();

    testWidgets('points down from a popover that sits above the anchor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(arrowHost());
      await tester.pumpAndSettle();

      expect(arrows(), findsNWidgets(2));
      final List<RenderBox> shown = drawn(tester);
      expect(shown, hasLength(1));

      final Rect anchor = tester.getRect(find.byKey(anchorKey));
      final Rect arrow =
          shown.single.localToGlobal(Offset.zero) & shown.single.size;
      // Centred on the anchor, tip a plug's width short of its top edge.
      expect(arrow.center.dx, closeTo(anchor.center.dx, 0.01));
      expect(arrow.bottom, closeTo(anchor.top - 1, 1.01));
      expect(arrow.size.height, 8);
    });

    testWidgets('points up from a popover that sits below the anchor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        arrowHost(
          targetAnchor: Alignment.bottomCenter,
          followerAnchor: Alignment.topCenter,
          offset: const Offset(0, 8),
        ),
      );
      await tester.pumpAndSettle();

      final List<RenderBox> shown = drawn(tester);
      expect(shown, hasLength(1));
      final Rect anchor = tester.getRect(find.byKey(anchorKey));
      final Rect arrow =
          shown.single.localToGlobal(Offset.zero) & shown.single.size;
      expect(arrow.top, closeTo(anchor.bottom + 1, 1.01));
    });

    testWidgets('stays clear of the popover corner when the anchor is at the '
        'edge', (WidgetTester tester) async {
      await tester.pumpWidget(arrowHost(alignment: Alignment.centerLeft));
      await tester.pumpAndSettle();

      final RenderBox arrow = drawn(tester).single;
      final Rect surface = tester.getRect(find.byType(PopoverSurface));
      final double left = arrow.localToGlobal(Offset.zero).dx;
      expect(left, greaterThanOrEqualTo(surface.left + 12));
    });

    testWidgets('is absent when the popover sits beside the anchor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        arrowHost(
          targetAnchor: Alignment.centerRight,
          followerAnchor: Alignment.centerLeft,
          offset: const Offset(8, 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(drawn(tester), isEmpty);
    });

    testWidgets('is not built unless asked for, or without a surface', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(arrowHost(showArrow: false));
      await tester.pumpAndSettle();
      expect(arrows(), findsNothing);

      await tester.pumpWidget(arrowHost(decorate: false));
      await tester.pumpAndSettle();
      expect(arrows(), findsNothing);
    });

    testWidgets('takes its size from the theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              AnchoredPopoverTheme(arrowSize: Size(20, 10)),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: AnchoredPopover(
                controller: AnchoredPopoverController.open(),
                trigger: PopoverTrigger.manual,
                autoDismiss: false,
                showArrow: true,
                popoverBuilder: (_, _) => content(),
                child: const SizedBox(key: anchorKey, width: 100, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Iterable<Size> sizes = tester
          .renderObjectList<RenderBox>(find.byType(CustomPaint))
          .where((RenderBox box) => box.size.width == 20)
          .map((RenderBox box) => box.size);
      expect(sizes.single, const Size(20, 11));
    });
  });

  group('transitionBuilder', () {
    testWidgets('replaces the fade and scale', (WidgetTester tester) async {
      Animation<double>? seen;
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            decorate: false,
            autoDismiss: false,
            transitionBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Widget child,
                ) {
                  seen = animation;
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      expect(find.byKey(popoverKey), findsOneWidget);
      expect(seen!.value, 1);
      expect(
        find.ancestor(
          of: find.byKey(popoverKey),
          matching: find.byType(SlideTransition),
        ),
        findsWidgets,
      );
      expect(
        find.ancestor(
          of: find.byKey(popoverKey),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
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

  group('anchor out of view', () {
    // A SingleChildScrollView builds everything, so the anchor stays mounted
    // when it scrolls away — which is when a popover would be left behind.
    Widget scroller(
      ScrollController controller,
      AnchoredPopoverController popover,
    ) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 300),
              AnchoredPopover(
                controller: popover,
                trigger: PopoverTrigger.manual,
                autoDismiss: false,
                popoverBuilder: (_, _) => content(),
                child: const SizedBox(key: anchorKey, width: 100, height: 40),
              ),
              const SizedBox(height: 3000),
            ],
          ),
        ),
      ),
    );

    testWidgets('scrolling the anchor out of the viewport closes it', (
      WidgetTester tester,
    ) async {
      final ScrollController scroll = ScrollController();
      final AnchoredPopoverController popover = AnchoredPopoverController();
      addTearDown(scroll.dispose);
      addTearDown(popover.dispose);
      int dismissed = 0;

      await tester.pumpWidget(scroller(scroll, popover));
      popover.show();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
      popover.addListener(() => dismissed += popover.isOpen ? 0 : 1);

      scroll.jumpTo(1500);
      await tester.pumpAndSettle();
      expect(popover.isOpen, isFalse);
      expect(dismissed, 1);
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('an anchor that is partly in view keeps it open', (
      WidgetTester tester,
    ) async {
      final ScrollController scroll = ScrollController();
      final AnchoredPopoverController popover = AnchoredPopoverController();
      addTearDown(scroll.dispose);
      addTearDown(popover.dispose);

      await tester.pumpWidget(scroller(scroll, popover));
      popover.show();
      await tester.pumpAndSettle();

      // The anchor spans 300..340 of the content; this leaves 10px of it under
      // the top edge of the viewport.
      scroll.jumpTo(330);
      await tester.pumpAndSettle();
      expect(popover.isOpen, isTrue);
      expect(find.byKey(popoverKey), findsOneWidget);
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

    testWidgets('the controller reads closed once the anchor is gone', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);
      int notified = 0;
      controller.addListener(() => notified++);

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
      controller.show();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      final int before = notified;

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(notified, before);
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

  group('keyboard', () {
    testWidgets('escape closes the popover', (WidgetTester tester) async {
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
      expect(find.byKey(popoverKey), findsOneWidget);

      // Nothing inside the popover has focus: a popover opened by a pointer
      // still has to answer the keyboard.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('dismissOnEscape false ignores it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            dismissOnEscape: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('a nested popover that ignores escape leaves it to the outer '
        'one', (WidgetTester tester) async {
      final AnchoredPopoverController outer = AnchoredPopoverController();
      final AnchoredPopoverController inner = AnchoredPopoverController();
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            controller: outer,
            trigger: PopoverTrigger.manual,
            autoDismiss: false,
            popoverBuilder: (_, _) => AnchoredPopover(
              controller: inner,
              trigger: PopoverTrigger.manual,
              autoDismiss: false,
              dismissOnEscape: false,
              popoverBuilder: (_, _) => const SizedBox(width: 20, height: 20),
              child: content(),
            ),
            child: const Placeholder(),
          ),
        ),
      );
      outer.show();
      await tester.pumpAndSettle();
      inner.show();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(outer.isOpen, isFalse);
    });

    testWidgets('escape stops being handled once the anchor is gone', (
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

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('focus', () {
    testWidgets('autofocus takes focus and gives it back', (
      WidgetTester tester,
    ) async {
      final FocusNode anchorFocus = FocusNode();
      addTearDown(anchorFocus.dispose);
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: anchorFocus,
              autofocus: true,
              child: AnchoredPopover(
                controller: controller,
                trigger: PopoverTrigger.manual,
                autoDismiss: false,
                autofocus: true,
                popoverBuilder: (_, _) => content(),
                child: const Placeholder(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(anchorFocus.hasFocus, isTrue);

      controller.show();
      await tester.pumpAndSettle();
      expect(anchorFocus.hasPrimaryFocus, isFalse);

      controller.hide();
      await tester.pumpAndSettle();
      expect(anchorFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('it leaves focus alone by default', (
      WidgetTester tester,
    ) async {
      final FocusNode anchorFocus = FocusNode();
      addTearDown(anchorFocus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: anchorFocus,
              autofocus: true,
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
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(anchorFocus.hasPrimaryFocus, isTrue);
    });
  });

  group('hover', () {
    /// A mouse already on screen, away from the anchor.
    Future<TestGesture> mouse(WidgetTester tester) async {
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      return gesture;
    }

    testWidgets('the pointer resting on the anchor opens it, and leaving '
        'closes it', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.hover,
            autoDismiss: false,
            hoverEnterDuration: const Duration(milliseconds: 200),
            hoverExitDuration: const Duration(milliseconds: 100),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await mouse(tester);

      await gesture.moveTo(tester.getCenter(find.byKey(anchorKey)));
      await tester.pump();
      // Not on the first frame: a pointer passing over an anchor on its way
      // somewhere else should open nothing.
      expect(find.byKey(popoverKey), findsNothing);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('the popover stays up while the pointer is on it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.hover,
            autoDismiss: false,
            hoverEnterDuration: const Duration(milliseconds: 200),
            hoverExitDuration: const Duration(milliseconds: 100),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await mouse(tester);

      await gesture.moveTo(tester.getCenter(find.byKey(anchorKey)));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      await gesture.moveTo(tester.getCenter(find.byKey(popoverKey)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('a hover popover lays no barrier over the screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.hover,
            autoDismiss: false,
            hoverEnterDuration: Duration.zero,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await mouse(tester);
      // The route lays one of its own; the popover should add none.
      final int routeBarriers = find.byType(ModalBarrier).evaluate().length;

      await gesture.moveTo(tester.getCenter(find.byKey(anchorKey)));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
      expect(find.byType(ModalBarrier), findsNWidgets(routeBarriers));
    });

    testWidgets('the pointer on the popover holds off auto-dismiss', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            showDuration: const Duration(milliseconds: 500),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await mouse(tester);

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await gesture.moveTo(tester.getCenter(find.byKey(popoverKey)));
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      // Leaving restarts the timer rather than closing it outright.
      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(popoverKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('pauseAutoDismissOnHover false dismisses on time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            showDuration: const Duration(milliseconds: 500),
            pauseAutoDismissOnHover: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await mouse(tester);

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      await gesture.moveTo(tester.getCenter(find.byKey(popoverKey)));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });
  });

  group('back button', () {
    testWidgets('back closes the popover instead of the route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: Center(
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
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
      // The page it was on is still there.
      expect(find.byKey(anchorKey), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('on iOS the route keeps its swipe-back gesture', (
      WidgetTester tester,
    ) async {
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        pageContext = context;
                        return Scaffold(
                          body: Center(
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
                        );
                      },
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      expect(
        ModalRoute.of(pageContext)!.popDisposition,
        RoutePopDisposition.pop,
      );
    });
  });

  group('updating while open', () {
    testWidgets('dismissOnEscape turned off stops closing it', (
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

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            dismissOnEscape: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('dismissOnEscape turned on starts closing it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            dismissOnEscape: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('a new showDuration restarts the timer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            showDuration: const Duration(seconds: 10),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            showDuration: const Duration(milliseconds: 200),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('autoDismiss turned off keeps it up', (
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

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            showDuration: const Duration(seconds: 2),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('a trigger that is no longer hover drops a pending open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.hover,
            hoverEnterDuration: const Duration(milliseconds: 300),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.byKey(anchorKey)));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.tap,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });
  });

  group('following a moving anchor', () {
    testWidgets('an outer scrollable moves it, not just the innermost one', (
      WidgetTester tester,
    ) async {
      final ScrollController outer = ScrollController();
      addTearDown(outer.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: outer,
              children: <Widget>[
                const SizedBox(height: 300),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: <Widget>[
                      SizedBox(
                        key: anchorKey,
                        width: 100,
                        height: 40,
                        child: AnchoredPopover(
                          autoDismiss: false,
                          popoverBuilder: (_, _) => content(),
                          child: const Placeholder(),
                        ),
                      ),
                      const SizedBox(height: 600),
                    ],
                  ),
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      final double anchorBefore = tester.getTopLeft(find.byKey(anchorKey)).dy;
      final double popoverBefore = tester.getTopLeft(find.byKey(popoverKey)).dy;

      // The inner list has not moved at all; only the outer one has.
      outer.jumpTo(120);
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(anchorKey)).dy, anchorBefore - 120);
      expect(tester.getTopLeft(find.byKey(popoverKey)).dy, popoverBefore - 120);
    });

    testWidgets('a window resize re-anchors it', (WidgetTester tester) async {
      addTearDown(tester.view.reset);

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
      final double before = tester.getTopLeft(find.byKey(popoverKey)).dy;
      final double gap = tester.getTopLeft(find.byKey(anchorKey)).dy - before;

      tester.view.physicalSize = const Size(800, 1200);
      await tester.pumpAndSettle();

      final double after = tester.getTopLeft(find.byKey(popoverKey)).dy;
      expect(after, isNot(before));
      expect(tester.getTopLeft(find.byKey(anchorKey)).dy - after, gap);
    });

    /// An anchor that slides down the screen without its subtree rebuilding,
    /// which is what an animation or a drag does.
    Widget slidingHost({
      required double top,
      required bool everyFrame,
      required AnchoredPopoverController controller,
    }) => MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              left: 100,
              top: top,
              child: SizedBox(
                key: anchorKey,
                width: 100,
                height: 40,
                child: AnchoredPopover(
                  controller: controller,
                  trigger: PopoverTrigger.manual,
                  autoDismiss: false,
                  followAnchorEveryFrame: everyFrame,
                  popoverBuilder: (_, _) => content(),
                  child: const Placeholder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    testWidgets('followAnchorEveryFrame keeps up with an animating anchor', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        slidingHost(top: 100, everyFrame: true, controller: controller),
      );
      controller.show();
      await tester.pumpAndSettle();
      final double gap =
          tester.getTopLeft(find.byKey(anchorKey)).dy -
          tester.getTopLeft(find.byKey(popoverKey)).dy;

      await tester.pumpWidget(
        slidingHost(top: 400, everyFrame: true, controller: controller),
      );
      // In frames, the way the animation would really arrive. The check looks
      // at the anchor after a frame has drawn and relayouts on the next one, so
      // the popover trails by a single frame of the anchor's movement — a few
      // pixels at 60fps, and nothing at all once the anchor stops.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      // Mid-animation: the anchor has left 100 and not yet reached 400.
      final double anchor = tester.getTopLeft(find.byKey(anchorKey)).dy;
      expect(anchor, greaterThan(100));
      expect(anchor, lessThan(400));
      expect(
        anchor - tester.getTopLeft(find.byKey(popoverKey)).dy,
        closeTo(gap, 20),
      );

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(anchorKey)).dy, 400);
      expect(400 - tester.getTopLeft(find.byKey(popoverKey)).dy, gap);
    });

    testWidgets('without it, an animating anchor leaves the popover behind', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        slidingHost(top: 100, everyFrame: false, controller: controller),
      );
      controller.show();
      await tester.pumpAndSettle();
      final double before = tester.getTopLeft(find.byKey(popoverKey)).dy;

      await tester.pumpWidget(
        slidingHost(top: 400, everyFrame: false, controller: controller),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.getTopLeft(find.byKey(anchorKey)).dy, greaterThan(100));
      expect(tester.getTopLeft(find.byKey(popoverKey)).dy, before);
    });

    testWidgets('the frame check stops with the popover', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        slidingHost(top: 100, everyFrame: true, controller: controller),
      );
      controller.show();
      await tester.pumpAndSettle();
      controller.hide();
      await tester.pumpAndSettle();

      // The per-frame check must never be what keeps frames coming.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('coverage of the remaining paths', () {
    testWidgets('secondaryTap opens the popover', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.secondaryTap,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      expect(find.byKey(popoverKey), findsNothing);
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(anchorKey)),
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('hover durations fall back to the theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              AnchoredPopoverTheme(
                hoverEnterDuration: Duration(milliseconds: 200),
                hoverExitDuration: Duration(milliseconds: 200),
              ),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: anchorKey,
                width: 100,
                height: 40,
                child: AnchoredPopover(
                  trigger: PopoverTrigger.hover,
                  autoDismiss: false,
                  popoverBuilder: (_, _) => content(),
                  child: const Placeholder(),
                ),
              ),
            ),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.byKey(anchorKey)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(popoverKey), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);

      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(popoverKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('the pointer leaving the popover closes a hover popover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.hover,
            autoDismiss: false,
            hoverEnterDuration: const Duration(milliseconds: 100),
            hoverExitDuration: const Duration(milliseconds: 100),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.byKey(anchorKey)));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await gesture.moveTo(tester.getCenter(find.byKey(popoverKey)));
      await tester.pump();

      // Off the popover, and not back onto the anchor.
      await gesture.moveTo(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('a pointer passing over the anchor opens nothing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnchoredPopover(
            trigger: PopoverTrigger.hover,
            hoverEnterDuration: const Duration(milliseconds: 300),
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.byKey(anchorKey)));
      await tester.pump(const Duration(milliseconds: 100));
      // Gone again before the popover was due to open.
      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('escape inside the popover arrives as a DismissIntent', (
      WidgetTester tester,
    ) async {
      final FocusNode inside = FocusNode();
      addTearDown(inside.dispose);

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            autoDismiss: false,
            autofocus: true,
            popoverBuilder: (_, _) =>
                Focus(focusNode: inside, autofocus: true, child: content()),
            child: const Placeholder(),
          ),
        ),
      );
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();
      expect(inside.hasPrimaryFocus, isTrue);

      // Focus is inside, so the keyboard handler stands aside and the key
      // travels the ordinary Actions path instead.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsNothing);
    });

    testWidgets('dropping a controller while closed makes a fresh one', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);
      final GlobalKey<AnchoredPopoverState> key =
          GlobalKey<AnchoredPopoverState>();

      await tester.pumpWidget(
        host(
          AnchoredPopover(
            key: key,
            controller: controller,
            trigger: PopoverTrigger.manual,
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

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
      expect(key.currentState!.isOpen, isFalse);

      // The internal controller it made for itself drives it.
      key.currentState!.show();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
      // The controller it no longer holds does not.
      controller.hide();
      await tester.pumpAndSettle();
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('turning both follow flags off detaches the listeners', (
      WidgetTester tester,
    ) async {
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);

      Widget build({required bool follow}) => MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: <Widget>[
              // Enough above the anchor that scrolling moves it without
              // scrolling it out of the list altogether.
              const SizedBox(height: 300),
              SizedBox(
                key: anchorKey,
                width: 100,
                height: 40,
                child: AnchoredPopover(
                  autoDismiss: false,
                  followAnchorOnScroll: follow,
                  popoverBuilder: (_, _) => content(),
                  child: const Placeholder(),
                ),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      );

      await tester.pumpWidget(build(follow: true));
      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(follow: false));
      final double before = tester.getTopLeft(find.byKey(popoverKey)).dy;
      scroll.jumpTo(100);
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(popoverKey)).dy, before);
    });

    testWidgets('followAnchorEveryFrame can be turned on while open', (
      WidgetTester tester,
    ) async {
      final AnchoredPopoverController controller = AnchoredPopoverController();
      addTearDown(controller.dispose);

      Widget build({required bool everyFrame, required double top}) =>
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    left: 100,
                    top: top,
                    child: SizedBox(
                      key: anchorKey,
                      width: 100,
                      height: 40,
                      child: AnchoredPopover(
                        controller: controller,
                        trigger: PopoverTrigger.manual,
                        autoDismiss: false,
                        followAnchorEveryFrame: everyFrame,
                        popoverBuilder: (_, _) => content(),
                        child: const Placeholder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

      await tester.pumpWidget(build(everyFrame: false, top: 100));
      controller.show();
      await tester.pumpAndSettle();
      final double gap =
          tester.getTopLeft(find.byKey(anchorKey)).dy -
          tester.getTopLeft(find.byKey(popoverKey)).dy;

      await tester.pumpWidget(build(everyFrame: true, top: 400));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(anchorKey)).dy, 400);
      expect(400 - tester.getTopLeft(find.byKey(popoverKey)).dy, gap);
    });
  });

  group('haptics', () {
    /// Records what the widget asks the platform to do.
    List<MethodCall> platformCalls(WidgetTester tester) {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return calls;
    }

    Widget androidHost(Widget popover) => MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: anchorKey,
            width: 100,
            height: 40,
            child: popover,
          ),
        ),
      ),
    );

    testWidgets('a long press asks the platform for its long-press feedback', (
      WidgetTester tester,
    ) async {
      final List<MethodCall> calls = platformCalls(tester);
      await tester.pumpWidget(
        androidHost(
          AnchoredPopover(
            autoDismiss: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      expect(
        calls.map((MethodCall call) => call.method),
        contains('HapticFeedback.vibrate'),
      );
    });

    testWidgets('enableFeedback false asks for nothing', (
      WidgetTester tester,
    ) async {
      final List<MethodCall> calls = platformCalls(tester);
      await tester.pumpWidget(
        androidHost(
          AnchoredPopover(
            autoDismiss: false,
            enableFeedback: false,
            popoverBuilder: (_, _) => content(),
            child: const Placeholder(),
          ),
        ),
      );

      await tester.longPress(find.byKey(anchorKey));
      await tester.pumpAndSettle();

      expect(
        calls.map((MethodCall call) => call.method),
        isNot(contains('HapticFeedback.vibrate')),
      );
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
