import 'dart:math' as math;
import 'dart:ui' show clampDouble;

import 'package:material_ui/material_ui.dart';

/// Places a popover against [anchorRect], then keeps it on screen.
///
/// Used with a [CustomSingleChildLayout] whose own box covers the [Overlay], so
/// "on screen" means inside that box, deflated by [screenPadding].
///
/// The popover is placed by putting its [followerAnchor] point on the
/// [targetAnchor] point of [anchorRect], plus [offset]. Two corrections then
/// apply, in order:
///
/// 1. If it would spill past the top or bottom edge and [flip] is set, the whole
///    placement is mirrored to the anchor's other side — but only if that side
///    actually fits, so a popover never flips into a worse position.
/// 2. Whatever remains is clamped into the padded bounds.
///
/// A popover larger than the space available is pinned to the top-left of the
/// padded bounds rather than being pushed off the other edge.
class PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate that places a popover against [anchorRect].
  const PopoverLayoutDelegate({
    required this.anchorRect,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
    required this.screenPadding,
    this.flip = true,
  });

  /// The anchor's bounds, in the coordinate space of the layout's own box.
  ///
  /// Measured during the build phase, because it has to be: a render object may
  /// not read another's size or transform from inside [performLayout], so a
  /// delegate cannot resolve the anchor live however convenient that would be.
  /// Keeping a popover on a moving anchor is therefore a matter of rebuilding
  /// it whenever the anchor moves, which is what [AnchoredPopover] does.
  final Rect anchorRect;

  /// The point of [anchorRect] the popover is placed against.
  final Alignment targetAnchor;

  /// The point of the popover put onto the [targetAnchor] point.
  final Alignment followerAnchor;

  /// Shifted by this much after the anchors line up.
  final Offset offset;

  /// How close to the edge of the layout's box the popover may sit.
  final EdgeInsets screenPadding;

  /// Whether to mirror the placement to the anchor's other side when the
  /// preferred side does not fit vertically.
  final bool flip;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest).deflate(screenPadding);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final Rect anchorRect = this.anchorRect;
    final double minX = screenPadding.left;
    final double minY = screenPadding.top;
    final double maxX = math.max(
      minX,
      size.width - screenPadding.right - childSize.width,
    );
    final double maxY = math.max(
      minY,
      size.height - screenPadding.bottom - childSize.height,
    );

    Offset place(Alignment target, Alignment follower, Offset delta) {
      final Offset point =
          anchorRect.topLeft + target.alongSize(anchorRect.size);
      return point - follower.alongSize(childSize) + delta;
    }

    Offset position = place(targetAnchor, followerAnchor, offset);

    if (flip && (position.dy < minY || position.dy > maxY)) {
      final Offset mirrored = place(
        Alignment(targetAnchor.x, -targetAnchor.y),
        Alignment(followerAnchor.x, -followerAnchor.y),
        Offset(offset.dx, -offset.dy),
      );
      if (mirrored.dy >= minY && mirrored.dy <= maxY) {
        position = mirrored;
      }
    }

    return Offset(
      clampDouble(position.dx, minX, maxX),
      clampDouble(position.dy, minY, maxY),
    );
  }

  @override
  bool shouldRelayout(covariant PopoverLayoutDelegate oldDelegate) =>
      anchorRect != oldDelegate.anchorRect ||
      targetAnchor != oldDelegate.targetAnchor ||
      followerAnchor != oldDelegate.followerAnchor ||
      offset != oldDelegate.offset ||
      screenPadding != oldDelegate.screenPadding ||
      flip != oldDelegate.flip;
}
