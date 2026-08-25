import 'package:material_ui/material_ui.dart';

import '../anchored_popover_theme.dart';

/// The card an [AnchoredPopover] paints behind its content: a filled, rounded,
/// shadowed [Material] with padding.
///
/// [AnchoredPopover] wraps its content in one of these unless it is built with
/// `decorate: false`, so you rarely need it directly — but it is a plain widget,
/// and useful on its own for anything that should match your popovers.
///
/// Unset arguments fall back to the ambient [AnchoredPopoverTheme], and then to
/// [AnchoredPopoverTheme.withDefaults].
class PopoverSurface extends StatelessWidget {
  /// Creates a popover surface around [child].
  const PopoverSurface({
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.shape,
    this.borderSide,
    this.padding,
    this.shadows,
    this.textStyle,
    super.key,
  });

  /// The content drawn on the surface.
  final Widget child;

  /// Fill colour. Defaults to [ColorScheme.surfaceContainerHigh].
  final Color? backgroundColor;

  /// Corner radii. Ignored when [shape] is set.
  final BorderRadius? borderRadius;

  /// Outline of the surface. Overrides [borderRadius] and [borderSide].
  final ShapeBorder? shape;

  /// Stroke around the surface. Ignored when [shape] is set.
  final BorderSide? borderSide;

  /// Space between the surface's edge and [child].
  final EdgeInsetsGeometry? padding;

  /// Shadows cast by the surface. Pass an empty list for none.
  final List<BoxShadow>? shadows;

  /// Merged into the ambient text style for [child].
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final AnchoredPopoverTheme theme = AnchoredPopoverTheme.resolve(context);
    final ShapeBorder effectiveShape =
        shape ??
        theme.shape ??
        RoundedRectangleBorder(
          borderRadius: borderRadius ?? theme.borderRadius!,
          side: borderSide ?? theme.borderSide!,
        );
    final List<BoxShadow> effectiveShadows = shadows ?? theme.shadows!;

    final Widget surface = Material(
      color: backgroundColor ?? theme.backgroundColor,
      shape: effectiveShape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? theme.padding!,
        child: DefaultTextStyle.merge(
          style: textStyle ?? theme.textStyle,
          child: child,
        ),
      ),
    );

    if (effectiveShadows.isEmpty) {
      return surface;
    }

    // Material draws a shadow only from an elevation, which is a single
    // Material-spec shadow. Painting the shape again behind it is what lets the
    // theme carry an arbitrary shadow list.
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: effectiveShape,
        shadows: effectiveShadows,
      ),
      child: surface,
    );
  }
}
