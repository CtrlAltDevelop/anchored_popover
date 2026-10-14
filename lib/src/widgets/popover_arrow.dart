import 'dart:ui' show clampDouble;

import 'package:material_ui/material_ui.dart';

import '../popover_layout_delegate.dart';

/// Which of the layout's children an id names.
enum PopoverArrowSlot {
  /// The popover's content.
  content,

  /// The arrow on the content's top edge, pointing up at an anchor above it.
  up,

  /// The arrow on the content's bottom edge, pointing down at an anchor below.
  down,
}

/// How far the arrow's base is pushed into the content, so no hairline shows
/// between the two where they meet.
const double _plug = 1;

/// How far from the content's corners the arrow keeps, so it never sits on a
/// rounded corner.
const double _cornerInset = 12;

/// Places the content with [placement], then the arrow on the edge of the
/// content that faces the anchor, pointing at it.
///
/// Both arrows are always laid out, because every child of a multi-child layout
/// has to be; the one that is not wanted is given no size. No arrow at all is
/// shown when the popover sits beside the anchor rather than above or below it,
/// where there is no edge to point from.
class PopoverArrowLayoutDelegate extends MultiChildLayoutDelegate {
  /// Creates a delegate that places the arrow of [arrowSize] around
  /// [placement]'s result.
  PopoverArrowLayoutDelegate({
    required this.placement,
    required this.arrowSize,
  });

  /// Places the content, and says where the anchor is.
  final PopoverLayoutDelegate placement;

  /// The arrow's width and height, base to tip.
  final Size arrowSize;

  @override
  void performLayout(Size size) {
    final Size contentSize = layoutChild(
      PopoverArrowSlot.content,
      placement.getConstraintsForChild(BoxConstraints.tight(size)),
    );
    final Offset position = placement.getPositionForChild(size, contentSize);
    positionChild(PopoverArrowSlot.content, position);

    final Rect content = position & contentSize;
    final Rect anchor = placement.anchorRect;
    // A pixel of slack, so an offset of zero still counts as above or below.
    final bool anchorBelow = content.bottom <= anchor.top + 1;
    final bool anchorAbove = content.top >= anchor.bottom - 1;

    final double lowest = content.left + _cornerInset + arrowSize.width / 2;
    final double highest = content.right - _cornerInset - arrowSize.width / 2;
    final double tipX = clampDouble(
      anchor.left + placement.targetAnchor.alongSize(anchor.size).dx,
      lowest,
      highest < lowest ? lowest : highest,
    );
    final Size box = Size(arrowSize.width, arrowSize.height + _plug);

    for (final PopoverArrowSlot slot in <PopoverArrowSlot>[
      PopoverArrowSlot.up,
      PopoverArrowSlot.down,
    ]) {
      final bool wanted = slot == PopoverArrowSlot.down
          ? anchorBelow
          : anchorAbove && !anchorBelow;
      layoutChild(slot, BoxConstraints.tight(wanted ? box : Size.zero));
      positionChild(
        slot,
        !wanted
            ? Offset.zero
            : Offset(
                tipX - arrowSize.width / 2,
                slot == PopoverArrowSlot.down
                    ? content.bottom - _plug
                    : content.top - arrowSize.height,
              ),
      );
    }
  }

  @override
  bool shouldRelayout(covariant PopoverArrowLayoutDelegate oldDelegate) =>
      arrowSize != oldDelegate.arrowSize ||
      placement.shouldRelayout(oldDelegate.placement);
}

/// The arrow itself: a triangle in the surface's colour, outlined with the
/// surface's border where it has one.
///
/// Sized by the layout delegate; this only draws.
class PopoverArrow extends StatelessWidget {
  /// Creates an arrow that points up when [pointsUp], and down otherwise.
  const PopoverArrow({
    required this.pointsUp,
    required this.color,
    this.borderSide = BorderSide.none,
    super.key,
  });

  /// Whether the tip is at the top, for an anchor above the popover.
  final bool pointsUp;

  /// Fill colour. The surface's, so the two read as one shape.
  final Color color;

  /// Stroke along the two slanted edges. Not drawn along the base, where the
  /// arrow joins the surface.
  final BorderSide borderSide;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ArrowPainter(
            pointsUp: pointsUp,
            color: color,
            borderSide: borderSide,
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.pointsUp,
    required this.color,
    required this.borderSide,
  });

  final bool pointsUp;
  final Color color;
  final BorderSide borderSide;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final double w = size.width;
    final double h = size.height - _plug;
    // The tip, and the two corners of the base the sides run to.
    final Offset tip = Offset(w / 2, pointsUp ? 0 : h + _plug);
    final double baseY = pointsUp ? h : _plug;
    final double farY = pointsUp ? h + _plug : 0;

    final Path fill = Path()
      ..moveTo(0, farY)
      ..lineTo(0, baseY)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(w, baseY)
      ..lineTo(w, farY)
      ..close();
    canvas.drawPath(fill, Paint()..color = color);

    if (borderSide.style != BorderStyle.none && borderSide.width > 0) {
      final Path edge = Path()
        ..moveTo(0, baseY)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(w, baseY);
      canvas.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.miter
          ..strokeWidth = borderSide.width
          ..color = borderSide.color,
      );
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      pointsUp != oldDelegate.pointsUp ||
      color != oldDelegate.color ||
      borderSide != oldDelegate.borderSide;
}
