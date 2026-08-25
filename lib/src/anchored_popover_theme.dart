import 'package:material_ui/material_ui.dart';

/// App-wide look and timing for every [AnchoredPopover] and [PopoverSurface].
///
/// Register it on your [ThemeData] and both widgets follow it, so a popover in
/// one screen cannot drift from a popover in another:
///
/// ```dart
/// ThemeData(
///   extensions: const [
///     AnchoredPopoverTheme(
///       borderRadius: BorderRadius.all(Radius.circular(12)),
///       showDuration: Duration(seconds: 2),
///     ),
///   ],
/// );
/// ```
///
/// Every field is nullable, and every field a widget sets itself wins over the
/// theme. Anything left unset on both falls back to [withDefaults].
class AnchoredPopoverTheme extends ThemeExtension<AnchoredPopoverTheme> {
  /// Creates a popover theme. Unset fields are resolved by [withDefaults].
  const AnchoredPopoverTheme({
    this.backgroundColor,
    this.borderRadius,
    this.shape,
    this.borderSide,
    this.padding,
    this.shadows,
    this.textStyle,
    this.screenPadding,
    this.showDuration,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.curve,
    this.reverseCurve,
  });

  /// Fill colour of the surface behind the popover's content.
  final Color? backgroundColor;

  /// Corner radii of the surface. Ignored when [shape] is set.
  final BorderRadius? borderRadius;

  /// Outline of the surface. Overrides [borderRadius] and [borderSide].
  final ShapeBorder? shape;

  /// Stroke drawn around the surface. Ignored when [shape] is set.
  final BorderSide? borderSide;

  /// Space between the surface's edge and the popover's content.
  final EdgeInsetsGeometry? padding;

  /// Shadows cast by the surface. An empty list casts none.
  final List<BoxShadow>? shadows;

  /// Base text style for the popover's content.
  final TextStyle? textStyle;

  /// How close to the edge of the [Overlay] a popover may be placed.
  ///
  /// Added to the safe-area insets, and enforced by clamping — see
  /// [PopoverLayoutDelegate].
  final EdgeInsetsGeometry? screenPadding;

  /// How long a popover stays up before it dismisses itself.
  ///
  /// Ignored by popovers built with `autoDismiss: false`.
  final Duration? showDuration;

  /// How long the popover takes to fade and scale in.
  final Duration? transitionDuration;

  /// How long the popover takes to fade and scale back out.
  final Duration? reverseTransitionDuration;

  /// Curve of the entrance transition.
  final Curve? curve;

  /// Curve of the exit transition.
  final Curve? reverseCurve;

  /// The theme registered on the ambient [ThemeData], or null if there is none.
  static AnchoredPopoverTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<AnchoredPopoverTheme>();

  /// The ambient theme with every unset field filled in.
  ///
  /// Works with no theme registered at all, in which case the colours come from
  /// the ambient [ColorScheme].
  static AnchoredPopoverTheme resolve(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AnchoredPopoverTheme? registered = theme
        .extension<AnchoredPopoverTheme>();
    return (registered ?? const AnchoredPopoverTheme()).withDefaults(
      theme.colorScheme,
    );
  }

  /// A copy with every null field replaced by its default.
  ///
  /// Colours are derived from [colorScheme], so the result follows the light
  /// and dark themes of an app that registers nothing. Every field on the
  /// returned theme is non-null.
  AnchoredPopoverTheme withDefaults(ColorScheme colorScheme) {
    return AnchoredPopoverTheme(
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHigh,
      borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(8)),
      shape: shape,
      borderSide: borderSide ?? BorderSide.none,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shadows:
          shadows ??
          <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
      textStyle:
          textStyle ??
          TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
      screenPadding: screenPadding ?? const EdgeInsets.all(8),
      showDuration: showDuration ?? const Duration(seconds: 3),
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 120),
      reverseTransitionDuration:
          reverseTransitionDuration ?? const Duration(milliseconds: 90),
      curve: curve ?? Curves.easeOutCubic,
      reverseCurve: reverseCurve ?? Curves.easeIn,
    );
  }

  @override
  AnchoredPopoverTheme copyWith({
    Color? backgroundColor,
    BorderRadius? borderRadius,
    ShapeBorder? shape,
    BorderSide? borderSide,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? shadows,
    TextStyle? textStyle,
    EdgeInsetsGeometry? screenPadding,
    Duration? showDuration,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    Curve? curve,
    Curve? reverseCurve,
  }) {
    return AnchoredPopoverTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      shape: shape ?? this.shape,
      borderSide: borderSide ?? this.borderSide,
      padding: padding ?? this.padding,
      shadows: shadows ?? this.shadows,
      textStyle: textStyle ?? this.textStyle,
      screenPadding: screenPadding ?? this.screenPadding,
      showDuration: showDuration ?? this.showDuration,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      reverseTransitionDuration:
          reverseTransitionDuration ?? this.reverseTransitionDuration,
      curve: curve ?? this.curve,
      reverseCurve: reverseCurve ?? this.reverseCurve,
    );
  }

  @override
  AnchoredPopoverTheme lerp(AnchoredPopoverTheme? other, double t) {
    if (other == null) {
      return this;
    }
    final bool takeOther = t >= 0.5;
    return AnchoredPopoverTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t),
      shape: ShapeBorder.lerp(shape, other.shape, t),
      borderSide: _lerpBorderSide(borderSide, other.borderSide, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      shadows: BoxShadow.lerpList(shadows, other.shadows, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      screenPadding: EdgeInsetsGeometry.lerp(
        screenPadding,
        other.screenPadding,
        t,
      ),
      showDuration: takeOther ? other.showDuration : showDuration,
      transitionDuration: takeOther
          ? other.transitionDuration
          : transitionDuration,
      reverseTransitionDuration: takeOther
          ? other.reverseTransitionDuration
          : reverseTransitionDuration,
      curve: takeOther ? other.curve : curve,
      reverseCurve: takeOther ? other.reverseCurve : reverseCurve,
    );
  }

  /// [BorderSide.lerp] rejects nulls and cannot interpolate to or from "unset",
  /// so a null endpoint snaps instead.
  static BorderSide? _lerpBorderSide(BorderSide? a, BorderSide? b, double t) {
    if (a == null || b == null) {
      return t < 0.5 ? a : b;
    }
    return BorderSide.lerp(a, b, t);
  }
}
