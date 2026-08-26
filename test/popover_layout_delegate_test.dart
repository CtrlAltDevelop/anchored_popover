import 'package:anchored_popover/anchored_popover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const Size overlay = Size(800, 600);
  const Size popover = Size(100, 40);

  PopoverLayoutDelegate delegate({
    required Rect anchorRect,
    Alignment targetAnchor = Alignment.topCenter,
    Alignment followerAnchor = Alignment.bottomCenter,
    Offset offset = const Offset(0, -8),
    EdgeInsets screenPadding = const EdgeInsets.all(8),
    bool flip = true,
  }) {
    return PopoverLayoutDelegate(
      anchorRect: anchorRect,
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      offset: offset,
      screenPadding: screenPadding,
      flip: flip,
    );
  }

  group('getPositionForChild', () {
    test('centres the popover above the anchor', () {
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(350, 280, 100, 40),
      ).getPositionForChild(overlay, popover);

      // Bottom edge 8 above the anchor's top, centres aligned.
      expect(position, const Offset(350, 232));
    });

    test('flips below the anchor when there is no room above', () {
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(350, 0, 100, 40),
      ).getPositionForChild(overlay, popover);

      expect(position, const Offset(350, 48));
    });

    test('flips above the anchor when there is no room below', () {
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(350, 560, 100, 40),
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        offset: const Offset(0, 8),
      ).getPositionForChild(overlay, popover);

      expect(position, const Offset(350, 512));
    });

    test('does not flip into a side that does not fit either', () {
      // A popover taller than the anchor has room on neither side, so the
      // preferred side is kept and only clamped.
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(350, 250, 100, 100),
      ).getPositionForChild(overlay, const Size(100, 590));

      expect(position.dy, 8);
    });

    test('does not flip when flip is false', () {
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(350, 0, 100, 40),
        flip: false,
      ).getPositionForChild(overlay, popover);

      // Clamped to the padded top edge instead of moving below the anchor.
      expect(position, const Offset(350, 8));
    });

    test('clamps into the padded bounds horizontally', () {
      expect(
        delegate(
          anchorRect: const Rect.fromLTWH(0, 280, 100, 40),
        ).getPositionForChild(overlay, const Size(300, 40)).dx,
        8,
      );
      expect(
        delegate(
          anchorRect: const Rect.fromLTWH(700, 280, 100, 40),
        ).getPositionForChild(overlay, const Size(300, 40)).dx,
        800 - 8 - 300,
      );
    });

    test('pins a popover larger than the padded bounds to their top left', () {
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(350, 280, 100, 40),
      ).getPositionForChild(overlay, const Size(900, 700));

      expect(position, const Offset(8, 8));
    });

    test('honours asymmetric screen padding', () {
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(760, 280, 40, 40),
        screenPadding: const EdgeInsets.fromLTRB(4, 60, 44, 4),
      ).getPositionForChild(overlay, popover);

      expect(position.dx, 800 - 44 - 100);
    });

    test('respects a corner-to-corner placement', () {
      final Offset position = delegate(
        anchorRect: const Rect.fromLTWH(350, 280, 100, 40),
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topLeft,
        offset: Offset.zero,
      ).getPositionForChild(overlay, popover);

      expect(position, const Offset(450, 320));
    });
  });

  group('getConstraintsForChild', () {
    test('loosens the constraints and removes the screen padding', () {
      final BoxConstraints constraints = delegate(
        anchorRect: Rect.zero,
        screenPadding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      ).getConstraintsForChild(BoxConstraints.tight(overlay));

      expect(constraints.minWidth, 0);
      expect(constraints.minHeight, 0);
      expect(constraints.maxWidth, 800 - 16);
      expect(constraints.maxHeight, 600 - 40);
    });
  });

  group('shouldRelayout', () {
    test('is true when the anchor has moved', () {
      expect(
        delegate(anchorRect: const Rect.fromLTWH(0, 0, 10, 10)).shouldRelayout(
          delegate(anchorRect: const Rect.fromLTWH(0, 50, 10, 10)),
        ),
        isTrue,
      );
    });

    test('is false for an identical delegate', () {
      expect(
        delegate(anchorRect: const Rect.fromLTWH(0, 0, 10, 10)).shouldRelayout(
          delegate(anchorRect: const Rect.fromLTWH(0, 0, 10, 10)),
        ),
        isFalse,
      );
    });
  });
}
